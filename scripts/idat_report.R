# Process a single IDAT pair: MNP classifier report + CNV analysis.
# Usage: Rscript idat_report.R <idat_basename> <output_dir>
#   idat_basename: path to the IDAT pair without the _Grn.idat/_Red.idat suffix
#   output_dir:    sample-specific output directory

.libPaths("/scratch/tmp/thomachr/software/R4.4/")

args <- commandArgs(trailingOnly = TRUE)
if (length(args) != 2) {
  stop("Usage: Rscript idat_report.R <idat_basename> <output_dir>")
}

idat_base  <- args[1]
output_dir <- args[2]
idat       <- basename(idat_base)

# Ensure both files of the IDAT pair exist
idat_pair <- paste0(idat_base, c("_Grn.idat", "_Red.idat"))
if (!all(file.exists(idat_pair))) {
  stop("Incomplete IDAT pair for ", idat, ": missing ",
       paste(idat_pair[!file.exists(idat_pair)], collapse = ", "))
}

library(minfi)
library(mnp.v12epicv2)
library(conumee2.0)

# Create sample output directory if it doesn't exist
if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)

cat("Processing sample:", idat, "\n")

# Load IDAT files
RGset <- read.metharray(idat_base, verbose = FALSE)

# Generate MNP report
MNPreport(RGset, output_dir = output_dir, sampleID = idat)

# Convert RGset to Mset
Mset_raw <- preprocessRaw(RGset)

# Perform CNV analysis using MNPcnv from mnp.v12epicv2
cat("Running CNV analysis for", idat, "\n")

x <- MNPcnv(Mset_raw)

# Export segmentation to .seg file
seg_filename <- file.path(output_dir, paste0(idat, "_CNV.seg"))
write.table(conumee2.0::CNV.write(x, what = "segments"), file = seg_filename, quote = FALSE, sep = "\t", row.names = FALSE)

# Export IGV bin files
igv_filename <- file.path(output_dir, paste0(idat, "_CNV.igv"))
conumee2.0::CNV.write(x, file = igv_filename, what = "bins")

# Export GISTIC files
gistic_filename <- file.path(output_dir, paste0(idat, "_gistic.seg"))
conumee2.0::CNV.write(x, file = gistic_filename, what = "gistic")

# Create genome plot
genomeplot_filename <- file.path(output_dir, paste0(idat, "_genomeplot.pdf"))
pdf(genomeplot_filename, width = 18, height = 9)
conumee2.0::CNV.genomeplot(x)
dev.off()

cat("CNV analysis completed for", idat, "\n")
