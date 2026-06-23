# HCC Module Load Commands

Quick reference for loading the correct software at each pipeline step.
Always `module unload` the current tool before loading a new one to avoid conflicts.

---

## Step-by-step Module Reference

| Script | Load | Unload Before Next Step |
|--------|------|-------------------------|
| 01_fastqc_pre.sh | `module load fastqc` | `module unload fastqc` |
| 02_trim_galore.sh | `module load trim_galore/0.6` | `module unload trim_galore` |
| 03_fastqc_post.sh | `module load fastqc` | `module unload fastqc` |
| 04_bowtie2_host_removal.sh | `module load bowtie/2.5 samtools/1.9` | `module unload bowtie samtools` |
| 05_megahit_assembly.sh | `module load megahit/1.2` | `module unload megahit` |
| 06_metaspades_assembly.sh | `module load spades/py35/3.13` | `module unload spades` |
| 07_metawrap_binning.sh | `module load metawrap/1.3` | `module unload metawrap` |
| 08_checkm2.sh | `module load checkm2/1.0` | `module unload checkm2` |
| 09_gtdbtk.sh | `module load gtdbtk/1.5` | `module unload gtdbtk` |
| 10_dram.sh | `module load dram/1.2` | `module unload dram` |

---

## Useful HCC Commands

```bash
# Search available software
module avail <toolname>
module spider <toolname>

# List currently loaded modules
module list

# Unload all loaded modules at once
module purge

# Check job status
squeue -u $USER

# View job output live
tail -f jobname.JOBID.out

# Submit a SLURM script
sbatch scripts/05_megahit_assembly.sh

# Cancel a job
scancel <JOBID>

# View detailed job info
scontrol show job <JOBID>

# Check storage quota
hcc-usage
```

---

## Partitions Available on Swan

| Partition | Notes |
|-----------|-------|
| `batch` | General compute |
| `guest` | Shared/overflow |
| `yinlab` | Lab-specific (if applicable) |

Use `--partition=batch,guest` to allow jobs to use either.

---

## Tips

- Never run MEGAHIT, MetaSPAdes, MetaWRAP, CheckM2, GTDB-Tk, or DRAM on the **login node**
- FastQC and `seqkit stats` are fast and can run on the login node
- Add your lab partition (e.g. `yinlab`) to SLURM scripts if available — reduces queue time
- Check HCC OnDemand at https://ondemand.hcc.unl.edu/ to download result files to your laptop
- Software list: https://hcc.unl.edu/docs/applications/modules/available_software_for_swan/
