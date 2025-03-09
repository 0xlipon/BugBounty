#!/usr/bin/env bash
BOLD_BLUE="\033[1;34m"
RED="\033[0;31m"
NC="\033[0m"
BOLD_YELLOW="\033[1;33m"

# Function to display usage message
display_usage() {
    echo ""
    echo "Options:"
    echo "     -h               Display this help message"
    echo "     -d               Single Domain link Spidering"
    echo "     -l               Multi Domain link Spidering"
    echo "     -i               Check required tool installed or not."
    echo -e "${BOLD_YELLOW}Usage:${NC}"
    echo -e "${BOLD_YELLOW}    $0 -d http://example.com${NC}"
    echo -e "${BOLD_YELLOW}    $0 -l http://example.com${NC}"
    echo -e "${RED}Required Tools:${NC}"
    echo -e "              ${RED}
            https://github.com/xnl-h4ck3r/waymore
            https://github.com/tomnomnom/anew
            https://github.com/projectdiscovery/urlfinder
            https://github.com/lc/gau${NC}"
    exit 0
}

# Function to check installed tools
check_tools() {
    tools=("gau" "waymore" "urlfinder" "anew")

    echo "Checking required tools:"
    for tool in "${tools[@]}"; do
        if command -v "$tool" &> /dev/null; then
            echo -e "${BOLD_BLUE}$tool is installed at ${BOLD_WHITE}$(which $tool)${NC}"
        else
            echo -e "${RED}$tool is NOT installed or not in the PATH${NC}"
        fi
    done
}

# Check if tool installation check is requested
if [[ "$1" == "-i" ]]; then
    check_tools
    exit 0
fi

# help function execution
if [[ "$1" == "-h" ]]; then
    display_usage
    exit 0
fi

# single domain url getting
if [[ "$1" == "-d" ]]; then
    domain_Without_Protocol=$(echo "$2" | sed 's,http://,,;s,https://,,;s,www\.,,;')
    # making directory
    main_dir="PII_bug/$domain_Without_Protocol"
    base_dir="$main_dir/single_domain/recon"

    mkdir -p $main_dir
    waymore -i "$domain_Without_Protocol" -n -mode U --providers wayback,otx,urlscan,virustotal -oU $base_dir/waymore.txt

    gau "$domain_Without_Protocol" --providers wayback,commoncrawl,otx,urlscan --verbose --o $base_dir/gau.txt

    cat $base_dir/waymore.txt $base_dir/gau.txt | anew $base_dir/all_urls.txt
    cat $base_dir/all_urls.txt | grep -aE '\.doc|\.docx|\.dot|\.dotm|\.xls|\.xlsx|\.xlt|\.xlsm|\.xlsb|\.ppt|\.pptx|\.pot|\.pps|\.pptm|\.mdb|\.accdb|\.mde|\.accde|\.adp|\.accdt|\.pub|\.puz|\.one|\.xml|\.pdf|\.sql|\.txt|\.zip|\.tar\.gz|\.tgz|\.bak|\.7z|\.rar|\.log|\.cache|\.secret|\.db|\.backup|\.yml|\.gz|\.config|\.csv|\.exe|\.dll|\.bin|\.ini|\.bat|\.sh|\.deb|\.rpm|\.iso|\.apk|\.msi|\.dmg|\.tmp|\.crt|\.pem|\.key|\.pub|\.asc|\.bz2|\.xz|\.lzma|\.z|\.cab|\.arj|\.lha|\.ace|\.arc|\.sqlite|\.sqlite3|\.db3|\.sqlitedb|\.sdb|\.sqlite2|\.frm|\.old|\.sav|\.enc|\.pgp|\.locky|\.secure|\.gpg|\.json' | anew $base_dir/all_extension_urls.txt

    cat $base_dir/all_urls.txt | anew $base_dir/all_unique_urls.txt

    all_urls_path=$base_dir/all_extension_urls.txt
    all_urls_count=$(cat $base_dir/all_extension_urls.txt | wc -l)
    echo -e "${BOLD_YELLOW}All extension urls${NC}(${RED}$all_urls_count${NC}): ${BOLD_BLUE}$all_urls_path${NC}"


    chmod -R 777 $main_dir

    exit 0
fi



# multi domain url getting
if [[ "$1" == "-l" ]]; then
    domain_Without_Protocol=$(echo "$2" | sed 's,http://,,;s,https://,,;s,www\.,,;')
    # making directory
    main_dir="PII_bug/$domain_Without_Protocol"
    base_dir="$main_dir/multi_domain/recon"

    mkdir -p $main_dir

    urlfinder -all -d "$domain_Without_Protocol" -o $base_dir/urlfinder.txt

    waymore -i "$domain_Without_Protocol" -mode U --providers wayback,otx,urlscan,virustotal -oU $base_dir/waymore.txt

    gau "$domain_Without_Protocol" --subs --providers wayback,commoncrawl,otx,urlscan --verbose --o $base_dir/gau.txt

    cat $base_dir/urlfinder.txt $base_dir/waymore.txt $base_dir/gau.txt | anew $base_dir/all_urls.txt
    cat $base_dir/all_urls.txt | grep -aE '\.xls|\.xml|\.xlsx|\.pdf|\.sql|\.doc|\.docx|\.pptx|\.txt|\.zip|\.tar\.gz|\.tgz|\.bak|\.7z|\.rar|\.log|\.cache|\.secret|\.db|\.backup|\.yml|\.gz|\.config|\.csv|\.yaml|\.exe|\.dll|\.bin|\.ini|\.bat|\.sh|\.tar|\.deb|\.rpm|\.iso|\.apk|\.msi|\.dmg|\.tmp|\.crt|\.pem|\.key|\.pub|\.asc' | anew $base_dir/all_extension_urls.txt

    all_urls_path=$base_dir/all_extension_urls.txt
    all_urls_count=$(cat $base_dir/all_extension_urls.txt | wc -l)
    echo -e "${BOLD_YELLOW}All extension urls${NC}(${RED}$all_urls_count${NC}): ${BOLD_BLUE}$all_urls_path${NC}"

    chmod -R 777 $main_dir

    exit 0
fi
