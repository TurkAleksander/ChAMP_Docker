#Load libraries
library(ChAMP)
library(ChAMPdata)
library(dplyr)
library(magrittr)
library(stringr)
library(stringi)
library(foreach)
library(doParallel)
#Load annotation data
data("AnnoEPICv2")

#Function to parse named arguments
parseArgs <- function(args) {
  parsed <- list()
  for (arg in args) {
    key_value <- strsplit(arg, "=")[[1]]
    key <- gsub("^--", "", key_value[1])  # Remove leading '--'
    value <- key_value[2]
    parsed[[key]] <- value
  }
  return(parsed)
}

#Capture command line arguments
args <- commandArgs(trailingOnly=TRUE)
parsedArgs <- parseArgs(args)
dataDir <- parsedArgs$inputDir
resultsDir <- parsedArgs$outputDir
sampleSheet <- parsedArgs$sampleSheet

#Load .idat files from specified directory
myLoad <- ChAMP::champ.load(directory = dataDir,
                            arraytype = "EPIC",
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