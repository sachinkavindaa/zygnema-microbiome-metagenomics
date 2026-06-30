# Tools, Versions, and Citations

All tools are accessed via HCC Swan module system unless otherwise noted.

---

## Quality Control

| Tool | Version | HCC Module | Citation |
|------|---------|------------|----------|
| FastQC | latest | `ml fastqc` | Andrews S. (2010) FastQC: A quality control tool for high throughput sequence data. https://www.bioinformatics.babraham.ac.uk/projects/fastqc/ |
| Trim Galore | 0.6 | `ml trim_galore/0.6` | Krueger F. (2012) Trim Galore. https://github.com/FelixKrueger/TrimGalore |

---

## Host Read Removal

| Tool | Version | HCC Module | Citation |
|------|---------|------------|----------|
| Bowtie2 | 2.5 | `ml bowtie/2.5` | Langmead B & Salzberg SL (2012) Nature Methods 9:357–359 |
| Samtools | 1.9 | `ml samtools/1.9` | Li H et al. (2009) Bioinformatics 25:2078–2079 |

---

## Assembly

| Tool | Version | HCC Module | Citation |
|------|---------|------------|----------|
| MEGAHIT | 1.2 | `ml megahit/1.2` | Li D et al. (2015) Bioinformatics 31:1674–1676 |
| MetaSPAdes | 3.13 | `ml spades/py35/3.13` | Nurk S et al. (2017) Genome Research 27:824–834 |
| SeqKit | latest | `ml seqkit` | Shen W et al. (2016) PLOS ONE 11:e0163962 |

---

## Binning

| Tool | Version | HCC Module | Citation |
|------|---------|------------|----------|
| MetaWRAP | 1.3 | `ml metawrap/1.3` | Uritskiy GV et al. (2018) Microbiome 6:158 |
| MetaBAT2 | — | (bundled in MetaWRAP) | Kang DD et al. (2019) PeerJ 7:e7359 |
| MaxBin2 | — | (bundled in MetaWRAP) | Wu YW et al. (2016) Bioinformatics 32:605–607 |
| CONCOCT | — | (bundled in MetaWRAP) | Alneberg J et al. (2014) Nature Methods 11:1144–1146 |

---

## Quality Assessment

| Tool | Version | HCC Module | Citation |
|------|---------|------------|----------|
| CheckM2 | 1.0 | `ml checkm2/1.0` | Chklovski A et al. (2023) Nature Methods 20:1124–1132 |

---

## Taxonomy

| Tool | Version | HCC Module | Citation |
|------|---------|------------|----------|
| GTDB-Tk | 1.5 | `ml gtdbtk/1.5` | Chaumeil PA et al. (2019) Bioinformatics 36:1925–1927 |
| GTDB r207 | — | (database) | Parks DH et al. (2022) Nature Biotechnology 40:784–794 |

---

## Functional Annotation

| Tool | Version | HCC Module | Citation |
|------|---------|------------|----------|
| DRAM | 1.2 | `ml dram/1.2` | Shaffer M et al. (2020) Nucleic Acids Research 48:8883–8900 |

---

## Standards and Databases Referenced

- **MIMAG quality standards:** Bowers RM et al. (2017) Nature Biotechnology 35:725–731. https://doi.org/10.1038/nbt.3893
- **GTDB taxonomy:** https://gtdb.ecogenomics.org/
- **KEGG:** Kanehisa M & Goto S (2000) Nucleic Acids Research 28:27–30
- **dbCAN:** Zhang H et al. (2018) Nucleic Acids Research 46:W95–W101
- **Pfam:** Finn RD et al. (2016) Nucleic Acids Research 44:D279–D285
