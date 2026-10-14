# EPIC pipeline

MNP v12 classifier report and CNV analysis for Illumina EPIC (v2) IDAT files on a SLURM cluster (PALMA). Each IDAT pair runs as its own short job.

## Usage

```bash
# put IDAT pairs (*_Grn.idat + *_Red.idat, or .idat.gz) into ./input (subfolders allowed)
./submit_epic.sh                      # or: ./submit_epic.sh <input_dir> <output_dir>
DRY_RUN=1 ./submit_epic.sh            # only show what would be submitted
```

Run `submit_epic.sh` directly on the login node, not via `sbatch`. It submits one job per IDAT pair and skips samples that are already finished (`<id>.done`) or already queued/running. Re-run it to resubmit failed samples. Gzipped IDATs (`.idat.gz`) are unpacked next to the original before submission; the `.gz` files are kept.

## Output

```
output/<sentrix_id>/
  <sentrix_id>.html             MNP classifier report
  <sentrix_id>_genomeplot.pdf   CNV genome plot
  <sentrix_id>_CNV.seg          segments
  <sentrix_id>_CNV.igv          bins (IGV)
  <sentrix_id>_gistic.seg       GISTIC input
  <sentrix_id>.done             written on success
log/epic_<sentrix_id>_<jobid>.{out,err}.txt
```

Each job works in its own sample directory (incl. `TMPDIR`), so parallel jobs never share temporary files.

## Files

| File | Purpose |
|---|---|
| `submit_epic.sh` | Finds IDAT pairs, unpacks `.idat.gz`, submits one job each |
| `scripts/epic_job.sh` | SLURM job for a single sample (resources in `#SBATCH` header) |
| `scripts/idat_report.R` | `Rscript scripts/idat_report.R <idat_basename> <output_dir>` |

Resources can be overridden without editing files, e.g. `SBATCH_PARTITION=express SBATCH_TIMELIMIT=00:10:00 ./submit_epic.sh`.
