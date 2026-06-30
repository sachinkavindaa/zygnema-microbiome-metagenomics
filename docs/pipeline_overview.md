# Pipeline Overview

This document explains the biological rationale and technical decisions behind each step.

---

## Part 0 — Raw Data

**Input:** Paired-end Illumina metagenomic sequencing of *Zygnema circumcarinatum* MZCH241 cultures.

The sample contains a mixture of DNA from:
- The host alga (*Zygnema circumcarinatum*)
- Associated bacteria, archaea, fungi, and other microorganisms

Two FASTQ files represent forward (R1) and reverse (R2) reads from paired-end sequencing. Each read is ~150 bp.

---

## Part 1 — Quality Control and Trimming

**Why:** Illumina sequencing produces reads with declining quality toward the 3' end. Adapter sequences ligated during library preparation can also appear in reads when insert fragments are shorter than the read length.

**FastQC** generates reports on:
- Per-base quality scores (Phred scale: Q20 = 99% accuracy, Q30 = 99.9%)
- Adapter contamination
- GC content (deviation from expected ~50% may indicate contamination)
- Overrepresented sequences

**Trim Galore** wraps Cutadapt to:
- Auto-detect and remove adapter sequences
- Trim low-quality 3' ends (default Q < 20)
- Remove reads below minimum length (default 20 bp)

---

## Part 2 — Host Read Removal

**Why:** We want only microbiome reads. The sequencing library contains a large proportion of algal DNA (host). These must be removed before assembly to avoid:
- Poor assembly quality (algal and microbial reads confuse assemblers)
- Wasted compute time assembling host genome contigs

**Strategy:** Map all reads to the algal reference genome (nuclear + plastid + mitogenome). Retain only read pairs where **both** mates fail to map.

**Samtools flags explained:**
```
-f 12    # bit 4 (read unmapped) AND bit 8 (mate unmapped) — both unmapped
-F 256   # exclude secondary alignments (keep primary only)
```

---

## Part 3 — Metagenome Assembly

**Why:** Short reads (150 bp) must be assembled into longer contigs for meaningful gene analysis. Assemblers use de Bruijn graphs: reads are broken into k-mers, a graph is built from k-mer overlaps, and paths through the graph become contigs.

**MEGAHIT** (recommended):
- Uses a range of k-mer sizes (small to large) iteratively
- Very memory-efficient
- ~40 minutes for typical metagenome

**MetaSPAdes** (alternative):
- Generally produces longer, more contiguous assemblies
- Requires substantially more memory and time (~8 hrs)
- Both use De Bruijn graph algorithms

**Comparing outputs with SeqKit:**
- `num_seqs` — number of contigs
- `sum_len` — total assembled bases
- `N50` — contig length where 50% of assembly is in contigs of this size or longer (higher = better contiguity)

---

## Part 4 — Binning

**Why:** The assembled contigs come from dozens of different microbial genomes, all mixed together. Binning groups contigs that likely came from the same organism based on:
- **Tetranucleotide frequency** — each genome has a characteristic k-mer composition
- **Coverage depth** — contigs from the same organism are covered at similar depth

**MetaWRAP** runs three independent binners and then performs bin refinement:

| Binner | Algorithm |
|--------|-----------|
| MetaBAT2 | Tetranucleotide freq + coverage depth |
| MaxBin2 | EM algorithm on coverage + composition |
| CONCOCT | Coverage variation + k-mer profiles |

**Bin refinement** tests all combinations (A, B, C, AB, AC, BC, ABC) and selects the set that maximizes completeness while minimizing contamination.

**Output threshold:** ≥70% completeness, ≤10% contamination (`metawrap_70_10_bins/`)

---

## Part 5 — MAG Quality Assessment

**CheckM2** uses machine learning (gradient boosting) trained on thousands of reference genomes to predict completeness and contamination. Unlike CheckM1 (which relies on universal single-copy marker genes), CheckM2 works well for divergent lineages.

**MIMAG quality standards (Bowers et al. 2017):**

| Category | Completeness | Contamination |
|----------|-------------|---------------|
| High quality | ≥90% | ≤5% |
| Medium quality | ≥50% | ≤10% |
| Low quality | <50% | >10% |

---

## Part 6 — Taxonomic Annotation

**GTDB-Tk** classifies MAGs using:
1. Marker gene identification (120 bacterial / 53 archaeal universal markers)
2. Phylogenomic tree placement (where does this MAG fall in the tree of life?)
3. ANI comparison to GTDB reference genomes

**GTDB vs NCBI taxonomy:** GTDB uses normalized rank definitions — some familiar NCBI names are reorganized. For example, "Proteobacteria" is split into separate phyla in GTDB.

Key output column in summary TSV: `classification` gives the full lineage in format:
```
d__Bacteria;p__Proteobacteria;c__Gammaproteobacteria;o__...;f__...;g__...;s__
```

---

## Part 7 — Functional Annotation

**DRAM workflow:**
1. **Prodigal** predicts protein-coding genes from each MAG
2. Predicted proteins are searched against 7 databases
3. **Distillation** aggregates hits into metabolic pathway presence/absence

**Key metabolic modules to look for:**
- Carbon fixation pathways
- Nitrogen cycling (fixation, nitrification, denitrification)
- Sulfur metabolism
- Cold stress response pathways
- Vitamin biosynthesis
- Secondary metabolite production

The `product.html` heatmap shows rows = pathways, columns = MAGs, color = pathway completeness. Interpret in the context of GTDB taxonomy — a known nitrogen fixer should show complete nitrogen fixation modules.
