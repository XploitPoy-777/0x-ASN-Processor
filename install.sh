#!/bin/bash

# Define color variables for output formatting
g='\033[0;32m' # Green
r='\033[0;31m' # Red
e='\033[0m'    # Reset

# Function to check if a command is successful and print the result
check_status() {
    if [ $? -eq 0 ]; then
        printf "$g[✔] $1 Installed Successfully $e\n"
    else
        printf "$r[✘] Failed to Install $1 $e\n"
        exit 1
    fi
}

echo -e "\nInstalling Required Tools...\n"

# Install asnmap
echo "Installing asnmap..."
go install github.com/projectdiscovery/asnmap/cmd/asnmap@latest
check_status "asnmap"
sudo mv ~/go/bin/asnmap /usr/local/bin
check_status "asnmap moved to /usr/local/bin"

# Install mapcidr
echo "Installing mapcidr..."
go install -v github.com/projectdiscovery/mapcidr/cmd/mapcidr@latest
check_status "mapcidr"
sudo mv ~/go/bin/mapcidr /usr/local/bin
check_status "mapcidr moved to /usr/local/bin"

# Install dnsx
echo "Installing dnsx..."
go install -v github.com/projectdiscovery/dnsx/cmd/dnsx@latest
check_status "dnsx"
sudo mv ~/go/bin/dnsx /usr/local/bin
check_status "dnsx moved to /usr/local/bin"

# Install whois
echo "Installing whois..."
sudo apt update && sudo apt install -y whois
check_status "whois"

# Install naabu
echo "Installing naabu..."
go install -v github.com/projectdiscovery/naabu/v2/cmd/naabu@latest
check_status "naabu"
sudo mv ~/go/bin/naabu /usr/local/bin
check_status "naabu moved to /usr/local/bin"

# Install awk
sudo apt install gawk
check_status "gawk"

# Install nmap
sudo apt install nmap
check_status "nmap"

echo -e "\n$g[✔] All Tools Installed Successfully! $e\n"
