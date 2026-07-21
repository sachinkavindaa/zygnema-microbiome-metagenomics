#!/bin/bash
#SBATCH --job-name=dram_annotation
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --time=168:00:00
#SBATCH --mem=20gb
#SBATCH --output=dram.%J.out
#SBATCH --error=dram.%J.err
#SBATCH --partition=batch,guest

# =============================================================================
# 10_dram.sh — Gene prediction and metabolic annotation with DRAM (~8 hrs)
# =============================================================================
# Submit with: sbatch scripts/10_dram.sh
#
# DRAM (Distilled and Refined Annotation of Metabolism) combines Prodigal
# gene calling with annotation against 7 databases:
#   - KEGG (metabolism)
#   - UniRef90 (broad functional coverage)
#   - Pfam (protein domains)
#   - dbCAN (carbohydrate-active enzymes — CAZymes)
#   - RefSeq viral (viral proteins)
#   - MEROPS (peptidases)
#   - VOGDB (viral orthologous groups)
#
# Two-step workflow:
#   1. annotate  — gene calling + DB search for every MAG
#   2. distill   — summarize into per-MAG metabolic pathway presence/absence
#
# Key outputs (in part_7_functional_annotation/):
#   annotation/annotations.tsv      — per-gene annotation table
#   annotation/trnas.tsv            — tRNA predictions
#   annotation/rrnas.tsv            — rRNA predictions
#   distill/metabolism_summary.xlsx — metabolic pathway summary
#   distill/product.html            — interactive heatmap (download to view)
#
# References:
#   Shaffer et al. (2020) Nucleic Acids Research doi:10.1093/nar/gkaa621
#   https://github.com/WrightonLabCSU/DRAM
#   Tutorial: https://genomicsaotearoa.github.io/metagenomics_summer_school/
# =============================================================================

set -euo pipefail

BINS_DIR="/work/yinlab/mislam17/final_project/part_4_binning/BIN_REFINEMENT_megahit/metawrap_70_10_bins"
OUT_DIR="part_7_functional_annotation"

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

echo "[INFO] Loading DRAM 1.2..."
module load dram/1.2

# ── Step 1: Annotate genes across all MAGs ────────────────────────────────────
echo "[INFO] Running DRAM annotate on all MAGs..."
echo "[INFO] Input: ${BINS_DIR}/*.fa"

DRAM.py annotate \
  -i "${BINS_DIR}/*.fa" \
  -o annotation

echo "[INFO] DRAM annotation complete."
echo "[INFO] Annotation files:"
ls -lh annotation/

# ── Step 2: Distill to metabolic summaries ────────────────────────────────────
echo "[INFO] Running DRAM distill (metabolic pathway summaries)..."
DRAM.py distill \
  -i annotation/annotations.tsv \
  -o distill \
  --trna_path annotation/trnas.tsv \
  --rrna_path annotation/rrnas.tsv

echo "[INFO] DRAM distillation complete."
echo ""
echo "========== DRAM Output Summary =========="
echo "Annotation table:        $(wc -l < annotation/annotations.tsv) genes annotated"
echo "tRNA genes:              $(wc -l < annotation/trnas.tsv 2>/dev/null || echo 'N/A')"
echo "rRNA genes:              $(wc -l < annotation/rrnas.tsv 2>/dev/null || echo 'N/A')"
echo ""
echo "[INFO] Key output files:"
echo "  annotation/annotations.tsv       — full per-gene annotation table"
echo "  distill/metabolism_summary.xlsx  — pathway presence/absence per MAG"
echo "  distill/product.html             — interactive heatmap (download to view)"
echo ""
echo "[INFO] Download distill/product.html via HCC OnDemand to view"
echo "       metabolic heatmaps for each MAG. Interpret results alongside"
echo "       GTDB taxonomy from Part 6."

module unload dram
