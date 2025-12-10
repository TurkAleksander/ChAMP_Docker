#Load libraries
library(ChAMP)
library(ChAMPdata)
library(dplyr)
library(magrittr)
library(stringr)
library(stringi)
library(foreach)
library(doParallel)
library(readxl)
library(readr)
library(lubridate)
library(ggplot2)
BiocManager::install("karyoploteR")
library(karyoploteR)
BiocManager::install("GenomicRanges")
library(GenomicRanges)
BiocManager::install("pheatmap")
library(pheatmap)
#Directories
#Load annotation data
data("AnnoEPICv2")

#Directories
baseDir <- "/work"
sampleInfoDir <- paste0(baseDir, "/Sample_info")
dataDir <- paste0(baseDir, "/Sample_raw_data/Idats_ML_EPIC")
setwd(baseDir)

#'[Organize sample data]

#Get EPIC sample/chip location data
sampleCrossRef <- readr::read_csv(file = paste0(sampleInfoDir,"/", "Slovenia_SampleSheet_ML_EPIC_250925.csv"),
                                  skip = 7,
                                  col_names = TRUE) %>%
  dplyr::select(Sample_Name, Sentrix_ID, Sentrix_Position) %>%
  dplyr::rename("Patient_ID" = "Sample_Name") %>%
  dplyr::mutate(across(where(is.character), str_remove_all, pattern = fixed(" ")))

#Get internal sample data (IDs, gender, etc)
sampleInfoDF <- readxl::read_xlsx(path = paste0(sampleInfoDir,"/", "Maja_epigen_EPIC_sample_data.xlsx"),
                                  sheet = 1,
                                  col_names = TRUE) %>%
  dplyr::rename("Patient_ID" = "Patient identifier",
                "DOB" = "Birth date") %>%
  dplyr::select(Patient_ID, Secondary_ID, Primary_cohort, Gender, DOB, Indication) %>%
  dplyr::mutate(Age = as.integer(floor((as.Date("21/11/2025", "%d/%m/%Y") - as.Date(DOB, "%Y%m%d")) / 365))) %>%
  mutate(Patient_ID = str_replace_all(Patient_ID, "\\s+", ""))

#Cross-reference the two DFs
sampleInfoDF <- dplyr::inner_join(sampleInfoDF, sampleCrossRef, by = "Patient_ID")
if (nrow(sampleInfoDF) != nrow(sampleCrossRef)) {
  print(union(setdiff(sampleInfoDF$Patient_ID,sampleCrossRef$Patient_ID), setdiff(sampleCrossRef$Patient_ID,sampleInfoDF$Patient_ID)))
  stop("--- STOPPED. Missing samples, see above. ---")
}
write.table(sampleInfoDF, file = paste0(baseDir, "/sampleInfoDF.txt"), row.names = FALSE, col.names = TRUE,sep = "\t")

#Function to parse named arguments
#parseArgs <- function(args) {
#  parsed <- list()
#  for (arg in args) {
#    key_value <- strsplit(arg, "=")[[1]]
#    key <- gsub("^--", "", key_value[1])  # Remove leading '--'
#    value <- key_value[2]
#    parsed[[key]] <- value
#  }
#  return(parsed)
#}

#Capture command line arguments
#args <- commandArgs(trailingOnly=TRUE)
#parsedArgs <- parseArgs(args)
#dataDir <- parsedArgs$inputDir
#resultsDir <- parsedArgs$outputDir
#sampleSheet <- parsedArgs$sampleSheet

#Load .idat files from specified directory
myLoad <- ChAMP::champ.load(directory = dataDir,
                            arraytype = "EPICv2",
                            filterXY = FALSE)
#Output QC data to results dir (requires cohort/group data, by default from sample sheet)
ChAMP::champ.QC(beta = myLoad$beta,
                pheno = myLoad$Sample_Group,
                resultsDir = paste0(resultsDir, "/CHAMP_QCimages/"))

#Normalization, default method is BMIQ, using EPICv2 annotation
#4 different methods available, but have their pros/cons/requirements
#See: https://www.bioconductor.org/packages/devel/bioc/vignettes/ChAMP/inst/doc/ChAMP.html#section-normalization
myNorm <- ChAMP::champ.norm(beta=myLoad$beta,
                            method="BMIQ",
                            arraytype="EPICv2",
                            cores=5)

#Singular value decomposition (SVD) analysis to identify potential confounding factors
#If you want to include more covariates than in the sample sheet, add them to myLoad$pd before running this step
ChAMP::champ.SVD(beta=myNorm, pd=myLoad$pd)

#Batch effect correction using ComBat
#Change "Slide" to the appropriate column name in your sample sheet if needed
myCombat <- ChAMP::champ.runCombat(beta=myNorm,
                                    pd=myLoad$pd,
                                    batchname=c("Slide"))
write.table(myCombat,
                file=paste0(resultsDir, "/ComBat_corrected_beta_values.txt"),
                sep="\t",
                quote=FALSE,
                row.names=TRUE,
                col.names=TRUE)

pca_norm <- prcomp(t(myCombat), scale. = TRUE)
pca_df_norm <- data.frame(
  Sample = rownames(pca_norm$x),
  PC1 = pca_norm$x[, 1],
  PC2 = pca_norm$x[, 2]
)

#'[Make heatmap]
#####

#Not feasible for all probes, too much data - keep most informative ones
#We'll do this with rowVars to identify most variable probes and keep the top 10,000
probeVars <- rowVars(as.matrix(myCombat), na.rm = TRUE)
probesToKeep <- order(probeVars, decreasing = TRUE)[1:10000]
myCombatHeat_var <- as.matrix(myCombat[probesToKeep, ])
#For coloring by group
sampleGroups <- data.frame(
  Sample_Name = colnames(myCombat)
)
sampleGroups <- merge(sampleGroups, sampleInfoDF, by.x = "Sample_Name", by.y = "Patient_ID") %>%
  dplyr::select(Sample_Name, Primary_cohort) %>%
  dplyr::rename(Group = Primary_cohort)
group_colors <- c("Heart_condition" = "red", "Microcephaly" = "blue", "Control" = "green")
col_side_colors <- group_colors[sampleGroups$Group]

annotation <- data.frame(Group = sampleGroups$Group)
rownames(annotation) <- colnames(myCombatHeat_var)

png(filename = paste0(baseDir,"/", "Heatmap_top10k.png"), width = 1920, height = 1080, res = 200)
pheatmap(
  myCombatHeat_var,
  annotation_col = annotation,
  annotation_colors = list(Group = group_colors),
  show_rownames = FALSE,
  fontsize_col = 6,
  fontsize_row = 3,
  border_color = NA
)
dev.off()