# EPIC pipeline

MNP v12 classifier report and CNV analysis for Illumina EPIC (v2) IDAT files on a SLURM cluster (PALMA). Each IDAT pair runs as its own short job.

## Usage

```bash
# put IDAT pairs (*_Grn.idat + *_Red.idat, or .idat.gz) into ./input (subfolders allowed)
./submit_epic.sh                      # or: ./submit_epic.sh <input_dir> <output_dir>
DRY_RUN=1 ./submit_epic.sh            # only show what would be submitted
./submit_epic.sh --partition normal   # skip automatic partition choice
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

Each job keeps all temporary files in its own sample directory (`TMPDIR`, incl. the rmarkdown intermediates of the MNP report, which would otherwise be written into the shared package directory), so parallel jobs never collide.

## Files

| File | Purpose |
|---|---|
| `submit_epic.sh` | Finds IDAT pairs, unpacks `.idat.gz`, submits one job each |
| `scripts/epic_job.sh` | SLURM job for a single sample (resources in `#SBATCH` header) |
| `scripts/idat_report.R` | `Rscript scripts/idat_report.R <idat_basename> <output_dir>` |

## Partitions and resources

Jobs are submitted to both **`normal`** and **`requeue`** (only those that are up, checked via `sinfo`), and SLURM starts each job on whichever frees up first. Jobs preempted on `requeue` restart from scratch, which is cheap at ~10 min per sample.

```bash
SLURM_CPU_PARTITIONS=normal ./submit_epic.sh   # candidate partitions (default: normal,requeue)
SLURM_AUTO_PARTITION=false ./submit_epic.sh    # always use SLURM_FALLBACK_PARTITION (default: normal)
SBATCH_TIMELIMIT=00:10:00 ./submit_epic.sh     # other sbatch options via SBATCH_* env vars
```

Per job: 4 CPUs, 32 GB RAM, 15 min (see `scripts/epic_job.sh`).
