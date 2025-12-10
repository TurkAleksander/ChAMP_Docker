FROM rocker/r-ver:4.3.2

LABEL maintainer="you@example.com"
ENV DEBIAN_FRONTEND=noninteractive

### ---- Install system dependencies ----
RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libfontconfig1-dev \
    libfreetype6-dev \
    libpng-dev \
    libtiff5-dev \
    libharfbuzz-dev \
    libfribidi-dev \
    libjpeg-dev \
    zlib1g-dev \
    libgit2-dev \
    libxt-dev \
    libglpk40 \
    libgmp-dev \
    libssh2-1-dev \
    libbz2-dev \
    liblzma-dev \
    zlib1g-dev \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    build-essential \
    wget \
    && apt-get clean

### ---- Install BiocManager configured for Bioconductor 3.17 ----
RUN R -e "install.packages('BiocManager', repos='https://cloud.r-project.org')"

### ---- Install base Bioconductor packages ----
RUN R -e "BiocManager::install(version='3.17', ask=FALSE)"

#Get KPMT package
RUN mkdir /dependencies && \
    cd /dependencies && \
    wget --no-verbose --tries=3 https://cran.r-project.org/src/contrib/Archive/kpmt/kpmt_0.1.0.tar.gz && \
    R -e "install.packages('/dependencies/kpmt_0.1.0.tar.gz', repos = NULL, type = 'source')"

### ---- Install ChAMP and other dependencies explicitly (faster & robust) ----
RUN R -e "BiocManager::install(c( \
  'minfi', \
  'IlluminaHumanMethylationEPICanno.ilm10b4.hg19', \
  'IlluminaHumanMethylation450kmanifest', \
  'IlluminaHumanMethylationEPICmanifest', \
  'missMethyl', \
  'bumphunter', \
  'limma', \
  'sva', \
  'ChIPseeker',\
  'missMethyl', \
  'DMRcate',\
  'DSS',\
  'foreach', \
  'doParallel',\
  'DMRloc',\
  'MultiAssayExperiment', \
  'dplyr', \
  'stringr', \
  'magrittr', \
  'stringi', \
  'ggplot2', \
  'karyoploteR', \
  'GenomicRanges', \
  'pheatmap', \
  'readxl', \
  'readr', \
  'IlluminaHumanMethylationEPICv2anno.20a1.hg38' \
  ), ask=FALSE)"

### ---- Install ChAMP (the default version is 2.29.1) ----
RUN R -e "install.packages('remotes', repos='https://cloud.r-project.org'); \
           remotes::install_github('YuanTian1991/ChAMP')"
RUN R -e "remotes::install_github('YuanTian1991/CHAMPdata')"
RUN R -e "library('ChAMPdata')"
RUN R -e "data('AnnoEPICv2')"


### ---- Optional: Set working directory ----
RUN mkdir /work && \
    chmod 777 /work && \
    cd /work
WORKDIR /work