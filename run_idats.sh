#!/bin/bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --partition normal
#SBATCH --time=1:00:00
#SBATCH --mem=64G
#SBATCH --job-name=epic_pipeline
#SBATCH --mail-type=ALL
#SBATCH --error ./log/%x_%j.err.txt
#SBATCH --output ./log/%x_%j.out.txt

ml palma/2023b GCC/13.2.0 R/4.4.1 Pandoc/3.1.2

mkdir -p ./output/seg
mkdir -p ./output/bin
mkdir -p ./output/gistic


Rscript ./idat_report.R