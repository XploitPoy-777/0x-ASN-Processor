# ASN Processing Tool

This script automates the process of extracting CIDR ranges, resolving IPs, and performing reverse DNS lookups for a given ASN. It also includes automated installation of required tools.

## Features
- Extract CIDR ranges using `whois` and `asnmap`.
- Expand CIDR ranges into individual IP addresses using `mapcidr`.
- Perform reverse DNS lookups to resolve associated domains using `dnsx`.
- Checks for open ports on All IPs  using `naabu`.
- Automatically install missing tools.
- Archive results for easier storage and sharing.
- Comprehensive logging for tracking progress.

---

## Tools Required
The script uses the following tools:
1. **whois**: For querying CIDR ranges from RADB.
2. **asnmap**: For extracting CIDR ranges associated with an ASN.
3. **mapcidr**: For expanding CIDRs into individual IPs.
4. **dnsx**: For reverse DNS lookups and domain resolution.
5. **naabu**: Checks for open ports on IPs from all_ip.txt.

---

## Installation Instructions

### Step 1: Clone the Repository
```bash
git clone https://github.com/0xPoyel/0x-asn-toolkit.git
cd 0x-asn-toolkit
```
### Step 2: Install Required Tools
The script will check and install missing tools automatically. Below are the manual installation commands for each tool:

Tools Install:
```bash
# Make it executable:
chmod +x install.sh

# Run the script:
./install.sh
```

Tools Install Check: 

```bash
# Make it executable:
chmod +x check.sh

# Run the script:
./check.sh
```

### Manually Install
- whois:
```bash
  sudo apt update && sudo apt install -y whois
```
- asnmap:
```bash
  go install github.com/projectdiscovery/asnmap/cmd/asnmap@latest
```
- mapcidr:
```bash
  go install github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest
```
- dnsx:
```bash
  go install github.com/projectdiscovery/dnsx/cmd/dnsx@latest
```
- naabu:
```bash
  go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
```

### Usage Instructions
1. Make the script executable:
```bash
  chmod +x 0x-asn-toolkit.sh
```
2. Run the script:
```bash
  ./asn_processor.sh <ASN>
```
- Replace <ASN> with the target ASN, e.g., AS12345.

3. Output Files:
- CIDR.txt: Combined list of CIDR ranges.
- all_ip.txt: All IP addresses from the CIDR ranges.
- ASN_domain.txt: Resolved domains from reverse DNS lookups.
- Archived Results: Results are saved as asn_results_<ASN>_<timestamp>.tar.gz
4. Logs: A detailed log file (asn_processing_<timestamp>.log) is created for each run.
### Example
```bash
./0x-asn-toolkit.sh AS12345
```
### Output:

- CIDR.txt
- all_ip.txt
- ASN_domain.txt
- port-open-list.txt
- Results archived to asn_results_AS12345_<timestamp>.tar.gz.
### Dependencies
Ensure the following are installed:
- Linux/Unix Shell
- Golang: For asnmap, mapcidr, naabu and dnsx
```bash
sudo apt install -y golang
```
## Contribution
- Contributions are welcome! Please feel free to open issues or submit pull requests for improvements.

### ⚠️ Reminder
🛡️ Always use this script ethically and responsibly. Ensure you have proper authorization before scanning or querying any resources. This tool is designed to enhance security research, not violate policies or laws.
