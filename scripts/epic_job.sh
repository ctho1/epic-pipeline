#!/bin/bash
#SBATCH --nodes=1
#SBATCH --cpus-per-task=4
#SBATCH --partition=normal
#SBATCH --time=00:15:00
#SBATCH --mem=32G
#SBATCH --mail-type=FAIL
# Partition(s), job name and log files are set by submit_epic.sh.

# Processes a single IDAT pair. Do not submit directly, use submit_epic.sh.
# Usage: sbatch epic_job.sh <idat_report.R> <idat_basename> <sample_output_dir>

if [[ $# -ne 3 ]]; then
  echo "Usage: sbatch epic_job.sh <idat_report.R> <idat_basename> <sample_output_dir>" >&2
  exit 1
fi

R_SCRIPT="$1"
IDAT_BASE="$2"
OUT_DIR="$3"
SAMPLE_ID="$(basename "$IDAT_BASE")"

ml palma/2023b GCC/13.2.0 R/4.4.1 Pandoc/3.1.2

set -euo pipefail

# Work and temp files stay inside the sample directory,
# so parallel jobs never share intermediate files. A fresh tmp dir also
# discards leftovers when a job is preempted and restarted on requeue.
rm -rf "$OUT_DIR/tmp"
mkdir -p "$OUT_DIR/tmp"
export TMPDIR="$OUT_DIR/tmp"
cd "$OUT_DIR"
rm -f "$SAMPLE_ID.done"

echo "Sample: $SAMPLE_ID | Job: ${SLURM_JOB_ID:-local} | Partition: ${SLURM_JOB_PARTITION:-none}" \
  "| Node: $(hostname) | Restart: ${SLURM_RESTART_COUNT:-0}"

Rscript "$R_SCRIPT" "$IDAT_BASE" "$OUT_DIR"

# Mark sample as finished so submit_epic.sh skips it next time
rm -rf "$OUT_DIR/tmp"
touch "$SAMPLE_ID.done"
