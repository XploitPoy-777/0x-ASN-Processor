#!/bin/bash

# Define color variables for output formatting
g='\033[0;32m' # Green
r='\033[0;31m' # Red
e='\033[0m'    # Reset

# Check for the presence of each required tool and print the status
hash whois 2>/dev/null && printf "[whois] $g Installed $e\n" || printf "[whois] $r Install Manually $e\n"
hash asnmap 2>/dev/null && printf "[asnmap] $g Installed $e\n" || printf "[asnmap] $r Install Manually $e\n"
hash mapcidr 2>/dev/null && printf "[mapcidr] $g Installed $e\n" || printf "[mapcidr] $r Install Manually $e\n"
hash dnsx 2>/dev/null && printf "[dnsx] $g Installed $e\n" || printf "[dnsx] $r Install Manually $e\n"
