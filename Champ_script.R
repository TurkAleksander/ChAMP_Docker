#Load libraries
library(ChAMP)
library(ChAMPdata)
library(dplyr)
library(magrittr)
library(stringr)
library(stringi)
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


