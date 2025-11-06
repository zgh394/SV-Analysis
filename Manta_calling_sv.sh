#!/bin/bash

ref="Gallus_gallus.GRCg6a.dna.toplevel.fa"
bam_dir="./bam"
result_dir="./result"
merge="./svimmer/bam/chr.list"
## 1. configconfig
cat $bam_dir/bam.list | while read id
   do

configManta.py --bam ./bam/${id}.picardrmdum.bam --referenceFasta $ref --runDir $result_dir/raw/$id 

 ## 2. Call SVs
$result_dir/raw/$id/runWorkflow.py

done

#preparing vcf_file & bam_file
ls $resut_dir/raw/*/results/variants/diploidSV.vcf.gz > vcf_file
ls $bam_dir/*.picardrmdum.bam > bam_file

#merge
svimmer vcf_file 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 30 31 32 33 | bgzip -c > merge.manta.bam.vcf.gz

#indexing
tabix -p vcf merge.manta.bam.vcf.gz

#genotype
for chr in $(cat $merge); do
graphtyper genotype_sv $ref merge.manta.bam.vcf.gz --sams=bam_file ${chr} --threads=8 --output=manta_sv
done

#Concatenate output VCF files
echo 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 25 26 27 28 30 31 32 33 | tr ' ' '\n' | while read chrom; do if [[ ! -d manta_sv/${chrom} ]]; then continue; fi; find manta_sv/${chrom} -name "*.vcf.gz" | sort; done > vcf_file_list
bcftools concat --naive --file-list vcf_file_list -Oz -o large.manta.bam.vcf.gz
tabix -p vcf large.manta.bam.vcf.gz

#filting files
bcftools view --include 'SVMODEL="AGGREGATED"' -Oz -o gt.agg_only.manta.bam.vcf.gz large.manta.bam.vcf.gz
tabix -p vcf gt.agg_only.manta.bam.vcf.gz
bcftools view -i '((SVTYPE = "DEL"  | SVTYPE = "DUP"  | SVTYPE = "INV" | SVTYPE = "INS")) & (
    (SVLEN >=50 & SVLEN <=2000000 | SVLEN <=-50 & SVLEN >=-2000000))' \
    gt.agg_only.manta.bam.vcf.gz -Oz -o filter.gt.agg_only.manta.bam.vcf.gz && \
    tabix -f filter.gt.agg_only.manta.bam.vcf.gz

echo "All Manta SV calling & filtering done!"
