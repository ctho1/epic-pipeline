.libPaths("/scratch/tmp/thomachr/software/R4.4/")
library(minfi)
library(mnp.v12epicv2)
library(conumee2.0)

# Create output directory if it doesn't exist
if (!dir.exists("./output")) dir.create("./output")

# Find all IDAT files
idat_files <- list.files(path = "./input", pattern = "_Grn.idat$", recursive = TRUE, full.names = TRUE)

# Get Sentrix IDs by removing "_Grn.idat" suffix
sentrix_ids <- gsub("_Grn.idat", "", basename(idat_files))

# Process each Sentrix ID
for (idat in sentrix_ids) {

  cat("Processing sample:", idat, "\n")

  # Check if output file already exists
  output_html <- paste0("./output/", idat, ".html")
  if (file.exists(output_html)) {
    cat("Skipping sample:", idat, "... output already exists.\n")
    next
  }
    
  # Get file path to IDAT pair
  matching_files <- list.files(path = "./input", pattern = paste0(idat, "_(Grn|Red).idat$"), recursive = TRUE, full.names = TRUE)
  
  # Ensure both files exist
  if (length(matching_files) < 2) {
    warning(paste("Incomplete IDAT pair for", idat, ". Skipping."))
    next
  }
  
  path_to_idat <- unique(dirname(matching_files))
  
  # Load IDAT files
  RGset <- read.metharray(file.path(path_to_idat, idat), verbose = FALSE)
  
  # Generate MNP report
  MNPreport(RGset, output_dir = "./output", sampleID = idat)
  
  # Convert RGset to Mset
  Mset_raw <- preprocessRaw(RGset)
  
  # Perform CNV analysis using MNPcnv from mnp.v12epicv2
  cat("Running CNV analysis for", idat, "\n")
  
  x <- MNPcnv(Mset_raw)
  
  # Export segmentation to .seg file
  seg_filename <- paste0("./output/seg/", idat, "_CNV.seg")
  write.table(conumee2.0::CNV.write(x, what = "segments"), file = seg_filename, quote = FALSE, sep = "\t", row.names = FALSE)
  
  # Export IGV bin files
  igv_filename <- paste0("./output/bin/", idat, "_CNV.igv")
  conumee2.0::CNV.write(x, file = igv_filename, what = "bins")
  
  # Export GISTIC files
  gistic_filename <- paste0("./output/gistic/", idat, "_gistic.seg")
  conumee2.0::CNV.write(x, file = gistic_filename, what = "gistic")
  
  # Optionally, create genome plot
  genomeplot_filename <- paste0("./output/", idat, "_genomeplot.pdf")
  pdf(genomeplot_filename, width = 18, height = 9)
  conumee2.0::CNV.genomeplot(x)
  dev.off()
  
  cat("CNV analysis completed for", idat, "\n")
}

