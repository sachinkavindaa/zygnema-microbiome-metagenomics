#!/bin/bash
#SBATCH --job-name=metawrap_binning
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=168:00:00
#SBATCH --mem=250gb
#SBATCH --output=metawrap.%J.out
#SBATCH --error=metawrap.%J.err
#SBATCH --partition=yinlab,batch,guest

# =============================================================================
# 07_metawrap_binning.sh — Contig binning and refinement with MetaWRAP (~3.5 hrs)
# =============================================================================
# Submit with: sbatch scripts/07_metawrap_binning.sh
#
# MetaWRAP runs three independent binners (MetaBAT2, MaxBin2, CONCOCT),
# then bin_refinement consolidates their outputs and selects the best bins
# from all possible bin set combinations (A, B, C, AB, AC, BC, ABC).
#
# Binners overview:
#   MetaBAT2  — uses tetranucleotide frequency + coverage depth
#   MaxBin2   — uses EM algorithm on coverage + sequence composition
#   CONCOCT   — uses coverage variation across samples + k-mer profiles
#
# Output threshold: ≥70% completeness, ≤10% contamination
# Final MAGs: part_4_binning/BIN_REFINEMENT_megahit/metawrap_70_10_bins/*.fa
# =============================================================================

set -euo pipefail

ASSEMBLY="/work/yinlab/mislam17/final_project/part_3_assembly/megahit_result/final.contigs.fa"
UNMAPPED_DIR="/work/yinlab/mislam17/final_project/part_2_remove_algae_genomes"
OUT_DIR="part_4_binning"
THREADS="${SLURM_NTASKS_PER_NODE}"

mkdir -p "${OUT_DIR}"
cd "${OUT_DIR}"

echo "[INFO] Loading MetaWRAP..."
module load metawrap/1.3

# ── Step 1: Run three binners ─────────────────────────────────────────────────
echo "[INFO] Running binning (MetaBAT2 + MaxBin2 + CONCOCT)..."
metawrap binning \
  -o BINNING_megahit \
  -t 16 \
  -a "${ASSEMBLY}" \
  --metabat2 --maxbin2 --concoct \
  "${UNMAPPED_DIR}/unmapped_1.fastq" \
  "${UNMAPPED_DIR}/unmapped_2.fastq" \
  -t 16

echo "[INFO] Individual binning complete."

# ── Step 2: Bin refinement ────────────────────────────────────────────────────
echo "[INFO] Running bin refinement (consolidating binner results)..."
metawrap bin_refinement \
  -o BIN_REFINEMENT_megahit \
  -t "${THREADS}" \
  -A BINNING_megahit/metabat2_bins/ \
  -B BINNING_megahit/maxbin2_bins/ \
  -C BINNING_megahit/concoct_bins/

echo "[INFO] Bin refinement complete."
echo "[INFO] Final MAGs (≥70% complete, ≤10% contamination):"
ls -lh BIN_REFINEMENT_megahit/metawrap_70_10_bins/*.fa 2>/dev/null || \
  echo "[WARN] No bins passed quality threshold, check error log."

echo "[INFO] Number of MAGs recovered:"
ls BIN_REFINEMENT_megahit/metawrap_70_10_bins/*.fa 2>/dev/null | wc -l

module unload metawrap
