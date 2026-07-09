#!/bin/bash
#SBATCH --job-name=megahit_assembly
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=168:00:00
#SBATCH --mem=250gb
#SBATCH --output=megahit.%J.out
#SBATCH --error=megahit.%J.err
#SBATCH --partition=yinlab,batch,guest

# =============================================================================
# 05_megahit_assembly.sh — Metagenome assembly with MEGAHIT (~40 min)
# =============================================================================
# Submit with: sbatch scripts/05_megahit_assembly.sh
#
# MEGAHIT uses succinct de Bruijn graphs with multiple k-mer sizes, making it
# highly memory-efficient and fast for large metagenomic datasets.
#
# Outputs (in part_3_assembly/megahit_result/):
#   final.contigs.fa  — assembled contigs (use this for downstream analysis)
#   log               — assembly log with k-mer iteration details
# =============================================================================

set -euo pipefail

UNMAPPED_DIR="/work/yinlab/mislam17/final_project/part_2_remove_algae_genomes"
OUT_DIR="part_3_assembly"
THREADS="${SLURM_NTASKS_PER_NODE}"

mkdir -p "${OUT_DIR}"

echo "[INFO] Loading MEGAHIT..."
module load megahit/1.2

echo "[INFO] Starting MEGAHIT assembly with ${THREADS} threads..."
megahit \
  -1 "${UNMAPPED_DIR}/unmapped_1.fastq" \
  -2 "${UNMAPPED_DIR}/unmapped_2.fastq" \
  -o "${OUT_DIR}/megahit_result" \
  -t "${THREADS}"

echo "[INFO] Assembly complete."
echo "[INFO] Output: ${OUT_DIR}/megahit_result/final.contigs.fa"

# ── Assembly statistics ───────────────────────────────────────────────────────
echo "[INFO] Computing assembly statistics with SeqKit..."
module unload megahit
module load seqkit

seqkit stats "${OUT_DIR}/megahit_result/final.contigs.fa" \
  > "${OUT_DIR}/megahit_stats.txt"

cat "${OUT_DIR}/megahit_stats.txt"
echo "[INFO] Stats saved to: ${OUT_DIR}/megahit_stats.txt"

module unload seqkit
