#!/usr/bin/env bash
set -euo pipefail
CFG="${1:-config.yaml}"

cfgget () {
  awk -F': *' -v k="$1" '$1==k{print $2}' "$CFG" \
  | sed 's/[[:space:]]*#.*$//' \
  | tr -d '"' | tr -d "'" \
  | xargs
}

N=$(cfgget rnacode_nsamples)
PCUT=$(cfgget rnacode_p_cutoff)
MINNT=$(cfgget min_window_nt)

mkdir -p results
RNAcode -n "$N" --tabular --outfile work/rnacode.tab work/fam.codon.aln.clu
awk 'BEGIN{FS=OFS="\t"} NR==1{print; next} {len=$4-$3+1; if(len>='"$MINNT"' && $9<='"$PCUT"') print}' \
  work/rnacode.tab > results/rnacode.filt.tab
echo "Kept windows:" $(($(wc -l < results/rnacode.filt.tab)-1))
