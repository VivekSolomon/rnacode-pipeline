#!/usr/bin/env bash
set -euo pipefail
QAA="$1"          # query protein FASTA (single sequence)
CFG="${2:-config.yaml}"

# minimal YAML getter for simple "key: value" lines
cfgget () {
  awk -F': *' -v k="$1" '$1==k{print $2}' "$CFG" \
  | sed 's/[[:space:]]*#.*$//' \
  | tr -d '"' | tr -d "'" \
  | xargs
}

taxon=$(cfgget taxon_query)
db=$(cfgget blast_db)
ws=$(cfgget word_size)
e=$(cfgget evalue)
mts=$(cfgget max_target_seqs)
cov=$(cfgget coverage_min)
lrmin=$(cfgget length_ratio_min)
lrmax=$(cfgget length_ratio_max)

mkdir -p work results
QLAA=$(seqkit fx2tab -l "$QAA" | awk '{print $2}')
blastp -query "$QAA" -db "$db" -remote \
  -entrez_query "$taxon" -word_size "$ws" -evalue "$e" -max_hsps 1 \
  -seg yes -comp_based_stats 1 -max_target_seqs "$mts" \
  -outfmt '6 sacc stitle pident length qcovs evalue sseq' \
  > work/aa_hits.tsv

awk -F'\t' -v Q=$QLAA -v C=$cov -v A=$lrmin -v B=$lrmax \
  '($5>=C) && ($2>=A*Q) && ($2<=B*Q)' \
  work/aa_hits.tsv > work/aa_hits.keep.tsv

awk -F'\t' '{printf(">%s\n%s\n",$1,$7)}' work/aa_hits.keep.tsv \
  | seqkit rmdup -s > work/fam.aa.fa

# include the query itself as a member too
cat "$QAA" work/fam.aa.fa | seqkit rmdup -n > work/fam.aa.with_query.fa
