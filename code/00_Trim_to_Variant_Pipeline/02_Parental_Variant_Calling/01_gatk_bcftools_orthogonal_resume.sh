#!/bin/bash
#SBATCH --job-name=orthogonal_resume
#SBATCH -p sonmi
#SBATCH -n 56
#SBATCH --output=%j.out
#SBATCH --error=%j.err
#SBATCH --nodelist=compute-0-0

ulimit -s unlimited
ulimit -l unlimited
cd $SLURM_SUBMIT_DIR

REFERENCE="./ref/11730.fasta"
GATK_OUTDIR="./gatk_result"
BCFTOOLS_OUTDIR="./bcftools_result"
THREADS=56
SAMPLE="22971"
BAM_FILE="./${SAMPLE}_markdup_rg.bam"

mkdir -p ${GATK_OUTDIR} ${BCFTOOLS_OUTDIR}

echo "Resume-mode: only runs missing steps. Sample: ${SAMPLE}"

# GATK: HaplotypeCaller
if [ -f "${GATK_OUTDIR}/${SAMPLE}_raw.vcf" ] && [ -s "${GATK_OUTDIR}/${SAMPLE}_raw.vcf" ]; then
    echo "[SKIP] GATK HaplotypeCaller"
else
    echo "[RUN] GATK HaplotypeCaller"
    gatk HaplotypeCaller -R ${REFERENCE} -I ${BAM_FILE} -O ${GATK_OUTDIR}/${SAMPLE}_raw.vcf -ploidy 1 -stand-call-conf 30
    [ $? -ne 0 ] && echo "ERROR: GATK HaplotypeCaller failed" && exit 1
fi

# GATK: VariantFiltration
if [ -f "${GATK_OUTDIR}/${SAMPLE}_filtered.vcf" ] && [ -s "${GATK_OUTDIR}/${SAMPLE}_filtered.vcf" ]; then
    echo "[SKIP] GATK VariantFiltration"
else
    echo "[RUN] GATK VariantFiltration"
    gatk VariantFiltration -R ${REFERENCE} -V ${GATK_OUTDIR}/${SAMPLE}_raw.vcf -O ${GATK_OUTDIR}/${SAMPLE}_filtered.vcf \
        -filter "QUAL < 30.0" --filter-name "LowQual" \
        -filter "DP < 10" --filter-name "LowDP" \
        -filter "QD < 2.0" --filter-name "LowQD" \
        -filter "MQ < 40.0" --filter-name "LowMQ" \
        -filter "FS > 60.0" --filter-name "HighFS"
    [ $? -ne 0 ] && echo "ERROR: GATK VariantFiltration failed" && exit 1
fi

# GATK: keep PASS only
if [ -f "${GATK_OUTDIR}/${SAMPLE}_PASS.vcf" ] && [ -s "${GATK_OUTDIR}/${SAMPLE}_PASS.vcf" ]; then
    echo "[SKIP] GATK SelectVariants PASS"
else
    echo "[RUN] GATK SelectVariants PASS"
    gatk SelectVariants -R ${REFERENCE} -V ${GATK_OUTDIR}/${SAMPLE}_filtered.vcf --exclude-filtered -O ${GATK_OUTDIR}/${SAMPLE}_PASS.vcf
    [ $? -ne 0 ] && echo "ERROR: GATK SelectVariants failed" && exit 1
fi

# bcftools: mpileup + call
if [ -f "${BCFTOOLS_OUTDIR}/${SAMPLE}_raw.vcf.gz" ] && [ -s "${BCFTOOLS_OUTDIR}/${SAMPLE}_raw.vcf.gz" ]; then
    echo "[SKIP] bcftools mpileup+call"
else
    echo "[RUN] bcftools mpileup+call"
    bcftools mpileup -Ou \
        -a FORMAT/AD,FORMAT/DP -f ${REFERENCE} \
        ${BAM_FILE} -d 500 --threads ${THREADS} | bcftools call --ploidy 1 -mv -O z \
        -o ${BCFTOOLS_OUTDIR}/${SAMPLE}_raw.vcf.gz --threads ${THREADS}
    [ $? -ne 0 ] && echo "ERROR: bcftools call failed" && exit 1
fi

# bcftools: filter (QUAL>=30, FORMAT/DP>=10, INFO/MQ>=40)
if [ -f "${BCFTOOLS_OUTDIR}/${SAMPLE}_filtered.vcf" ] && [ -s "${BCFTOOLS_OUTDIR}/${SAMPLE}_filtered.vcf" ]; then
    echo "[SKIP] bcftools filter"
else
    echo "[RUN] bcftools filter"
    bcftools filter -i "QUAL>=30 && FORMAT/DP>=10 && INFO/MQ>=40" \
        ${BCFTOOLS_OUTDIR}/${SAMPLE}_raw.vcf.gz -Ov -o ${BCFTOOLS_OUTDIR}/${SAMPLE}_filtered.vcf
    [ $? -ne 0 ] && echo "ERROR: bcftools filter failed" && exit 1
fi

exit 0