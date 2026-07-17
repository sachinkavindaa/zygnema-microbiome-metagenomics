#!/bin/bash
#SBATCH --job-name=gtdbtk_taxonomy
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --time=168:00:00
#SBATCH --mem=250gb
#SBATCH --output=gtdb.%J.out
#SBATCH --error=gtdb.%J.err
#SBATCH --partition=batch,guest

# =============================================================================
# 09_gtdbtk.sh — Taxonomic annotation of MAGs with GTDB-Tk (~1-2 hrs)
# =============================================================================
# Submit with: sbatch scripts/09_gtdbtk.sh
#
# GTDB-Tk places MAGs into the Genome Taxonomy Database (GTDB) phylogeny
# using marker gene phylogenetics and average nucleotide identity (ANI).
# GTDB uses a standardized, rank-normalized taxonomy that often differs
# from NCBI taxonomy (e.g., many "Proteobacteria" are reclassified).
#
# Output files (in part_6_taxonomic_annotation/GTDB/):
#   gtdbtk.bac120.summary.tsv   — bacterial MAG taxonomy
#   gtdbtk.ar53.summary.tsv     — archaeal MAG taxonomy (if any)
#   gtdbtk.*.classify.tree      — placement trees
# =============================================================================

set -euo pipefail

BINS_DIR="/work/yinlab/mislam17/final_project/part_4_binning/BIN_REFINEMENT_megahit/metawrap_70_10_bins"
OUT_DIR="part_6_taxonomic_annotation"
THREADS="${SLURM_NTASKS_PER_NODE}"

mkdir -p "${OUT_DIR}"

echo "[INFO] Loading GTDB-Tk..."
module load gtdbtk/1.5

echo "[INFO] Running GTDB-Tk classify workflow..."
gtdbtk classify_wf \
  --genome_dir "${BINS_DIR}" \
  --out_dir "${OUT_DIR}/GTDB" \
  --cpus "${THREADS}" \
  --extension .fa

echo "[INFO] GTDB-Tk taxonomy annotation complete."
echo ""
echo "========== Bacterial MAG Taxonomy Summary =========="
if [ -f "${OUT_DIR}/GTDB/gtdbtk.bac120.summary.tsv" ]; then
  awk -F'\t' '{print $1, $2}' "${OUT_DIR}/GTDB/gtdbtk.bac120.summary.tsv"
else
  echo "[WARN] No bacterial summary file found — check GTDB output."
fi

echo ""
echo "========== Archaeal MAG Taxonomy Summary =========="
if [ -f "${OUT_DIR}/GTDB/gtdbtk.ar53.summary.tsv" ]; then
  awk -F'\t' '{print $1, $2}' "${OUT_DIR}/GTDB/gtdbtk.ar53.summary.tsv"
else
  echo "  No archaeal MAGs detected."
fi

module unload gtdbtk
