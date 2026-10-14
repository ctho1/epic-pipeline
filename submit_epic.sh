#!/bin/bash
# Submits one SLURM job per IDAT pair found in the input directory.
# Run on the login node (not via sbatch):
#   ./submit_epic.sh [input_dir] [output_dir]
# Defaults: ./input and ./output next to this script.
# Set DRY_RUN=1 to only print what would be submitted.

set -euo pipefail

if [[ -n "${SLURM_JOB_ID:-}" ]]; then
  echo "Run this script directly (./submit_epic.sh), not via sbatch." >&2
  exit 1
fi

EPIC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INPUT_DIR="${1:-$EPIC_DIR/input}"
OUTPUT_DIR="${2:-$EPIC_DIR/output}"
LOG_DIR="$EPIC_DIR/log"
SCRIPT_DIR="$EPIC_DIR/scripts"
DRY_RUN="${DRY_RUN:-0}"

if [[ ! -d "$INPUT_DIR" ]]; then
  echo "Input directory not found: $INPUT_DIR" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$LOG_DIR"
INPUT_DIR="$(cd "$INPUT_DIR" && pwd)"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

# Unpacks <file>.idat.gz to <file>.idat unless the .idat already exists.
# Writes to a temp file first, so an interrupted run never leaves a truncated IDAT.
ensure_unpacked() {
  local idat="$1"
  [[ -f "$idat" ]] && return 0
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry run] would unpack $(basename "$idat").gz"
    return 0
  fi
  if gzip -dc "$idat.gz" > "$idat.part" && mv "$idat.part" "$idat"; then
    echo "Unpacked $(basename "$idat").gz"
  else
    rm -f "$idat.part"
    echo "WARNING: could not unpack $idat.gz" >&2
    return 1
  fi
}

# Names of this user's queued/running jobs, to avoid double submission
queued="$(squeue -h -u "$USER" -o '%j' 2>/dev/null || true)"

submitted=0
skipped=0
incomplete=0

while IFS= read -r -d '' grn; do
  # Already unpacked: the plain .idat is handled instead
  if [[ "$grn" == *.gz && -f "${grn%.gz}" ]]; then
    continue
  fi

  base="${grn%.gz}"
  base="${base%_Grn.idat}"
  id="$(basename "$base")"
  job_name="epic_${id}"
  sample_dir="$OUTPUT_DIR/$id"

  if [[ ! -f "${base}_Red.idat" && ! -f "${base}_Red.idat.gz" ]]; then
    echo "WARNING: incomplete IDAT pair for $id (missing _Red.idat), skipping."
    incomplete=$((incomplete + 1))
    continue
  fi

  if [[ -f "$sample_dir/$id.done" ]]; then
    echo "Skipping $id: output already exists."
    skipped=$((skipped + 1))
    continue
  fi

  if grep -qxF "$job_name" <<< "$queued"; then
    echo "Skipping $id: job already queued or running."
    skipped=$((skipped + 1))
    continue
  fi

  if ! ensure_unpacked "${base}_Grn.idat" || ! ensure_unpacked "${base}_Red.idat"; then
    echo "WARNING: unpacking failed for $id, skipping."
    incomplete=$((incomplete + 1))
    continue
  fi

  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry run] would submit $id -> $sample_dir"
  else
    mkdir -p "$sample_dir"
    job_id="$(sbatch --parsable \
      --job-name="$job_name" \
      --output="$LOG_DIR/%x_%j.out.txt" \
      --error="$LOG_DIR/%x_%j.err.txt" \
      "$SCRIPT_DIR/epic_job.sh" "$SCRIPT_DIR/idat_report.R" "$base" "$sample_dir")"
    echo "Submitted $id (job $job_id)"
  fi
  queued+=$'\n'"$job_name"
  submitted=$((submitted + 1))
done < <(find "$INPUT_DIR" -type f \( -name '*_Grn.idat' -o -name '*_Grn.idat.gz' \) -print0 | sort -z)

echo "Done: $submitted submitted, $skipped skipped, $incomplete incomplete."
