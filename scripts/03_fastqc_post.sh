#!/bin/bash
# =============================================================================
# 03_fastqc_post.sh — Post-trimming quality control with FastQC
# =============================================================================
# Run directly on login node after trim_galore job completes.
# Compare these results to 01_fastqc_pre.sh to confirm adapter removal
# and quality improvement.
# =============================================================================

set -euo pipefail

TRIM_DIR="part_1_data_preprocessing/trim"
OUT_DIR="part_1_data_preprocessing/postfastqc"

mkdir -p "${OUT_DIR}"

echo "[INFO] Loading FastQC module..."
module load fastqc

echo "[INFO] Running FastQC on trimmed reads..."
fastqc \
  "${TRIM_DIR}/M2CH_S1_L002_R1_001_val_1.fq.gz" \
  "${TRIM_DIR}/M2CH_S1_L002_R2_001_val_2.fq.gz" \
  --outdir "${OUT_DIR}" \
  --threads 2

echo "[INFO] Post-trim FastQC complete. Results in: ${OUT_DIR}/"
echo "[INFO] Compare pre- vs post-trim HTML reports for:"
echo "        - Improved per-base quality scores (especially 3' ends)"
echo "        - Removal of adapter content"
echo "        - More uniform read lengths after trimming"

module unload fastqc
echo "[INFO] Module unloaded."
