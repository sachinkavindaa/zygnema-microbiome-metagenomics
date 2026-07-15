#!/bin/bash
#SBATCH --job-name=checkm2
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --time=168:00:00
#SBATCH --mem=250gb
#SBATCH --output=checkm2.%J.out
#SBATCH --error=checkm2.%J.err
#SBATCH --partition=batch,guest

# =============================================================================
# 08_checkm2.sh — MAG quality assessment with CheckM2 (~30 min)
# =============================================================================
# Submit with: sbatch scripts/08_checkm2.sh
#
# CheckM2 uses machine learning (trained on reference genomes) to predict
# completeness and contamination for each MAG — without relying on marker genes,
# making it more accurate than CheckM1 for novel or divergent lineages.
#
# Quality thresholds (MIMAG standard; Bowers et al. 2017 Nat Biotechnol):
#   High-quality (HQ) MAG:    ≥90% complete, ≤5% contamination
#   Medium-quality (MQ) MAG:  ≥50% complete, ≤10% contamination
#   Low-quality (LQ) MAG:     <50% complete or >10% contamination
#
# Output: part_5_checkm2/checkm2_result/quality_report.tsv
# =============================================================================

set -euo pipefail

BINS_DIR="/work/yinlab/mislam17/final_project/part_4_binning/BIN_REFINEMENT_megahit/metawrap_70_10_bins"
OUT_DIR="part_5_checkm2"
THREADS="${SLURM_NTASKS_PER_NODE}"

mkdir -p "${OUT_DIR}"

echo "[INFO] Loading CheckM2..."
module load checkm2/1.0

echo "[INFO] Running CheckM2 on MAGs..."
checkm2 predict \
  --threads "${THREADS}" \
  --input "${BINS_DIR}"/*.fa \
  --output-directory "${OUT_DIR}/checkm2_result"

echo "[INFO] CheckM2 complete."
echo "[INFO] Quality report: ${OUT_DIR}/checkm2_result/quality_report.tsv"

# ── Summarize results ─────────────────────────────────────────────────────────
echo ""
echo "========== CheckM2 Quality Summary =========="
cat "${OUT_DIR}/checkm2_result/quality_report.tsv"
echo ""

echo "[INFO] High-quality MAGs (≥90% complete, ≤5% contamination):"
awk -F'\t' 'NR>1 && $2>=90 && $3<=5 {print $1, "completeness="$2"% contamination="$3"%"}' \
  "${OUT_DIR}/checkm2_result/quality_report.tsv" || echo "  None found."

module unload checkm2
