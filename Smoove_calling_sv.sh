#!/bin/bash
ref="Gallus_gallus.GRCg6a.dna.toplevel.fa"
bam_dir="./bam"
result_dir="./result"
gff="Gallus_gallus.GRCg6a.106.gff3"

mkdir -p ${result_dir}/call ${result_dir}/merge ${result_dir}/genotype ${result_dir}/paste ${result_dir}/annotate

## Smoove SV calling & annotation pipeline
#1. SV calling per sample
for sample in $(cat sample.list); do
    smoove call --outdir ${result_dir}/call --name ${sample} --fasta ${ref} -p 1 --genotype ${bam_dir}/${sample}.sort.dd.bam
done

#2. Merge SV sites into a unified site list
smoove merge --name merged -f ${ref} --outdir ${result_dir}/merge ${result_dir}/call/*.genotyped.vcf.gz

#3. Genotype merged SV sites across all samples
for sample in $(cat sample.list); do
    smoove genotype -d -x -p 1 --name ${sample}-joint --outdir ${result_dir}/genotype --fasta ${ref} --vcf ${result_dir}/merge/merged.sites.vcf.gz ${bam_dir}/${sample}.sort.dd.bam
done

#4. Merge all genotyped samples into a single VCF
cd ${result_dir}/paste
smoove paste --name RIR ${result_dir}/genotype/*.vcf.gz
cd - > /dev/null

#5. Annotate SVs and compress
smoove annotate --gff ${gff} ${result_dir}/paste/RIR.smoove.square.vcf.gz | bgzip -c > ${result_dir}/annotate/combs.smoove.square.anno.vcf.gz

echo "All Smoove SV calling & annotation done!"
