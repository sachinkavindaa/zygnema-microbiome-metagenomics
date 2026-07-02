#!/bin/bash
# =============================================================================
# 00_setup.sh — Workspace setup and raw data preparation
# =============================================================================
# Usage: bash 00_setup.sh <your_username>
# Run directly on login node (no compute needed).
# =============================================================================

set -euo pipefail

USERNAME=${1:?"Usage: bash 00_setup.sh <your_username>"}
WORKDIR="/work/fdst396/${USERNAME}/final_project"

echo "[INFO] Creating project directory: ${WORKDIR}"
mkdir -p "${WORKDIR}"
cd "${WORKDIR}"

echo "[INFO] Copying raw sequencing data..."
cp -r /work/yinlab/mislam17/final_project/project_raw_data .

echo "[INFO] Creating subdirectory structure..."
mkdir -p \
  part_1_data_preprocessing/prefastqc \
  part_1_data_preprocessing/trim \
  part_1_data_preprocessing/postfastqc \
  part_2_remove_algae_genomes/reference_genome \
  part_3_assembly \
  part_4_binning \
  part_5_checkm2 \
  part_6_taxonomic_annotation \
  part_7_functional_annotation

echo "[INFO] Setup complete. Project root: ${WORKDIR}"
echo "[INFO] Raw data location: ${WORKDIR}/project_raw_data/"
ls -lh project_raw_data/
