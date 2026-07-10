#!/bin/bash
#SBATCH --job-name=metaspades_assembly
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=32
#SBATCH --time=168:00:00
#SBATCH --mem=250gb
#SBATCH --output=metaspades.%J.out
#SBATCH --error=metaspades.%J.err
#SBATCH --partition=yinlab,batch,guest

# =============================================================================
# 06_metaspades_assembly.sh — Metagenome assembly with MetaSPAdes (~8 hrs)
# =============================================================================
# Submit with: sbatch scripts/06_metaspades_assembly.sh
#
# Optional — run to compare with MEGAHIT results.
# MetaSPAdes often produces longer, more complete contigs but requires much
# more time and memory than MEGAHIT.
#
# Outputs (in part_3_assembly/metaspade_result/):
#   contigs.fasta    — assembled contigs
#   scaffolds.fasta  — scaffolded contigs (use contigs.fasta for downstream)
# =============================================================================

set -euo pipefail

UNMAPPED_DIR="/work/yinlab/mislam17/final_project/part_2_remove_algae_genomes"
OUT_DIR="part_3_assembly"
THREADS="${SLURM_NTASKS_PER_NODE}"

mkdir -p "${OUT_DIR}"

echo "[INFO] Loading SPAdes..."
module load spades/py35/3.13

echo "[INFO] Starting MetaSPAdes assembly with ${THREADS} threads..."
spades.py \
  --meta \
  -1 "${UNMAPPED_DIR}/unmapped_1.fastq" \
  -2 "${UNMAPPED_DIR}/unmapped_2.fastq" \
  -o "${OUT_DIR}/metaspade_result" \
  --threads "${THREADS}"

echo "[INFO] MetaSPAdes assembly complete."
echo "[INFO] Outputs:"
ls -lh "${OUT_DIR}/metaspade_result/"

# ── Compare assembly stats ────────────────────────────────────────────────────
echo "[INFO] Computing assembly statistics..."
module unload spades
module load seqkit

seqkit stats \
  "${OUT_DIR}/metaspade_result/contigs.fasta" \
  "${OUT_DIR}/megahit_result/final.contigs.fa" \
  > "${OUT_DIR}/assembly_comparison.txt" 2>/dev/null || true

echo "[INFO] Assembly comparison:"
cat "${OUT_DIR}/assembly_comparison.txt" 2>/dev/null || \
  seqkit stats "${OUT_DIR}/metaspade_result/contigs.fasta"

module unload seqkit
