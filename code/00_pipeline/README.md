# Command-line steps that produced the inputs in `data/`

Run on the institute SLURM cluster; the absolute paths (`/share/home/hty`, `/biodata/hty`) must be
edited before re-use.

| Script | Step |
|---|---|
| `calc_depth_coverage_26-10-11.sh` | per-BAM mapping statistics and breadth of coverage at ≥1×, ≥3×, ≥10× and ≥30× (`samtools depth` + flagstat) → `data/01_Het_Fws/het-cov.txt` |
| `parse_kraken_reports_100pct.py` | Kraken2 reports → mutually exclusive 100% composition (Unclassified, Eukaryota, Bacteria, Archaea, Viruses, other) |
| `01_filter_SO_hap_260708.sh`, `01_filter_SO_dip_260708.sh` | split the merged call set per sample (`bcftools view -S`) and extract the 1,065-SNP and 1,391-marker subsets (`bcftools view -R`) |
| `02_het_calculation.sh` | PLINK `--het` / `--hardy` for both marker sets |

Python scripts use the standard library only.
