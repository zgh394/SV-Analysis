#!/bin/bash
ref="Gallus_gallus.GRCg6a.dna.toplevel.fa"
bam_dir="./bam"
result_dir="./result"

mkdir -p bcf vcf geno
##dell call sv
#1. SV calling per sample
for id in $(cat bam.list); do
    delly call -g $ref $bam_dir/${id}.picardrmdum.bam > $result_dir/bcf/${id}.delly.bcf
done

#2. Merge SV sites into a unified site list
ls $result_dir/bcf/*.delly.bcf > $result_dir/bcf/bcf.list
delly merge -o $result_dir/bcf/sites.bcf $result_dir/bcf/bcf.list

#3. Genotype merged SV sites across all samples
for id in $(cat bam.list); do
    delly call -g $ref -v $result_dir/bcf/sites.bcf -o $result_dir/geno/${id}.geno.bcf $bam_dir/${id}.picardrmdum.bam
    bcftools view -Ov $result_dir/geno/${id}.geno.bcf > $result_dir/vcf/${id}.delly.vcf
done

#4. Merge all genotyped samples into a single VCF/BCF
ls $result_dir/geno/*.geno.bcf > $result_dir/geno/geno.list
bcftools merge -m id -O b -o $result_dir/geno/merged.bcf --file-list $result_dir/geno/geno.list

#5. Apply germline SV filter
bcftools index $result_dir/geno/merged.bcf
delly filter -f germline -o $result_dir/germline.bcf $result_dir/geno/merged.bcf
bcftools view $result_dir/germline.bcf -Oz -o $result_dir/germline.vcf.gz

#6. filtering SVTYPE
bcftools view -i '(SVTYPE = "DEL" | SVTYPE = "DUP" | SVTYPE = "INV" | SVTYPE = "INS")' germline.vcf.gz -Oz -o germline.filter.vcf.gz && tabix germline.filter.vcf.gz

echo "All Delly SV calling & filtering done!"
