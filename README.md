# *Cryptosporidium parvum* IId-HLJ × IId-GD genetic cross — analysis code

Code, input tables and container environment for the bioinformatic analyses of the revised
manuscript. The scripts take the variant calls and summary tables in `data/` and regenerate every
genomic figure and statistic in the paper.

## Folders

* `code/` — analysis scripts, run in order by `code/run.sh`
* `data/` — variant calls, summary tables and AlphaFold output used as input
* `environment/` — `Dockerfile` and `postInstall` exported from Code Ocean (R 4.5.1, pinned packages)

## Run

```bash
docker build -t cpar-revision environment/
mkdir -p results
docker run --rm -v "$PWD/data":/data -v "$PWD/code":/code -v "$PWD/results":/results \
  cpar-revision bash /code/run.sh
```

Outputs are written to `results/<module>/`. Without Docker, install R 4.5.1 and the packages listed
in `environment/Dockerfile`, replace the `/data` and `/results` prefixes at the top of the scripts,
and run `bash code/run.sh`.

## What each script does

* `code/00_Trim_Mapping_SNP` — read trimming, mapping, depth and bcftools calls (cluster scripts)
* `code/00_pipeline` — coverage and mapping statistics, Kraken2 composition, marker selection, Heterozygosity
* `code/01_Het_Fws` — heterozygosity, Fws, heterogeneity versus coverage, heterogeneity over time
* `code/02_PCA` — PCA, scree plots, PC–covariate correlations
* `code/03_Variant_distribution` — SNP and InDel density across the eight chromosomes
* `code/04_Allele_Frequency` — VAF profiles, crossover calls, haplotype stability over time
* `code/05_Genetic_Map` — recombination map, crossover counts, crossover–heterozygosity correlation
* `code/06_Fst_Pi` — windowed F<sub>ST</sub> and Pi between high- and low-virulence lines
* `code/07_Line3_8_11_24_Allele_Frequency` — allele-frequency contrast of lines 3, 8, 11 versus 24
* `code/08_XP-EHH` — XP-EHH and Manhattan plots
* `code/09_Upset_Plot` — intersection of the four candidate-gene sets
* `code/10_Drift_Concordance` — direction concordance of allele-frequency change across lines
* `code/11_AlphaFold` — pLDDT profile and PAE matrix of the CpDHR1 models

