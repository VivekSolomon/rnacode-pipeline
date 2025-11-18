#!/usr/bin/env bash
set -euo pipefail
QAA="$1"                 # query protein FASTA (single small protein)
CFG="${2:-config.yaml}"

bash bin/aa_homologs.sh "$QAA" "$CFG"
bash bin/fetch_cds.sh   work/fam.aa.with_query.fa
bash bin/codon_msa.sh   work/fam.aa.with_query.fa work/fam.cds.fa
bash bin/rnacode_step.sh "$CFG"
