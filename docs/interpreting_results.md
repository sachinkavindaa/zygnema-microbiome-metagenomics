# Interpreting Results

A guide to understanding the outputs at each pipeline step.

---

## Part 1 — FastQC Reports

Download the `.html` files via HCC OnDemand and open them in your browser.

| Plot | What to look for | Pass / Warn / Fail |
|------|-----------------|-------------------|
| Per-base sequence quality | Phred scores stay above Q28 across the read | Quality drops at 3' end are normal |
| Per-sequence quality scores | Peak should be at Q30+ | Broad distribution = low-quality library |
| Sequence length distribution | Uniform peak at library length | Variable = degraded input DNA |
| Adapter content | Should be clean after trimming | Any signal before trimming = read-through |
| GC content | Should match expected genome GC% | Sharp peak = contamination |
| Per-base N content | Should be near zero | High N = sequencing problems |

**After trimming:** Re-run FastQC and confirm adapter content is gone and per-base quality has improved.

---

## Part 2 — Host Removal

Check that unmapped reads are a sensible proportion of total:
- If >95% of reads map to host → very little microbiome signal (low microbial load in sample)
- If <50% map to host → strong microbiome signal (good)

```bash
# Quick check: count reads before and after
echo "Raw reads:"
zcat project_raw_data/M2CH_S1_L002_R1_001.fastq.gz | awk 'NR%4==1' | wc -l

echo "Microbiome reads after host removal:"
grep -c '^@' part_2_remove_algae_genomes/unmapped_1.fastq
```

---

## Part 3 — Assembly Statistics (SeqKit output)

| Metric | Meaning | What's good |
|--------|---------|-------------|
| `num_seqs` | Total number of contigs | Fewer is generally better (higher contiguity) |
| `sum_len` | Total assembled bases | Should be ~× expected genome sizes × estimated species richness |
| `min_len` | Shortest contig | Typically 200 bp (MEGAHIT default min) |
| `avg_len` | Mean contig length | Higher = better assembly |
| `max_len` | Longest contig | A proxy for assembler performance |
| `N50` | Half the assembly is in contigs ≥ this size | Higher N50 = more contiguous |

---

## Part 4 — Binning Results

Find the bin_refinement stats in:
```
BIN_REFINEMENT_megahit/metawrap_70_10_bins/metawrap_70_10_bins.stats
```

| Column | Meaning |
|--------|---------|
| `bin` | MAG file name |
| `completeness` | Estimated % of genome recovered |
| `contamination` | % contamination from foreign contigs |
| `N50` | Contig N50 within the bin |
| `size` | Total bin size in bp |

---

## Part 5 — CheckM2 Quality Report

File: `checkm2_result/quality_report.tsv`

| Column | Meaning |
|--------|---------|
| `Name` | MAG name |
| `Completeness` | Predicted % completeness (ML model) |
| `Contamination` | Predicted % contamination |
| `Completeness_Model_Used` | Which CheckM2 model was applied |
| `Translation_Table_Used` | Genetic code for gene prediction |
| `Genome_Size` | Total bases in MAG |
| `GC_Content` | GC% (useful for taxonomic context) |

**In your report:** Make a table of all MAGs, flag high-quality ones (≥90% complete, ≤5% contamination) as per MIMAG standards.

---

## Part 6 — GTDB-Tk Taxonomy

File: `GTDB/gtdbtk.bac120.summary.tsv`

| Column | Meaning |
|--------|---------|
| `user_genome` | Your MAG file name |
| `classification` | Full GTDB lineage (d→p→c→o→f→g→s) |
| `fastani_reference` | Closest GTDB reference genome |
| `fastani_ani` | ANI to closest reference (>95% = same species) |
| `red_value` | Relative evolutionary divergence |

**Interpreting the lineage string:**
```
d__Bacteria;p__Pseudomonadota;c__Alphaproteobacteria;o__Rhizobiales;f__Rhizobiaceae;g__Rhizobium;s__
```
- `d__` = domain
- `p__` = phylum
- `c__` = class
- `o__` = order
- `f__` = family
- `g__` = genus
- `s__` = species (empty = novel species)

Note: Many GTDB names differ from NCBI — "Proteobacteria" → "Pseudomonadota" in GTDB.

---

## Part 7 — DRAM Results

### annotations.tsv
One row per predicted gene. Key columns:
- `fasta` — which MAG the gene came from
- `scaffold` — contig name
- `gene_position` — position on contig
- `ko_id` — KEGG Orthology number (e.g., K00001)
- `kegg_hit` — KEGG annotation
- `pfam_hits` — Pfam domain annotations
- `cazy_hits` — CAZyme family (carbohydrate-active enzymes)
- `peptidase_hits` — MEROPS peptidase family

### product.html (download to view)
Interactive heatmap where:
- **Rows** = metabolic modules / pathways
- **Columns** = MAGs
- **Color intensity** = proportion of pathway genes present (0 = absent, 1 = complete)

Key pathways to report:
- **Carbon fixation** (Calvin cycle, Wood-Ljungdahl, rTCA)
- **Nitrogen metabolism** (fixation, nitrification, denitrification, ammonification)
- **Sulfur metabolism** (oxidation, reduction, dissimilatory sulfate reduction)
- **Methane metabolism** (methanogenesis, methanotrophy)
- **Aerobic/anaerobic respiration** (terminal oxidases)

Combine this with GTDB taxonomy to tell a biological story: "The *Rhizobium*-like MAG shows complete nitrogen fixation modules, consistent with its known role as a plant growth-promoting bacterium..."
