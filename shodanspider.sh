#!/bin/env bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;97m'
RESET='\033[0m'  # Reset to default color

# Function to display the banner with colors
display_banner() {
    echo -e "${CYAN}###########################################################${RESET}"
    echo -e "${BLUE}#                                                         #${RESET}"
    echo -e "${GREEN}#      🌐  Welcome to ShodanSpider v2.0  🌐               #${RESET}"
    echo -e "${BLUE}#                                                         #${RESET}"
    echo -e "${CYAN}###########################################################${RESET}"
    echo -e "${YELLOW}#  🚀  Powered by: Shubham Rooter                         #${RESET}"
    echo -e "${YELLOW}#  📧  Contact: info@shubhamrooter.com                    #${RESET}"
    echo -e "${YELLOW}#  🛠️   Version: 2.0                                       #${RESET}"
    echo -e "${CYAN}###########################################################${RESET}"
    echo -e "${WHITE}#   📝  For detailed usage, run with -h for help.         #${RESET}"
    echo -e "${CYAN}###########################################################${RESET}"
    echo ""
}

# Function to display help with colors
display_help() {
    echo -e "${YELLOW}Usage: $0 [OPTIONS]${RESET}"
    echo ""
    echo -e "${CYAN}Options:${RESET}"
    echo -e "${GREEN}  -q [query]        ${RESET}Search Shodan with a specific query."
    echo -e "${GREEN}  -cve [cve-id]     ${RESET}Search Shodan for a specific CVE."
    echo -e "${GREEN}  -o [filename]     ${RESET}Save the output to a specified file."
    echo -e "${GREEN}  -h                ${RESET}Display this help message."
    echo ""
    echo -e "${CYAN}Examples:${RESET}"
    echo -e "${GREEN}  $0 -q apache -o output.txt${RESET}"
    echo -e "${GREEN}  $0 -cve cve-2021-34473${RESET}"
    echo ""
    echo -e "${YELLOW}Note:${RESET} Make sure you have jq installed for query encoding."
    exit 0
}

# Display the banner
display_banner

# Check if the user asked for help
if [[ $1 == "-h" ]]; then
    display_help
fi

# Check if arguments are valid
[[ $# -lt 2 || ( $1 != "-q" && $1 != "-cve" ) ]] && { 
    echo -e "${RED}Invalid arguments. Use -h for help.${RESET}"; 
    exit 1; 
}

# Initialize variables
query=""
output_file=""

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -q)
            query=$2
            shift 2
            ;;
        -cve)
            query="vuln:$2"
            shift 2
            ;;
        -o)
            output_file=$2
            shift 2
            ;;
        *)
            echo -e "${RED}Invalid argument: $1. Use -h for help.${RESET}"
            exit 1
            ;;
    esac
done

# Encode the query for URL
encoded_query=$(echo "$query" | jq -sRr @uri)
url="https://www.shodan.io/search/facet?query=${encoded_query}&facet=ip"

# Randomized User Agents for the request
USER_AGENTS=(
    "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2 Safari/605.1.15"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Firefox/122.0"
    "Mozilla/5.0 (X11; Ubuntu; Linux x86_64) Firefox/122.0"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15) Firefox/122.0"
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) Edge/120.0.2210.133"
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) Edge/120.0.2210.133"
    "Mozilla/5.0 (X11; Linux x86_64) Edge/120.0.2210.133"
)

# Randomly select a User Agent
UA=${USER_AGENTS[$RANDOM % ${#USER_AGENTS[@]}]}

# Execute the curl request and filter IP addresses
result=$(curl -s -A "$UA" \
    -H "Accept: text/html,application/xhtml+xml" \
    -H "Accept-Language: en-US,en;q=0.9" \
    --compressed "$url" | \
    grep -o '[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}' | \
    grep -v '^0\.\|^127\.\|^169\.254\.\|^172\.\(1[6-9]\|2[0-9]\|3[0-1]\)\.\|^192\.168\.\|^10\.\|^224\.\|^240\.' | \
    sort -u)

# Count the number of results
count=$(echo "$result" | wc -l)

# Output the result to the console or save to a file
if [[ -n "$output_file" ]]; then
    echo "$result" > "$output_file"
    echo -e "${GREEN}Results saved to $output_file.${RESET}"
    echo -e "${CYAN}Total Results: $count${RESET}"
else
    echo "$result"
    echo -e "${CYAN}Total Results: $count${RESET}"
fi
