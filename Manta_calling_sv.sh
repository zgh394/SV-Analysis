#!/bin/bash

ref="Gallus_gallus.GRCg6a.dna.toplevel.fa"
bam_dir="./bam"
result_dir="./result"

#sv calling
cat $bam_dir/bam.list | while read id
   do
## step 1. configconfig
configManta.py --bam ./bam/${id}.picardrmdum.bam --referenceFasta $ref --runDir $result_dir/raw/$id 

 ## step 2. Call SVs
$result_dir/raw/$id/runWorkflow.py

done

echo "All Manta SV calling & filtering done!"
