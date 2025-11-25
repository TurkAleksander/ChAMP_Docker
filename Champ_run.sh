#!/bin/bash

helpFunction()
{
   echo ""
   echo "Usage: $0 -i parameterI -o parameterO -s parameterS"
   echo -e "\t-i Absolute input directory with all paired .idat files, must also contain CSV sample sheet"
   echo -e "\t-o Absolute output directory where you want your results to go"
   echo -e "\t-s Sample sheet name (e.g.: SampleSheet.csv)"
   exit 1 # Exit script after printing help
}

while getopts "i:s:" opt
do
   case "$opt" in
      i ) parameterI="$OPTARG" ;;
      i ) parameterO="$OPTARG" ;;
      s ) parameterS="$OPTARG" ;;
      ? ) helpFunction ;; # Print helpFunction in case parameter is non-existent
   esac
done

# Print helpFunction in case parameters are empty
if [ -z "$parameterI" ] || [ -z "$parameterS" ] || [ -z "$parameterO" ]
then
   echo "Some or all of the parameters are empty";
   helpFunction
fi

# Begin script in case all parameters are correct
echo "The purpose of this is to use Docker to run ChAMP analysis (v2.29.1) in R (v4.3.2)"
echo "The analysis runs with preset parameters, feel free to edit Champ_script.R to your needs"
echo "$parameterI"
echo "$parameterO"
echo "$parameterS"


docker run -it --rm --name champ_run \
     -v ${parameterI}:/work \
     -v ${parameterO}:/results \
     champ:2.29.1 \
     Rscript /work/Champ_script.R --inputDir=/work/input --outputDir=/work/output --sampleSheet=${parameterS}