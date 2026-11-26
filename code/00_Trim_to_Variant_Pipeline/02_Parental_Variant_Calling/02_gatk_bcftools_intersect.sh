#!/bin/bash
#SBATCH --job-name=gatk_bcftools_intersect
#SBATCH -p sonmi
#SBATCH -n 56
#SBATCH --output=%j.out
#SBATCH --error=%j.err
#SBATCH --nodelist=compute-0-0
#SBATCH --time=24:00:00

ulimit -s unlimited
ulimit -l unlimited
cd $SLURM_SUBMIT_DIR

BCFTOOLS="/share/home/software/bcftools"

GATK_VCF="gatk_result/22971_PASS.vcf"
BCF_VCF="bcftools_result/22971_filtered.vcf"
OUT_DIR="intersect_results"

[ ! -f "$GATK_VCF" ] && echo "Error: GATK VCF not found" && exit 1
[ ! -f "$BCF_VCF" ] && echo "Error: bcftools VCF not found" && exit 1

mkdir -p ${OUT_DIR}/isec_output ${OUT_DIR}/by_type

# Extract variant positions (chrom:pos), ignoring ref/alt
$BCFTOOLS query -f '%CHROM:%POS\n' ${GATK_VCF} | sort -u > ${OUT_DIR}/gatk_positions.txt
GATK_COUNT=$(wc -l < ${OUT_DIR}/gatk_positions.txt)
echo "GATK unique positions: ${GATK_COUNT}"

$BCFTOOLS query -f '%CHROM:%POS\n' ${BCF_VCF} | sort -u > ${OUT_DIR}/bcf_positions.txt
BCF_COUNT=$(wc -l < ${OUT_DIR}/bcf_positions.txt)
echo "bcftools unique positions: ${BCF_COUNT}"

# Intersection and differences
comm -12 ${OUT_DIR}/gatk_positions.txt ${OUT_DIR}/bcf_positions.txt > ${OUT_DIR}/intersection_positions.txt
INTER_COUNT=$(wc -l < ${OUT_DIR}/intersection_positions.txt)
comm -23 ${OUT_DIR}/gatk_positions.txt ${OUT_DIR}/bcf_positions.txt > ${OUT_DIR}/gatk_specific_positions.txt
GATK_SPEC=$(wc -l < ${OUT_DIR}/gatk_specific_positions.txt)
comm -13 ${OUT_DIR}/gatk_positions.txt ${OUT_DIR}/bcf_positions.txt > ${OUT_DIR}/bcf_specific_positions.txt
BCF_SPEC=$(wc -l < ${OUT_DIR}/bcf_specific_positions.txt)
echo "Intersection: ${INTER_COUNT}; GATK specific: ${GATK_SPEC}; bcftools specific: ${BCF_SPEC}"

# Convert positions to bcftools -R format
awk -F':' '{print $1"\t"$2}' ${OUT_DIR}/intersection_positions.txt > ${OUT_DIR}/intersection.extract
awk -F':' '{print $1"\t"$2}' ${OUT_DIR}/gatk_specific_positions.txt > ${OUT_DIR}/gatk_specific.extract
awk -F':' '{print $1"\t"$2}' ${OUT_DIR}/bcf_specific_positions.txt > ${OUT_DIR}/bcf_specific.extract

# Compress and index input VCFs
bgzip -f ${GATK_VCF}
tabix -p vcf ${GATK_VCF}.gz
bgzip -f ${BCF_VCF}
tabix -p vcf ${BCF_VCF}.gz

# Extract full records for each set
$BCFTOOLS view -R ${OUT_DIR}/intersection.extract ${GATK_VCF}.gz > ${OUT_DIR}/isec_output/intersection.vcf
$BCFTOOLS view -R ${OUT_DIR}/gatk_specific.extract ${GATK_VCF}.gz > ${OUT_DIR}/isec_output/gatk_specific.vcf
$BCFTOOLS view -R ${OUT_DIR}/bcf_specific.extract ${BCF_VCF}.gz > ${OUT_DIR}/isec_output/bcftools_specific.vcf

# Classify by variant type (SNP/Indel)
classify_variants() {
    local input=$1
    local prefix=$2
    local outdir=$3
    [ ! -f "$input" ] && return
    $BCFTOOLS view -v snps -O v -o ${outdir}/${prefix}_snp.vcf $input 2>/dev/null
    $BCFTOOLS view -v indels -O v -o ${outdir}/${prefix}_indel.vcf $input 2>/dev/null
}
classify_variants ${OUT_DIR}/isec_output/intersection.vcf "intersection" ${OUT_DIR}/by_type
classify_variants ${OUT_DIR}/isec_output/gatk_specific.vcf "gatk_specific" ${OUT_DIR}/by_type
classify_variants ${OUT_DIR}/isec_output/bcftools_specific.vcf "bcftools_specific" ${OUT_DIR}/by_type

# Statistics summary
STATS="${OUT_DIR}/statistics_summary.txt"
{
    echo "VCF Position Intersection Statistics"
    echo "Analysis date: $(date)"
    echo "GATK total positions: ${GATK_COUNT}"
    echo "bcftools total positions: ${BCF_COUNT}"
    echo "Intersection: ${INTER_COUNT}"
    echo "GATK specific: ${GATK_SPEC}"
    echo "bcftools specific: ${BCF_SPEC}"
    echo "SNP/Indel counts:"
    for vcf in ${OUT_DIR}/by_type/*.vcf; do
        [ -f "$vcf" ] && echo "$(basename $vcf .vcf): $($BCFTOOLS view -H $vcf 2>/dev/null | wc -l)"
    done
} > $STATS

# Compress final outputs
bgzip -c ${OUT_DIR}/isec_output/intersection.vcf > ${OUT_DIR}/intersection.vcf.gz 2>/dev/null
tabix -p vcf ${OUT_DIR}/intersection.vcf.gz 2>/dev/null
bgzip -c ${OUT_DIR}/isec_output/gatk_specific.vcf > ${OUT_DIR}/gatk_specific.vcf.gz 2>/dev/null
tabix -p vcf ${OUT_DIR}/gatk_specific.vcf.gz 2>/dev/null
bgzip -c ${OUT_DIR}/isec_output/bcftools_specific.vcf > ${OUT_DIR}/bcftools_specific.vcf.gz 2>/dev/null
tabix -p vcf ${OUT_DIR}/bcftools_specific.vcf.gz 2>/dev/null

cat ${STATS}
exit 0