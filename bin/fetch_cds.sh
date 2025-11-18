#!/usr/bin/env bash
set -euo pipefail

# Needs: work/aa_hits.keep.tsv (col1 = subject protein accession)
[ -s work/aa_hits.keep.tsv ] || { echo "ERROR: work/aa_hits.keep.tsv missing"; exit 1; }
awk -F'\t' '{print $1}' work/aa_hits.keep.tsv | sort -u > work/prot_ids.txt

# Fetch all linked CDS
> work/fam.cds.raw.fa
while read -r PID; do
  elink -db protein -id "$PID" -target nuccore \
   | efetch -format fasta_cds_na >> work/fam.cds.raw.fa || true
done < work/prot_ids.txt

# Rewrite CDS headers to >protein_id (PAL2NAL-friendly), keep only IDs we hit by BLAST
awk '
  /^>/ {
    if (match($0, /protein_id=([^]]+)/, m)) { print ">" m[1] } else { next }
  }
  /^[^>]/ { print }
' work/fam.cds.raw.fa > work/fam.cds.by_protid.fa

seqkit grep -n -f work/prot_ids.txt work/fam.cds.by_protid.fa \
  | seqkit seq -u > work/fam.cds.fa
