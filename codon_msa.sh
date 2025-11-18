#!/usr/bin/env bash
set -euo pipefail
AAFAM="$1"   # work/fam.aa.with_query.fa
CDS="$2"     # work/fam.cds.fa

mkdir -p work
# remove internal-stop offenders
seqkit translate -f 1 "$CDS" | grep -B1 '\*' | grep '^>' | sed 's/^>//' > work/has_stops.txt || true
if [ -s work/has_stops.txt ]; then
  seqkit grep -v -n -f work/has_stops.txt "$CDS" > work/fam.cds.clean.fa
  seqkit grep -v -n -f work/has_stops.txt "$AAFAM" > work/fam.aa.clean.fa
else
  cp "$CDS" work/fam.cds.clean.fa
  cp "$AAFAM" work/fam.aa.clean.fa
fi

# protein MSA
mafft --maxiterate 1000 --globalpair work/fam.aa.clean.fa > work/fam.aa.aln.faa

# back-translate to codon alignment (CLUSTAL for RNAcode 0.3.1)
pal2nal.pl work/fam.aa.aln.faa work/fam.cds.clean.fa -output clustal > work/fam.codon.aln.clu
