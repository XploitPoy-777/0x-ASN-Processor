#!/bin/bash

# Script for extracting CIDR ranges, resolving IPs, and performing reverse DNS lookups for a given ASN.
# Usage: ./0x-asn-toolkit.sh <ASN>

# Check if an ASN argument is provided
if [ -z "$1" ]; then
  echo -e "\033[1;34mUsage: $0 <ASN>\033[0m"
  exit 1
fi

ASN="$1"
LOGFILE="asn_processing_$(date +%Y%m%d_%H%M%S).log"

# Required tools check
REQUIRED_TOOLS=("whois" "asnmap" "mapcidr" "dnsx")
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v $tool &> /dev/null; then
    echo -e "\033[1;34mError: $tool is not installed. Please install it before running the script.\033[0m" | tee -a "$LOGFILE"
    exit 1
  fi
done

echo -e "\033[1;34mStarting ASN processing for $ASN at $(date)\033[0m" | tee -a "$LOGFILE"

# Step 1: Fetch CIDR ranges from RADB
echo -e "\033[1;34mFetching CIDR ranges from RADB...\033[0m" | tee -a "$LOGFILE"
whois -h whois.radb.net -- "-i origin $ASN" | grep -Eo "([0-9.]+){4}/[0-9]+" | uniq > CIDR1.txt

# Step 2: Fetch CIDR ranges using ASNMap
echo -e "\033[1;34mFetching CIDR ranges using ASNMap...\033[0m" | tee -a "$LOGFILE"
asnmap -a "$ASN" -o CIDR2.txt

# Step 3: Combine and deduplicate CIDR ranges
echo -e "\033[1;34mCombining and deduplicating CIDR ranges...\033[0m" | tee -a "$LOGFILE"
cat CIDR1.txt CIDR2.txt | sort | uniq | tee CIDR.txt > /dev/null

# Cleanup temporary files
rm CIDR1.txt CIDR2.txt

# Step 4: Expand CIDR ranges into individual IPs
echo -e "\033[1;34mExpanding CIDR ranges into individual IPs...\033[0m" | tee -a "$LOGFILE"
mapcidr -cidr CIDR.txt -o all_ip.txt

# Step 5: Perform reverse DNS lookups (Method 1)
echo -e "\033[1;34mPerforming reverse DNS lookups (Method 1)...\033[0m" | tee -a "$LOGFILE"
cat CIDR.txt | dnsx -ptr -resp-only -silent -retry 3 > Domain1.txt

# Step 6: Perform reverse DNS lookups (Method 2)
echo -e "\033[1;34mPerforming reverse DNS lookups (Method 2)...\033[0m" | tee -a "$LOGFILE"
whois -h whois.radb.net -- "-i origin $ASN" | grep -Eo "([0-9.]+){4}/[0-9]+" | uniq | mapcidr -silent | dnsx -ptr -resp-only -retry 3 -silent > Domain2.txt

# Step 7: Combine and deduplicate resolved domains
echo -e "\033[1;34mCombining and deduplicating resolved domains...\033[0m" | tee -a "$LOGFILE"
cat Domain1.txt Domain2.txt | sort | uniq | tee ASN_domain.txt > /dev/null

# Cleanup temporary domain files
rm Domain1.txt Domain2.txt

# Step 8: Check for open ports
echo -e "\033[1;34mChecking open ports on IPs...\033[0m" | tee -a "$LOGFILE"
naabu -list all_ip.txt -p 80,443 -v -o port-open-list.txt

# Step 8: Summary of results
echo -e "\033[1;34mProcessing complete.\033[0m" | tee -a "$LOGFILE"
echo -e "\033[1;34mCIDR Ranges: $(wc -l < CIDR.txt)\033[0m" | tee -a "$LOGFILE"
echo -e "\033[1;34mTotal IPs: $(wc -l < all_ip.txt)\033[0m" | tee -a "$LOGFILE"
echo -e "\033[1;34mResolved Domains: $(wc -l < ASN_domain.txt)\033[0m" | tee -a "$LOGFILE"
echo -e "\033[1;34mOpen Ports: $(wc -l < port-open-list.txt)\033[0m" | tee -a "$LOGFILE"

# Optional: Archive results
RESULT_ARCHIVE="asn_results_$ASN_$(date +%Y%m%d_%H%M%S).tar.gz"
tar -czf "$RESULT_ARCHIVE" CIDR.txt all_ip.txt ASN_domain.txt port-open-list.txt
echo -e "\033[1;34mResults archived to $RESULT_ARCHIVE\033[0m" | tee -a "$LOGFILE"

# Cleanup CIDR and domain result files if not needed
# Uncomment the line below to remove raw files after archiving
# rm CIDR.txt all_ip.txt ASN_domain.txt port-open-list.txt

echo -e "\033[1;34mLog file saved to $LOGFILE"
