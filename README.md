# 🌿 Zygnema Microbiome Metagenomics Pipeline

> **Shotgun metagenomics analysis of the microbiome associated with the green alga *Zygnema circumcarinatum* MZCH241** — from raw Illumina reads to Metagenome-Assembled Genomes (MAGs), taxonomic classification, and functional annotation.

---

## 🔬 Project Overview

*Zygnema* (class Zygnematophyceae) is the closest living relative of land plants and a key model for understanding the evolution of terrestrial adaptation. Yet almost nothing is known about its associated microbiome.

This pipeline takes paired-end Illumina metagenomic reads from *Zygnema circumcarinatum* MZCH241 cultures (host algae + microbiome co-sequenced) and:

1. Assesses and trims raw read quality
2. Removes host (algal) reads via reference-guided mapping
3. Assembles the remaining microbiome reads into contigs
4. Bins contigs into draft genomes (MAGs)
5. Evaluates MAG quality and completeness
6. Assigns taxonomy to each MAG
7. Predicts genes and annotates metabolic functions

---

## 🧬 Scientific Background

| Question | Approach |
|---|---|
| What microbes live with *Zygnema*? | Shotgun metagenomics + GTDB-Tk taxonomy |
| How do they support algal survival? | DRAM functional annotation (metabolic pathways) |
| How complete are the recovered genomes? | CheckM2 quality assessment |
| How does assembly method affect results? | MEGAHIT vs. MetaSPAdes comparison |

**Why this matters:** Land plants evolved from aquatic charophyte algae ~600 million years ago. Microbes are thought to have played a central role in facilitating that transition. *Zygnema* microbiome data is essentially absent from the literature — this project represents a novel contribution.

---

## 📁 Repository Structure

```
zygnema-microbiome-metagenomics/
│
├── README.md                      # This file
├── protocol_final_project.txt     # Full command reference (original protocol)
│
├── scripts/
│   ├── 00_setup.sh                # Workspace setup and data copy
│   ├── 01_fastqc_pre.sh           # Pre-trim quality control
│   ├── 02_trim_galore.sh          # Adapter/quality trimming (SLURM)
│   ├── 03_fastqc_post.sh          # Post-trim quality control
│   ├── 04_bowtie2_host_removal.sh # Algal host read removal (SLURM)
│   ├── 05_megahit_assembly.sh     # MEGAHIT metagenome assembly (SLURM)
│   ├── 06_metaspades_assembly.sh  # MetaSPAdes assembly (SLURM, optional)
│   ├── 07_metawrap_binning.sh     # MetaWRAP binning + refinement (SLURM)
│   ├── 08_checkm2.sh              # MAG quality assessment (SLURM)
│   ├── 09_gtdbtk.sh               # Taxonomic annotation (SLURM)
│   └── 10_dram.sh                 # Gene prediction & functional annotation (SLURM)
│
├── docs/
│   ├── pipeline_overview.md       # Detailed method descriptions
│   ├── tools_and_versions.md      # Software versions and citations
│   └── interpreting_results.md    # Guide to reading outputs
│
├── environment/
│   └── hcc_modules.md             # HCC module load commands per step
│
└── results/                       # Placeholder — outputs go here (not tracked in git)
    └── .gitkeep
```

---

## ⚙️ Pipeline Steps

### Part 0 — Data Preparation

```bash
cd /work/fdst396/<your_username>
mkdir final_project && cd final_project
cp -r /work/yinlab/mislam17/final_project/project_raw_data .
```

Two paired-end FASTQ files: `M2CH_S1_L002_R1_001.fastq.gz` and `M2CH_S1_L002_R2_001.fastq.gz`

---

### Part 1 — Data Preprocessing (~2 hrs)

**Tools:** FastQC · Trim Galore

```bash
# Pre-trim quality check
ml fastqc
fastqc R1.fastq.gz R2.fastq.gz --outdir prefastqc/

# Trim adapters and low-quality bases
ml trim_galore/0.6
trim_galore --paired R1.fastq.gz R2.fastq.gz -j 20

# Post-trim quality check
fastqc trimmed_R1.fq.gz trimmed_R2.fq.gz --outdir postfastqc/
```

See [`scripts/01_fastqc_pre.sh`](scripts/01_fastqc_pre.sh), [`scripts/02_trim_galore.sh`](scripts/02_trim_galore.sh), [`scripts/03_fastqc_post.sh`](scripts/03_fastqc_post.sh)

---

### Part 2 — Host Read Removal (~1–2 hrs)

**Tools:** Bowtie2 · Samtools

Reference genomes: algal nuclear genome + plastid + mitogenome concatenated into `algae_reference_genome.fna`

```bash
ml bowtie/2.5 samtools/1.9

# Build index
bowtie2-build algae_reference_genome.fna index_prefix

# Map reads; extract unmapped (microbiome) reads
bowtie2 -x index_prefix -1 R1.fq.gz -2 R2.fq.gz -S aligned.sam --local -p 16
samtools view -bS aligned.sam | samtools sort -o sorted.bam
samtools index sorted.bam
samtools view -b -f 12 -F 256 sorted.bam > unmapped.bam
samtools fastq -1 unmapped_1.fastq -2 unmapped_2.fastq unmapped.bam
```

`-f 12` selects read pairs where **both** mates are unmapped — these are the microbiome reads.

See [`scripts/04_bowtie2_host_removal.sh`](scripts/04_bowtie2_host_removal.sh)

---

### Part 3 — Metagenome Assembly (~40 min – 8 hrs)

**Tools:** MEGAHIT · MetaSPAdes

```bash
# MEGAHIT (recommended; ~40 min)
ml megahit/1.2
megahit -1 unmapped_1.fastq -2 unmapped_2.fastq -o megahit_result -t 32
# Output: megahit_result/final.contigs.fa

# MetaSPAdes (alternative; ~8 hrs)
ml spades/py35/3.13
spades.py --meta -1 unmapped_1.fastq -2 unmapped_2.fastq -o metaspade_result --threads 32
# Output: metaspade_result/contigs.fasta

# Assembly statistics
ml seqkit
seqkit stats final.contigs.fa
```

See [`scripts/05_megahit_assembly.sh`](scripts/05_megahit_assembly.sh), [`scripts/06_metaspades_assembly.sh`](scripts/06_metaspades_assembly.sh)

---

### Part 4 — Binning and Bin Refinement (~3.5 hrs)

**Tools:** MetaWRAP (MetaBAT2 + MaxBin2 + CONCOCT)

```bash
ml metawrap/1.3

# Run three binners simultaneously
metawrap binning -o BINNING_megahit -t 16 \
  -a megahit_result/final.contigs.fa \
  --metabat2 --maxbin2 --concoct \
  unmapped_1.fastq unmapped_2.fastq

# Refine and consolidate bins
metawrap bin_refinement -o BIN_REFINEMENT_megahit -t 32 \
  -A BINNING_megahit/metabat2_bins/ \
  -B BINNING_megahit/maxbin2_bins/ \
  -C BINNING_megahit/concoct_bins/
```

Final MAGs: `BIN_REFINEMENT_megahit/metawrap_70_10_bins/*.fa`
(≥70% completeness, ≤10% contamination threshold)

See [`scripts/07_metawrap_binning.sh`](scripts/07_metawrap_binning.sh)

---

### Part 5 — MAG Quality Assessment (~30 min)

**Tool:** CheckM2

```bash
ml checkm2/1.0
checkm2 predict --threads 16 \
  --input BIN_REFINEMENT_megahit/metawrap_70_10_bins/*.fa \
  --output-directory checkm2_result/
```

High-quality MAGs (MIMAG standard): **≥90% completeness**, **≤5% contamination**

See [`scripts/08_checkm2.sh`](scripts/08_checkm2.sh)

---

### Part 6 — Taxonomic Annotation (~1–2 hrs)

**Tool:** GTDB-Tk v1.5 (Genome Taxonomy Database)

```bash
ml gtdbtk/1.5
gtdbtk classify_wf \
  --genome_dir BIN_REFINEMENT_megahit/metawrap_70_10_bins/ \
  --out_dir GTDB/ \
  --cpus 16 --extension .fa
```

See [`scripts/09_gtdbtk.sh`](scripts/09_gtdbtk.sh)

---

### Part 7 — Gene Prediction & Functional Annotation (~8 hrs)

**Tool:** DRAM v1.2 (Distilled and Refined Annotation of Metabolism)

```bash
ml dram/1.2

# Annotate genes across all MAGs
DRAM.py annotate \
  -i 'BIN_REFINEMENT_megahit/metawrap_70_10_bins/*.fa' \
  -o annotation/

# Distill to metabolic summary
DRAM.py distill \
  -i annotation/annotations.tsv \
  -o distill/ \
  --trna_path annotation/trnas.tsv \
  --rrna_path annotation/rrnas.tsv
```

DRAM integrates 7 databases (KEGG, UniRef, Pfam, dbCAN, RefSeq viral, MEROPS, VOGDB) and produces interactive HTML heatmaps of metabolic pathways per MAG.

See [`scripts/10_dram.sh`](scripts/10_dram.sh)

---

## 🧰 Tools Summary

| Tool | Version | Purpose |
|---|---|---|
| FastQC | latest | Read quality assessment |
| Trim Galore | 0.6 | Adapter trimming & quality filtering |
| Bowtie2 | 2.5 | Host genome alignment |
| Samtools | 1.9 | SAM/BAM manipulation |
| MEGAHIT | 1.2 | Fast metagenome assembly |
| MetaSPAdes | 3.13 | Alternative metagenome assembly |
| SeqKit | latest | Assembly statistics |
| MetaWRAP | 1.3 | Binning pipeline (MetaBAT2 + MaxBin2 + CONCOCT) |
| CheckM2 | 1.0 | MAG completeness/contamination assessment |
| GTDB-Tk | 1.5 | Phylogenomic taxonomy classification |
| DRAM | 1.2 | Gene prediction & metabolic annotation |

---

## 🖥️ HPC Environment

All jobs run on the **University of Nebraska HCC Swan/Crane cluster** using SLURM.

```bash
# General SLURM tips
sbatch script.sh          # submit a job
squeue -u $USER           # check your jobs
scancel <job_id>          # cancel a job
module avail <tool>       # search available modules
module load <tool>        # load a module
module unload <tool>      # unload before loading next (avoid conflicts)
```

> ⚠️ **Never run compute-heavy jobs on the login node.** Always use SLURM `sbatch` scripts.

Available HCC software: https://hcc.unl.edu/docs/applications/modules/available_software_for_swan/

---

## 📊 Expected Outputs

| Step | Key Output Files |
|---|---|
| FastQC | `*_fastqc.html`, `*_fastqc.zip` |
| Trim Galore | `*_val_1.fq.gz`, `*_val_2.fq.gz`, trim reports |
| Bowtie2 | `unmapped_1.fastq`, `unmapped_2.fastq` |
| MEGAHIT | `final.contigs.fa` |
| MetaWRAP | `metawrap_70_10_bins/bin.*.fa` (MAGs) |
| CheckM2 | `quality_report.tsv` |
| GTDB-Tk | `gtdbtk.bac120.summary.tsv` |
| DRAM | `annotations.tsv`, `metabolism_summary.html` |

---

## 📚 Key References

- **MEGAHIT:** Li et al. (2015) *Bioinformatics* — https://github.com/voutcn/megahit
- **MetaSPAdes:** Nurk et al. (2017) *Genome Research*
- **MetaWRAP:** Uritskiy et al. (2018) *Microbiome* — https://github.com/bxlab/metaWRAP
- **CheckM2:** Chklovski et al. (2023) *Nature Methods* — https://github.com/chklovski/CheckM2
- **GTDB-Tk:** Chaumeil et al. (2019) *Bioinformatics* — https://github.com/Ecogenomics/GTDBTk
- **DRAM:** Shaffer et al. (2020) *Nucleic Acids Research* — https://github.com/WrightonLabCSU/DRAM
- **MIMAG standards:** Bowers et al. (2017) *Nature Biotechnology* — https://doi.org/10.1038/nbt.3893
- **Zygnema genome:** *Nature Genetics* (2024) — https://doi.org/10.1038/s41588-024-01737-3

---

## 👥 Authors

**Course Project 2 — Department of Food Science and Technology, University of Nebraska-Lincoln**

- Dr. Xuehuan Feng (Postdoc)
- Xinpeng Zhang (PhD student)
- Numan Islam (PhD student)
- PI: Dr. Yanbin Yin

---

## 📄 License

This project is for educational use as part of a graduate bioinformatics course. Scripts are provided as-is for learning purposes.
