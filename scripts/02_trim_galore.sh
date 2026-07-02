#!/bin/bash
#SBATCH --job-name=trim_galore
#SBATCH --time=124:00:00
#SBATCH --mem=100gb
#SBATCH --partition=batch,guest
#SBATCH --output=trim.%J.out
#SBATCH --error=trim.%J.err
#SBATCH --ntasks=20
#SBATCH --cpus-per-task=1

# =============================================================================
# 02_trim_galore.sh — Adapter and quality trimming with Trim Galore
# =============================================================================
# Submit with: sbatch scripts/02_trim_galore.sh
#
# Purpose:
#   Remove adapter sequences and low-quality bases from paired-end reads.
#   Adapter contamination occurs when sequenced fragments are shorter than the
#   read length, causing the sequencer to read into the adapter ligated to the
#   end of the fragment.
#
# Outputs (in part_1_data_preprocessing/trim/):
#   *_val_1.fq.gz       — trimmed forward reads
#   *_val_2.fq.gz       — trimmed reverse reads
#   *_trimming_report.txt — trimming statistics per file
# =============================================================================

set -euo pipefail

RAW_DIR="/work/yinlab/mislam17/project_raw_data"
OUT_DIR="part_1_data_preprocessing/trim"

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

echo "[INFO] Loading Trim Galore..."
module unload fastqc
module load trim_galore/0.6

echo "[INFO] Starting trimming with ${SLURM_NTASKS} threads..."
trim_galore \
  --paired \
  "${RAW_DIR}/M2CH_S1_L002_R1_001.fastq.gz" \
  "${RAW_DIR}/M2CH_S1_L002_R2_001.fastq.gz" \
  -j "${SLURM_NTASKS}"

echo "[INFO] Trimming complete."
echo "[INFO] Output files:"
ls -lh .

module unload trim_galore
