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

# Help message function
show_help() {
    echo -e ""
    echo -e "${CYAN}Usage: $0 <ASN>${NC}"
    echo -e ""
    echo -e "${YELLOW}Description:${NC}"
    echo -e "This script performs the following tasks:"
    echo -e "- Fetches CIDR ranges for a given ASN."
    echo -e "- Resolves IPs and performs reverse DNS lookups"
    echo -e "- Identifying alive IPs from the gathered ranges."
    echo -e "- Scanning open ports and services on the alive IPs."
    echo -e "- Saving results (logs, CIDR ranges, Alive IPS, Domains, Scanning Output) in a dedicated output directory."
    echo -e ""
    echo -e "${YELLOW}Options:${NC}"
    echo -e "  -h, --help      Show this help message and exit"
    echo -e ""
    echo -e "${YELLOW}Notes:${NC}"
    echo -e "  Ensure that all required tools (whois, asnmap, mapcidr, dnsx, naabu, nmap, awk) are installed."
    echo -e "  Results will be stored in a timestamped directory for easy organization."
    exit 0
}

# Check if help flag is provided
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
fi

# Check if an ASN argument is provided
if [ -z "$1" ]; then
  echo -e "${RED}Usage: $0 <ASN>${NC}"
  exit 1
fi

ASN="$1"

# Define the output directory
OUTPUT_DIR="./asn_results_$ASN_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUTPUT_DIR"

# Define log file in the output directory
LOGFILE="$OUTPUT_DIR/asn_processing.log"

# Update or clone 0x-asn-toolkit
TOOLKIT_DIR="0x-asn-toolkit"

if [ -d "$TOOLKIT_DIR" ]; then
    echo -e "${YELLOW}[+] Directory '$TOOLKIT_DIR' found. Attempting to update the repository...${NC}" | tee -a "$LOGFILE"
    cd "$TOOLKIT_DIR" || { echo -e "${RED}Failed to navigate to '$TOOLKIT_DIR'. Exiting.${NC}" | tee -a "$LOGFILE"; exit 1; }
    if git pull origin main; then
        echo -e "${GREEN}[+] Successfully updated 0x-asn-toolkit repository.${NC}" | tee -a "$LOGFILE"
    else
        echo -e "${RED}[-] Failed to update 0x-asn-toolkit repository. Please check your network or git settings.${NC}" | tee -a "$LOGFILE"
        exit 1
    fi
    cd .. || { echo -e "${RED}Failed to navigate back to the parent directory. Exiting.${NC}" | tee -a "$LOGFILE"; exit 1; }
else
    echo -e "${YELLOW}[+] Directory '$TOOLKIT_DIR' not found. Cloning the repository...${NC}" | tee -a "$LOGFILE"
    if git clone https://github.com/0xPoyel/0x-asn-toolkit.git; then
        echo -e "${GREEN}[+] Successfully cloned 0x-asn-toolkit repository.${NC}" | tee -a "$LOGFILE"
    else
        echo -e "${RED}[-] Failed to clone 0x-asn-toolkit repository. Please check your network or git settings.${NC}" | tee -a "$LOGFILE"
        exit 1
    fi
fi



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
  echo -e "${YELLOW}[+] Checking network connectivity...${NC}"
  while ! ping -c 1 -q google.com &>/dev/null; do
    echo -e "${RED}[-] Network is offline. Retrying in 10 seconds...${NC}"
    sleep 10
  done
  echo -e "${GREEN}[+] Network is online. Proceeding...${NC}"
}

# Step 1: Fetch CIDR ranges from RADB
echo -e "${BLUE}Fetching CIDR ranges from RADB...${NC}" | tee -a "$LOGFILE"
whois -h whois.radb.net -- "-i origin $ASN" | grep -Eo "([0-9.]+){4}/[0-9]+" | uniq > "$OUTPUT_DIR/CIDR1.txt"

# Step 2: Fetch CIDR ranges using ASNMap
echo -e "${BLUE}Fetching CIDR ranges using ASNMap...${NC}" | tee -a "$LOGFILE"
asnmap -a "$ASN" -o "$OUTPUT_DIR/CIDR2.txt"

# Step 3: Combine and deduplicate CIDR ranges
echo -e "${BLUE}Combining and deduplicating CIDR ranges...${NC}" | tee -a "$LOGFILE"
cat "$OUTPUT_DIR/CIDR1.txt" "$OUTPUT_DIR/CIDR2.txt" | sort | uniq > "$OUTPUT_DIR/CIDR.txt"

# Cleanup temporary CIDR files
rm "$OUTPUT_DIR/CIDR1.txt" "$OUTPUT_DIR/CIDR2.txt"

# Step 4: Expand CIDR ranges into individual IPs
echo -e "${BLUE}Expanding CIDR ranges into individual IPs...${NC}" | tee -a "$LOGFILE"
mapcidr -cidr "$OUTPUT_DIR/CIDR.txt" -o "$OUTPUT_DIR/All_ip.txt"

# Step 5: Perform reverse DNS lookups (Method 1)
echo -e "${BLUE}Performing reverse DNS lookups (Method 1)...${NC}" | tee -a "$LOGFILE"
cat "$OUTPUT_DIR/CIDR.txt" | dnsx -ptr -resp-only -silent -retry 3 > "$OUTPUT_DIR/Domain1.txt"


# Step 6: Perform reverse DNS lookups (Method 2)
echo -e "${BLUE}Performing reverse DNS lookups (Method 2)...${NC}" | tee -a "$LOGFILE"
whois -h whois.radb.net -- "-i origin $ASN" | grep -Eo "([0-9.]+){4}/[0-9]+" | uniq | mapcidr -silent | dnsx -ptr -resp-only -retry 3 -silent > "$OUTPUT_DIR/Domain2.txt"

# Step 7: Combine and deduplicate resolved domains
echo -e "${BLUE}Combining and deduplicating resolved domains...${NC}" | tee -a "$LOGFILE"
cat "$OUTPUT_DIR/Domain1.txt" "$OUTPUT_DIR/Domain2.txt" | sort | uniq | tee "$OUTPUT_DIR/ASN_domain.txt" 

# Step 8: Cleanup temporary domain files
rm "$OUTPUT_DIR/Domain1.txt" "$OUTPUT_DIR/Domain2.txt"

# Step 9: Check for alive IPs
echo -e "${BLUE}Checking Alive IPs...${NC}" | tee -a "$LOGFILE"
naabu -list "$OUTPUT_DIR/All_ip.txt" -p 80,443 -rate 5000 -silent | awk -F: '{print $1}' > "$OUTPUT_DIR/Alive_ips.txt"

# Step 10: Perform a detailed Nmap scan
echo -e "${BLUE}Starting Nmap service version detection on alive IPs...${NC}" | tee -a "$LOGFILE"
nmap -sV -T4 \
     -p 17,20,21,22,23,24,25,53,69,80,123,139,137,445,443,1723,161,177,3306,8080,8081,8082,8088,8443,4343,8888,27017,27018 \
     -iL "$OUTPUT_DIR/Alive_ips.txt" \
     -oN "$OUTPUT_DIR/Nmap_scan_results.txt"
     
if [ $? -eq 0 ]; then
  echo -e "${BLUE}Nmap scan completed successfully. Results saved to namp-scan-result.txt${NC}" | tee -a "$LOGFILE"
else
  echo -e "${BLUE}Error: Nmap scan failed. Check your inputs or logs.${NC}"| tee -a "$LOGFILE"
fi


# Step 11: Summary of results
echo -e "${BLUE}Processing complete.${NC}" | tee -a "$LOGFILE"
echo -e "${BLUE}CIDR Ranges: $(wc -l < "$OUTPUT_DIR/CIDR.txt")${NC}" | tee -a "$LOGFILE"
echo -e "${BLUE}Total IPs: $(wc -l < "$OUTPUT_DIR/All_ip.txt")${NC}" | tee -a "$LOGFILE"
echo -e "${BLUE}Resolved Domains: $(wc -l < "$OUTPUT_DIR/ASN_domain.txt")${NC}" | tee -a "$LOGFILE"
echo -e "${BLUE}Alive IPs: $(wc -l < "$OUTPUT_DIR/Alive_ips.txt")${NC}" | tee -a "$LOGFILE"
echo -e "${BLUE}Results saved in: $OUTPUT_DIR${NC}" | tee -a "$LOGFILE"
echo -e "${BLUE}Log file: $LOGFILE${NC}" | tee -a "$LOGFILE"
