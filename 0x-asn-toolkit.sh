#!/bin/bash

# Script for extracting CIDR ranges, resolving IPs, performing reverse DNS lookups, and scanning services for a given ASN.
# Usage: ./script.sh <ASN>

#!/bin/bash

# Define colors
RED='\033[1;31m'
BLUE='\033[1;34m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
CYAN='\033[1;36m'
NC='\033[0m' # No Color

# Function to display the logo
display_logo() {
    echo -e "${BLUE}======================================="
    echo -e "${CYAN}      ██████╗ ██╗   ██╗███████╗       "
    echo -e "${CYAN}      ██╔══██╗██║   ██║██╔════╝       "
    echo -e "${CYAN}      ██████╔╝██║   ██║█████╗         "
    echo -e "${CYAN}      ██╔═══╝ ██║   ██║██╔══╝         "
    echo -e "${CYAN}      ██║     ╚██████╔╝███████╗       "
    echo -e "${CYAN}      ╚═╝      ╚═════╝ ╚══════╝       "
    echo -e "${BLUE}=======================================${NC}"
    echo -e "${YELLOW}     0xPoyel ASN Processor     "
    echo -e "${BLUE}=======================================${NC}"
}

# Call the function to display the logo
display_logo


# Check if an ASN argument is provided
if [ -z "$1" ]; then
  echo -e "\033[1;34mUsage: $0 <ASN>\033[0m"
  exit 1
fi

ASN="$1"
LOGFILE="asn_processing_$(date +%Y%m%d_%H%M%S).log"

# Required tools check
REQUIRED_TOOLS=("whois" "asnmap" "mapcidr" "dnsx" "naabu" "nmap" "awk")
for tool in "${REQUIRED_TOOLS[@]}"; do
  if ! command -v $tool &> /dev/null; then
    echo -e "\033[1;34mError: $tool is not installed. Please install it before running the script.\033[0m" | tee -a "$LOGFILE"
    exit 1
  fi
done

echo -e "\033[1;34mStarting ASN processing for $ASN at $(date)\033[0m" | tee -a "$LOGFILE"


# Function to check network connectivity
check_network() {
  echo -e "\033[1;33m[+] Checking network connectivity...\033[0m"
  while ! ping -c 1 -q google.com &>/dev/null; do
    echo -e "\033[1;31m[-] Network is offline. Retrying in 10 seconds...\033[0m"
    sleep 10
  done
  echo -e "\033[1;32m[+] Network is online. Proceeding...\033[0m"
}

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
mapcidr -cidr CIDR.txt -o All_ip.txt

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
echo -e "\033[1;34mChecking Alive IPs...\033[0m" | tee -a "$LOGFILE"
naabu -list All_ip.txt -p 80,443 -rate 5000 -silent | awk -F: '{print $1}' > Alive_ips.txt

# Step 9: Perform a detailed Nmap scan
echo -e "\033[1;34mStarting Nmap service version detection on Alive IPs...\033[0m" | tee -a "$LOGFILE"
nmap -sV -T4 \
     -p 17,20,21,22,23,24,25,53,69,80,123,139,137,445,443,1723,161,177,3306,8080,8081,8082,8088,8443,4343,8888,27017,27018 \
     -iL Alive_ips.txt \
     -oN namp-scan-result.txt

if [ $? -eq 0 ]; then
  echo -e "\033[1;34mNmap scan completed successfully. Results saved to namp-scan-result.txt\033[0m" | tee -a "$LOGFILE"
else
  echo -e "\033[1;34mError: Nmap scan failed. Check your inputs or logs.\033[0m" | tee -a "$LOGFILE"
fi

# Step 10: Summary of results
echo -e "\033[1;34mProcessing complete.\033[0m" | tee -a "$LOGFILE"
echo -e "\033[1;34mCIDR Ranges: $(wc -l < CIDR.txt)\033[0m" | tee -a "$LOGFILE"
echo -e "\033[1;34mTotal IPs: $(wc -l < all_ip.txt)\033[0m" | tee -a "$LOGFILE"
echo -e "\033[1;34mResolved Domains: $(wc -l < ASN_domain.txt)\033[0m" | tee -a "$LOGFILE"
echo -e "\033[1;34mAlive IPs: $(wc -l < alive_ips.txt)\033[0m" | tee -a "$LOGFILE"


# Cleanup CIDR and domain result files if not needed
# Uncomment the line below to remove raw files after archiving
# rm CIDR.txt all_ip.txt ASN_domain.txt alive_ips.txt scan-result.txt

echo -e "\033[1;34mLog file saved to $LOGFILE\033[0m"
