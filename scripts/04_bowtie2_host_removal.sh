#!/bin/bash
#SBATCH --job-name=bowtie2_host_removal
#SBATCH --nodes=1
#SBATCH --ntasks-per-node=16
#SBATCH --time=168:00:00
#SBATCH --mem=30gb
#SBATCH --output=bowtie2.%J.out
#SBATCH --error=bowtie2.%J.err
#SBATCH --partition=batch,guest

# =============================================================================
# 04_bowtie2_host_removal.sh — Remove algal host reads via reference mapping
# =============================================================================
# Submit with: sbatch scripts/04_bowtie2_host_removal.sh
#
# Strategy:
#   Map all reads against the algal reference genomes (nuclear + plastid +
#   mitogenome). Reads that fail to map = microbiome reads. We use
#   samtools -f 12 to extract read pairs where BOTH mates are unmapped.
#
# Outputs (in part_2_remove_algae_genomes/):
#   unmapped_1.fastq  — de-contaminated forward reads (microbiome)
#   unmapped_2.fastq  — de-contaminated reverse reads (microbiome)
#
# Samtools flag meanings:
#   -f 12   = keep reads where: read unmapped (0x4) AND mate unmapped (0x8)
#   -F 256  = exclude secondary alignments
# =============================================================================

set -euo pipefail

TRIM_DIR="/work/yinlab/mislam17/final_project/part_1_data_preprocessing/trim"
REF_DIR="part_2_remove_algae_genomes/reference_genome"
OUT_DIR="part_2_remove_algae_genomes"
THREADS="${SLURM_NTASKS_PER_NODE}"

echo "[INFO] Loading modules..."
module load bowtie/2.5 samtools/1.9

# ── Prepare reference genome ──────────────────────────────────────────────────
echo "[INFO] Concatenating reference genomes..."
mkdir -p "${REF_DIR}"
cd "${REF_DIR}"
cp -r /work/yinlab/mislam17/final_project/reference_genome/* .
cat * > algae_reference_genome.fna
cd ../../

# ── Build Bowtie2 index ───────────────────────────────────────────────────────
echo "[INFO] Building Bowtie2 index (this may take a few minutes)..."
bowtie2-build \
  /work/yinlab/mislam17/final_project/part_2_remove_algae_genomes/reference_genome/algae_reference_genome.fna \
  "${REF_DIR}/index_prefix"

# ── Align reads to reference ──────────────────────────────────────────────────
echo "[INFO] Mapping reads to algal reference genome..."
bowtie2 \
  -x "${REF_DIR}/index_prefix" \
  -1 "${TRIM_DIR}/M2CH_S1_L002_R1_001_val_1.fq.gz" \
  -2 "${TRIM_DIR}/M2CH_S1_L002_R2_001_val_2.fq.gz" \
  -S "${OUT_DIR}/bowtie2_alignments.sam" \
  --local \
  -p "${THREADS}"

# ── Convert, sort, and index BAM ──────────────────────────────────────────────
echo "[INFO] Converting SAM → BAM, sorting, indexing..."
samtools view -bS -@ "${THREADS}" "${OUT_DIR}/bowtie2_alignments.sam" \
  > "${OUT_DIR}/bowtie2_alignments.bam"

samtools sort -@ "${THREADS}" "${OUT_DIR}/bowtie2_alignments.bam" \
  -o "${OUT_DIR}/bowtie2_alignments.sorted.bam"

samtools index "${OUT_DIR}/bowtie2_alignments.sorted.bam"

# ── Extract unmapped pairs ────────────────────────────────────────────────────
echo "[INFO] Extracting unmapped read pairs (microbiome reads)..."
samtools view -b -f 12 -F 256 -@ "${THREADS}" \
  "${OUT_DIR}/bowtie2_alignments.sorted.bam" \
  > "${OUT_DIR}/unmapped.bam"

samtools fastq -@ "${THREADS}" \
  -1 "${OUT_DIR}/unmapped_1.fastq" \
  -2 "${OUT_DIR}/unmapped_2.fastq" \
  "${OUT_DIR}/unmapped.bam"

# ── Summary ───────────────────────────────────────────────────────────────────
echo "[INFO] Host removal complete."
echo "[INFO] Microbiome reads saved to:"
echo "        ${OUT_DIR}/unmapped_1.fastq"
echo "        ${OUT_DIR}/unmapped_2.fastq"
echo "[INFO] Read counts:"
echo "  unmapped_1: $(grep -c '^@' "${OUT_DIR}/unmapped_1.fastq") reads"
echo "  unmapped_2: $(grep -c '^@' "${OUT_DIR}/unmapped_2.fastq") reads"

# Clean up large intermediate files
rm -f "${OUT_DIR}/bowtie2_alignments.sam" "${OUT_DIR}/bowtie2_alignments.bam"

module unload bowtie samtools
