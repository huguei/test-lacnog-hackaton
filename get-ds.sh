#!/bin/bash
GRP=$1

echo 'trust-anchors {' > ds.keys; dig @100.100.$GRP.130 grp$GRP.lacnic41-dns.te-labs.training dnskey +norec +dnssec +nosplit | grep -P 'DNSKEY\s*257' | awk '{printf "\t%s static-key %s %s %s \"%s\";\n", $1, $5, $6, $7, $8}' >> ds.keys; echo '};' >> ds.keys
delv -a ds.keys +root=grp$GRP.lacnic41-dns.te-labs.training @100.100.$GRP.130 grp$GRP.lacnic41-dns.te-labs.training soa
