Some of the newest versions of ChAMP you can get from Bioconductor don't process EPICv2 arrays, but an "older" version does.
You need specific versions of ChAMP (v2.29.1) and ChAMPdata (v2.31.1) and their dependencies, which this docker provides.
For the visualization functions you may need to add a newer version of S4vectors to the Dockerfile (>= 0.47.6) and rebuild.

For usage and such, see: https://www.bioconductor.org/packages/devel/bioc/vignettes/ChAMP/inst/doc/ChAMP.html
