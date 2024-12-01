#!/bin/bash
apt -y install tpm2-tools yq &> /dev/null
r=()
for i in {0..23}; do r+=(0000000000000000000000000000000000000000000000000000000000000000); done
q='.. | select(.PCRIndex? and .Digests[0].Digest?) | [.PCRIndex,.Digests[0].Digest] | @tsv'
while read i h; do
  n=$(<<< "${r[i]}$h" xxd -r -p | sha256sum | cut -d ' ' -f 1)
  printf '%-2s sha256( %s || %s ) = %s\n' "$i" "${r[i]}" "$h" "$n"
  r[i]="$n"
done < <(tpm2_eventlog /sys/kernel/security/tpm0/binary_bios_measurements 2>/dev/null | yq -r "$q")
i=0
while read h; do
  if test "${r[i]}" = "${h,,}"; then
    printf '%-2s OK %s\n' "$i" "${r[i]}"
  else
    printf '%-2s NE %s != calculated %s\n' "$i" "${h,,}" "${r[i]}"
  fi
  ((i++))
done < <(tpm2_pcrread | grep -A24 sha256 | tail -n+2 | cut -dx -f2)
