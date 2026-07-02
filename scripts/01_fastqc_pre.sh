#!/bin/bash
# =============================================================================
# 01_fastqc_pre.sh — Pre-trimming quality control with FastQC
# =============================================================================
# Run directly on login node (fast, ~5-10 min).
# Outputs: HTML reports and zip archives in part_1_data_preprocessing/prefastqc/
# Download the .html files to your local machine via HCC OnDemand to inspect.
# =============================================================================

set -euo pipefail

RAW_DIR="project_raw_data"
OUT_DIR="part_1_data_preprocessing/prefastqc"

cd "$(dirname "$0")/.." 2>/dev/null || true   # go to project root if run from scripts/

echo "[INFO] Loading FastQC module..."
module load fastqc

echo "[INFO] Running FastQC on raw reads..."
fastqc \
  "${RAW_DIR}/M2CH_S1_L002_R1_001.fastq.gz" \
  "${RAW_DIR}/M2CH_S1_L002_R2_001.fastq.gz" \
  --outdir "${OUT_DIR}" \
  --threads 2

echo "[INFO] FastQC complete. Results in: ${OUT_DIR}/"
echo "[INFO] Download .html files via HCC OnDemand and review:"
echo "        - Per-base sequence quality"
echo "        - Per-sequence quality scores"
echo "        - Sequence length distribution"
echo "        - Adapter content"
echo "        - GC content"

module unload fastqc
echo "[INFO] Module unloaded."
