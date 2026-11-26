#BiocManager::install("bahlolab/moimix", build_vignettes = TRUE)
library(SeqArray)
#To convert a tabixed gzipped VCF file to the GDS format use the SeqArray package.
seqVCF2GDS("/data/01_Het_Fws/fws/F1SOSS_hap_overlap_1391.vcf",
           "/data/01_Het_Fws/fws/F1SOSS_hap_overlap_1391.gds")

#To read the GDS file into R, use the seqOpen function and to check that its output matches the orginal VCF file use seqSummary.
my_vcf <-seqOpen("/data/01_Het_Fws/fws/F1SOSS_hap_overlap_1391.gds")
seqSummary(my_vcf)

# save sample identifiers
sample.id <- seqGetData(my_vcf, "sample.id")
library(moimix)
# get genomic coordinates of all variants
coords <- getCoordinates(my_vcf)
head(coords)

#Estimating the BAF matrix
isolate_baf <- bafMatrix(my_vcf)
class(isolate_baf)
str(isolate_baf)

#Estimating MOI with Fws
fws_all <- getFws(my_vcf)

aa <- as.data.frame(fws_all[])
write.table(aa,file = "/results/01_Het_Fws/fws/Fws_SOSS_hap_overlap_1391.txt")
