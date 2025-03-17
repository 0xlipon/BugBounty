#!/bin/bash

# Define colors
WHITE='\033[97m'
BLUE='\033[34m'
BOLD_WHITE='\033[1;97m'
BOLD_BLUE='\033[1;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'  # No Color

# Function to handle errors
handle_error() {
    echo -e "${RED}Error occurred during the execution of $1. Exiting.${NC}"
    echo "Error during: $1" >> error.log
    exit 1
}

# Function to show progress with emoji
show_progress() {
    echo -e "${BOLD_BLUE}Current process: $1...⌛️${NC}"
}

# Function to remove duplicate domains
remove_duplicates() {
    file_path=$1
    initial_count=$(wc -l < "$file_path")
    awk '{sub(/^https?:\/\//, "", $0); sub(/^www\./, "", $0); if (!seen[$0]++) print}' "$file_path" > "unique-$file_path"
    final_count=$(wc -l < "unique-$file_path")
    removed_count=$((initial_count - final_count))
    echo -e "${RED}Removed $removed_count duplicate domains. Total subdomains after processing: $final_count${NC}"
    sleep 3

    # Step 6.1: Removing old domain list
    show_progress "Removing old domain list"
    rm -r "${domain_name}-domains.txt" || handle_error "Removing old domain list"
    sleep 3
}

# Banner
echo -e "${CYAN}┌───────────────────────────────────────────────┐"
echo -e "${WHITE} 💰 ${BOLD_BLUE}B U G   B O U N T Y   R E C O N   T O O L 🚀 ${BOLD_BLUE} "
echo -e "${CYAN}├───────────────────────────────────────────────┤"
echo -e "${WHITE}       ⚡ ${CYAN}Version: 1.0 • Author: 0xlipon ⚡ ${WHITE}"
echo -e "${CYAN}└───────────────────────────────────────────────┘${NC}"
echo -e "${RED}💀 With great power comes great responsibility!💀 ${RED}"
echo -e "${YELLOW}☕ Sit back, relax, and let the recon begin... 🔥 ${NC}"
echo ""

# Prompt for the domain name
read -p "Enter Target Domain Name: " domain_name

# Prompt for the file containing URLs
read -p "Enter the path to the file containing URLs: " url_file

# Validate if the file exists
if [[ ! -f "$url_file" ]]; then
    handle_error "The file '$url_file' does not exist!"
fi

# Copy URLs into a domain-specific file
output_file="${domain_name}-domains.txt"
cp "$url_file" "$output_file"

# Step 2.1: Crawling with GoSpider
show_progress "Crawling links with GoSpider"
gospider -S "${domain_name}-domains.txt" -c 10 -d 5 | tee -a "${domain_name}-gospider.txt" || handle_error "GoSpider crawl"
sleep 3

# Step 2.2: Crawling with Hakrawler
show_progress "Crawling links with Hakrawler"
cat "${domain_name}-domains.txt" | hakrawler -d 3 -subs | tee -a "${domain_name}-hakrawler.txt" || handle_error "Hakrawler crawl"
sleep 3

# Step 2.3: Crawling with URLFinder
show_progress "Crawling links with URLFinder"
urlfinder -all -d "${domain_name}-domains.txt" -o "${domain_name}-urlfinder.txt" || handle_error "URLFinder crawl"
sleep 3


# Step 2.4: Crawling with Katana
show_progress "Crawling links with Katana"
cat "${domain_name}-domains.txt" | katana -jc | tee -a "${domain_name}-katana.txt" || handle_error "Katana crawl"
sleep 3

# Step 2.5: Crawling with Waybackurls
show_progress "Crawling links with Waybackurls"
cat "${domain_name}-domains.txt" | waybackurls | tee -a "${domain_name}-waybackurls.txt" || handle_error "Waybackurls crawl"
sleep 3

# Step 2.5.0: Crawling with Gau
show_progress "Crawling links with Gau"
# Perform crawling with Gau and save results
cat "${domain_name}-domains.txt" | gau | tee -a "${domain_name}-gau.txt" || handle_error "Gau crawl"
sleep 3

echo -e "${BOLD_BLUE}Crawling and filtering URLs completed successfully. Output files created for each tool.${NC}"
    
# Step 2.6: Filter invalid links on Gospider and Hakrawler
show_progress "Filtering invalid links on Gospider & Hakrawler & UrlFinder"
grep -oP 'http[^\s]*' "${domain_name}-gospider.txt" > "${domain_name}-gospider1.txt"
grep -oP 'http[^\s]*' "${domain_name}-hakrawler.txt" > "${domain_name}-hakrawler1.txt"
grep -oP 'http[^\s]*' "${domain_name}-urlfinder.txt" > "${domain_name}-urlfinder1.txt"
sleep 3

# Step 2.7: Remove old Gospider & Hakrawler & UrlFinder files
show_progress "Removing old Gospider & Hakrawler & UrlFinder files"
rm -r "${domain_name}-gospider.txt" "${domain_name}-hakrawler.txt" "${domain_name}-urlfinder.txt"
sleep 3

# Step 2.8: Filter similar URLs with URO tool
show_progress "Filtering similar URLs with URO tool"
uro -i "${domain_name}-gospider1.txt" -o urogospider.txt &
uro_pid_gospider=$!

uro -i "${domain_name}-hakrawler1.txt" -o urohakrawler.txt &
uro_pid_hakrawler=$!

uro -i "${domain_name}-urlfinder1.txt" -o urourlfinder.txt &
uro_pid_urlfinder=$!

uro -i "${domain_name}-katana.txt" -o urokatana.txt &
uro_pid_katana=$!

uro -i "${domain_name}-waybackurls.txt" -o urowaybackurls.txt &
uro_pid_waybackurls=$!

uro -i "${domain_name}-gau.txt" -o urogau.txt &
uro_pid_gau=$!

# Monitor the processes
while kill -0 $uro_pid_gospider 2> /dev/null || kill -0 $uro_pid_hakrawler 2> /dev/null || \
    kill -0 $uro_pid_katana 2> /dev/null || kill -0 $uro_pid_waybackurls 2> /dev/null || \
    kill -0 $uro_pid_urlfinder 2> /dev/null || kill -0 $uro_pid_urlfinder 2> /dev/null || \
    kill -0 $uro_pid_gau 2> /dev/null; do
    echo -e "${BOLD_BLUE}URO tool is still running...⌛️${NC}"
    sleep 30  # Check every 30 seconds
done

echo -e "${BOLD_BLUE}URO processing completed. Files created successfully.${NC}"
sleep 3

# Step 2.9: Remove all previous files
show_progress "Removing all previous files"
rm -rf "${domain_name}-gospider1.txt" "${domain_name}-hakrawler1.txt" "${domain_name}-katana.txt" "${domain_name}-waybackurls.txt" "${domain_name}-gau.txt" "${domain_name}-urlfinder1.txt"
sleep 3

# Step 2.10: Merge all URO files into one final file
show_progress "Merging all URO files into one final file"
cat urogospider.txt urohakrawler.txt urokatana.txt urowaybackurls.txt urogau.txt urourlfinder.txt > "${domain_name}-links-final.txt"
    
# Create new folder 'urls' and assign permissions
show_progress "Creating 'urls' directory and setting permissions"
mkdir -p urls
chmod 777 urls

# Copy the final file to the 'urls' folder
show_progress "Copying ${domain_name}-links-final.txt to 'urls' directory"
cp "${domain_name}-links-final.txt" urls/

# Display professional message about the URLs
echo -e "${BOLD_WHITE}All identified URLs have been successfully saved in the newly created 'urls' directory.${NC}"

# Display the number of URLs in the final merged file
total_merged_urls=$(wc -l < "${domain_name}-links-final.txt")
echo -e "${BOLD_WHITE}Total URLs merged: ${RED}${total_merged_urls}${NC}"
sleep 3

# Step 2.11: Remove all 5 previous files
show_progress "Removing all 6 previous files"
rm -rf urokatana.txt urohakrawler.txt urowaybackurls.txt urogau.txt urogospider.txt urourlfinder.txt
sleep 3

# Step 3: Function to In-depth URL Filtering
echo -e "${BOLD_WHITE}Filtering extensions from the URLs for $domain_name${NC}"

# Step 3.1: Filtering extensions from the URLs
show_progress "Filtering extensions from the URLs"
cat ${domain_name}-links-final.txt | grep -E -v '\.css($|\s|\?|&|#|/|\.)|\.js($|\s|\?|&|#|/|\.)|\.jpg($|\s|\?|&|#|/|\.)|\.JPG($|\s|\?|&|#|/|\.)|\.PNG($|\s|\?|&|#|/|\.)|\.GIF($|\s|\?|&|#|/|\.)|\.avi($|\s|\?|&|#|/|\.)|\.dll($|\s|\?|&|#|/|\.)|\.pl($|\s|\?|&|#|/|\.)|\.webm($|\s|\?|&|#|/|\.)|\.c($|\s|\?|&|#|/|\.)|\.py($|\s|\?|&|#|/|\.)|\.bat($|\s|\?|&|#|/|\.)|\.tar($|\s|\?|&|#|/|\.)|\.swp($|\s|\?|&|#|/|\.)|\.tmp($|\s|\?|&|#|/|\.)|\.sh($|\s|\?|&|#|/|\.)|\.deb($|\s|\?|&|#|/|\.)|\.exe($|\s|\?|&|#|/|\.)|\.zip($|\s|\?|&|#|/|\.)|\.mpeg($|\s|\?|&|#|/|\.)|\.mpg($|\s|\?|&|#|/|\.)|\.flv($|\s|\?|&|#|/|\.)|\.wmv($|\s|\?|&|#|/|\.)|\.wma($|\s|\?|&|#|/|\.)|\.aac($|\s|\?|&|#|/|\.)|\.m4a($|\s|\?|&|#|/|\.)|\.ogg($|\s|\?|&|#|/|\.)|\.mp4($|\s|\?|&|#|/|\.)|\.mp3($|\s|\?|&|#|/|\.)|\.bat($|\s|\?|&|#|/|\.)|\.dat($|\s|\?|&|#|/|\.)|\.cfg($|\s|\?|&|#|/|\.)|\.cfm($|\s|\?|&|#|/|\.)|\.bin($|\s|\?|&|#|/|\.)|\.jpeg($|\s|\?|&|#|/|\.)|\.JPEG($|\s|\?|&|#|/|\.)|\.ps.gz($|\s|\?|&|#|/|\.)|\.gz($|\s|\?|&|#|/|\.)|\.gif($|\s|\?|&|#|/|\.)|\.tif($|\s|\?|&|#|/|\.)|\.tiff($|\s|\?|&|#|/|\.)|\.csv($|\s|\?|&|#|/|\.)|\.png($|\s|\?|&|#|/|\.)|\.ttf($|\s|\?|&|#|/|\.)|\.ppt($|\s|\?|&|#|/|\.)|\.pptx($|\s|\?|&|#|/|\.)|\.ppsx($|\s|\?|&|#|/|\.)|\.doc($|\s|\?|&|#|/|\.)|\.woff($|\s|\?|&|#|/|\.)|\.xlsx($|\s|\?|&|#|/|\.)|\.xls($|\s|\?|&|#|/|\.)|\.mpp($|\s|\?|&|#|/|\.)|\.mdb($|\s|\?|&|#|/|\.)|\.json($|\s|\?|&|#|/|\.)|\.woff2($|\s|\?|&|#|/|\.)|\.icon($|\s|\?|&|#|/|\.)|\.pdf($|\s|\?|&|#|/|\.)|\.docx($|\s|\?|&|#|/|\.)|\.svg($|\s|\?|&|#|/|\.)|\.txt($|\s|\?|&|#|/|\.)|\.jar($|\s|\?|&|#|/|\.)|\.0($|\s|\?|&|#|/|\.)|\.1($|\s|\?|&|#|/|\.)|\.2($|\s|\?|&|#|/|\.)|\.3($|\s|\?|&|#|/|\.)|\.4($|\s|\?|&|#|/|\.)|\.m4r($|\s|\?|&|#|/|\.)|\.kml($|\s|\?|&|#|/|\.)|\.pro($|\s|\?|&|#|/|\.)|\.yao($|\s|\?|&|#|/|\.)|\.gcn3($|\s|\?|&|#|/|\.)|\.PDF($|\s|\?|&|#|/|\.)|\.egy($|\s|\?|&|#|/|\.)|\.par($|\s|\?|&|#|/|\.)|\.lin($|\s|\?|&|#|/|\.)|\.yht($|\s|\?|&|#|/|\.)' > filtered-extensions-links.txt
sleep 5

# Step 3.2: Renaming filtered extensions file
show_progress "Renaming filtered extensions file"
mv filtered-extensions-links.txt "${domain_name}-links-clean.txt"
sleep 3

# Step 3.3: Filtering unwanted domains from the URLs
show_progress "Filtering unwanted domains from the URLs"
grep -E "^(https?://)?([a-zA-Z0-9.-]+\.)?${domain_name}" "${domain_name}-links-clean.txt" > "${domain_name}-links-clean1.txt"
sleep 3

# Step 3.4: Removing old filtered file
show_progress "Removing old filtered file"
rm -r ${domain_name}-links-clean.txt ${domain_name}-links-final.txt
sleep 3

# Step 3.5: Renaming new filtered file
show_progress "Renaming new filtered file"
mv ${domain_name}-links-clean1.txt ${domain_name}-links-clean.txt
sleep 3

# Step 3.6: Running URO tool again to filter duplicate and similar URLs
show_progress "Running URO tool again to filter duplicate and similar URLs"
uro -i "${domain_name}-links-clean.txt" -o "${domain_name}-uro.txt" &
uro_pid_clean=$!

# Monitor the URO process
while kill -0 $uro_pid_clean 2> /dev/null; do
    echo -e "${BOLD_BLUE}URO tool is still running for clean URLs...⌛️${NC}"
    sleep 30  # Check every 30 seconds
done

echo -e "${BOLD_BLUE}URO processing completed. Files created successfully.${NC}"
sleep 3

# Display the number of URLs in the URO output file
echo -e "${BOLD_WHITE}Total URLs in final output: ${RED}$(wc -l < "${domain_name}-uro.txt")${NC}"
sleep 3

# Step 3.7: Removing old file
show_progress "Removing old file"
rm -r "${domain_name}-links-clean.txt"
sleep 3

# Step 3.8: Removing 99% similar parameters with bash command
show_progress "Removing 99% similar parameters with bash command"
filtered_output="filtered_output.txt"
if [[ ! -f "${domain_name}-uro.txt" ]]; then 
    echo "File not found! Please check the path and try again."
    exit 1
fi
awk -F'[?&]' '{gsub(/:80/, "", $1); base_url=$1; params=""; for (i=2; i<=NF; i++) {split($i, kv, "="); if (kv[1] != "id") {params = params kv[1]; if (i < NF) {params = params "&";}}} full_url=base_url"?"params; if (!seen[full_url]++) {print $0 > "'"$filtered_output"'";}}' "${domain_name}-uro.txt"
sleep 5

# Display the number of URLs in the filtered output file
echo -e "${BOLD_WHITE}Total filtered URLs: ${RED}$(wc -l < "$filtered_output")${NC}"
sleep 3

# Step 3.9: Removing old file
show_progress "Removing old file"
rm -r "${domain_name}-uro.txt"
sleep 3

# Step 3.10: Rename to new file
show_progress "Rename to new file"
mv filtered_output.txt "${domain_name}-links.txt"
sleep 3

# Step 3.11: Filtering ALIVE URLS
show_progress "Filtering ALIVE URLS"
subprober -f "${domain_name}-links.txt" -sc -ar -o "${domain_name}-links-alive.txt" -nc -mc 200,201,202,204,301,302,304,307,308,403,500,504,401,407 -c 20 || handle_error "subprober"
sleep 5

# Step 3.12: Removing old file
show_progress "Removing old file"
rm -r ${domain_name}-links.txt
sleep 3

# Step 3.13: Filtering valid URLS
show_progress "Filtering valid URLS"
grep -oP 'http[^\s]*' "${domain_name}-links-alive.txt" > ${domain_name}-links-valid.txt || handle_error "grep valid urls"
sleep 5

# Step 3.14: Removing intermediate file and renaming final output
show_progress "Final cleanup and renaming"
rm -r ${domain_name}-links-alive.txt
mv ${domain_name}-links-valid.txt ${domain_name}-links.txt
sleep 3

echo -e "${BOLD_BLUE}Filtering process completed successfully. Final output saved as ${domain_name}-links.txt.${NC}"

# Step 4: Function to HiddenParamFinder
echo -e "${BOLD_WHITE}[*] HiddenParamFinder for $domain_name${NC}"

# Step 4.1: Preparing URLs with clean extensions
show_progress "Preparing URLs with clean extensions, created 2 files: arjun-urls.txt and output-php-links.txt"

# Extract all URLs with specific extensions into arjun-urls.txt and output-php-links.txt
cat "${domain_name}-links.txt" | grep -E "\.php($|\s|\?|&|#|/|\.)|\.asp($|\s|\?|&|#|/|\.)|\.aspx($|\s|\?|&|#|/|\.)|\.cfm($|\s|\?|&|#|/|\.)|\.jsp($|\s|\?|&|#|/|\.)" | \
awk '{print > "arjun-urls.txt"; print > "output-php-links.txt"}'
sleep 3

# Step 2: Clean parameters from URLs in arjun-urls.txt
show_progress "Filtering and cleaning arjun-urls.txt to remove parameters and duplicates"

# Clean parameters from URLs and save the cleaned version back to arjun-urls.txt
awk -F'?' '{print $1}' arjun-urls.txt | awk '!seen[$0]++' > temp_arjun_urls.txt

# Replace arjun-urls.txt with the cleaned file
mv temp_arjun_urls.txt arjun-urls.txt

show_progress "Completed cleaning arjun-urls.txt. All URLs are now clean, unique, and saved."

# Check if Arjun generated any files
if [ ! -s arjun-urls.txt ] && [ ! -s output-php-links.txt ]; then
    echo -e "${RED}Arjun did not find any new links or did not create any files.${NC}"
    echo -e "${BOLD_BLUE}Renaming ${domain_name}-links.txt to urls-ready.txt and continuing...${NC}"
    mv "${domain_name}-links.txt" urls-ready.txt || handle_error "Renaming ${domain_name}-links.txt"
    sleep 3
fi
    echo -e "${BOLD_BLUE}URLs prepared successfully and files created.${NC}"
    echo -e "${BOLD_BLUE}arjun-urls.txt and output-php-links.txt have been created.${NC}"

# Step 2: Running Arjun on clean URLs if arjun-urls.txt is present
if [ -s arjun-urls.txt ]; then
    show_progress "Running Arjun on clean URLs"
    arjun -i arjun-urls.txt -oT arjun_output.txt -t 10 -w parametri.txt || handle_error "Arjun command"

    # Merge files and process .php links
if [ -f arjun-urls.txt ] || [ -f output-php-links.txt ] || [ -f arjun_output.txt ]; then
    # Merge and extract only the base .php URLs, then remove duplicates
    cat arjun-urls.txt output-php-links.txt arjun_output.txt 2>/dev/null | awk -F'?' '/\.php/ {print $1}' | sort -u > arjun-final.txt

    echo -e "${BOLD_BLUE}arjun-final.txt created successfully with merged and deduplicated links.${NC}"
else
    echo -e "${YELLOW}No input files for merging. Skipping merge step.${NC}"
fi
sleep 5

        # Count the number of new links discovered by Arjun
        if [ -f arjun_output.txt ]; then
            new_links_count=$(wc -l < arjun_output.txt)
            echo -e "${BOLD_BLUE}Arjun has completed running on the clean URLs.${NC}"
            echo -e "${BOLD_RED}Arjun discovered ${new_links_count} new links.${NC}"
            echo -e "${CYAN}The new links discovered by Arjun are:${NC}"
            cat arjun_output.txt
        else
            echo -e "${YELLOW}No output file was created by Arjun.${NC}"
        fi
    else
        echo -e "${RED}No input file (arjun-urls.txt) found for Arjun.${NC}"
    fi

    # Continue with other steps or clean up
    show_progress "Cleaning up temporary files"
    if [[ -f arjun-urls.txt || -f arjun_output.txt || -f output-php-links.txt ]]; then
        [[ -f arjun-urls.txt ]] && rm -r arjun-urls.txt
        [[ -f output-php-links.txt ]] && rm -r output-php-links.txt
        sleep 3
    else
        echo -e "${RED}No Arjun files to remove.${NC}"
    fi

    echo -e "${BOLD_BLUE}Files merged and cleanup completed. Final output saved as arjun-final.txt.${NC}"

# Step 5: Creating a new file for XSS testing
if [ -f arjun-final.txt ]; then
    show_progress "Creating a new file for XSS testing"

    # Ensure arjun-final.txt is added to urls-ready.txt
    cat "${domain_name}-links.txt" arjun-final.txt > urls-ready1337.txt || handle_error "Creating XSS testing file"
    rm -r "${domain_name}-links.txt"
    mv urls-ready1337.txt "${domain_name}-links.txt"
    sleep 3
    mv "${domain_name}-links.txt" urls-ready.txt || handle_error "Renaming ${domain_name}-links.txt"
fi

# Function to run step 7 (Getting ready for XSS & URLs with query strings)
    echo -e "${BOLD_WHITE}Preparing for XSS Detection and Query String URL Analysis for $domain_name${NC}"

    # Step 1: Filtering URLs with query strings
    show_progress "Filtering URLs with query strings"
    grep '=' urls-ready.txt > "$domain_name-query.txt"
    sleep 5
    echo -e "${BOLD_BLUE}Filtering completed. Query URLs saved as ${domain_name}-query.txt.${NC}"

    # Step 2: Renaming the remaining URLs
    show_progress "Renaming remaining URLs"
    mv urls-ready.txt "$domain_name-ALL-links.txt"
    sleep 3
    echo -e "${BOLD_BLUE}All-links URLs saved as ${domain_name}-ALL-links.txt.${NC}"

    # Step 3: Analyzing and reducing the query URLs based on repeated parameters
show_progress "Analyzing query strings for repeated parameters"

# Start the analysis in the background and get the process ID (PID)
(> ibro-xss.txt; > temp_param_names.txt; > temp_param_combinations.txt; while read -r url; do base_url=$(echo "$url" | cut -d'?' -f1); extension=$(echo "$base_url" | grep -oiE '\.php|\.asp|\.aspx|\.cfm|\.jsp'); if [[ -n "$extension" ]]; then echo "$url" >> ibro-xss.txt; else params=$(echo "$url" | grep -oE '\?.*' | tr '?' ' ' | tr '&' '\n'); param_names=$(echo "$params" | cut -d'=' -f1); full_param_string=$(echo "$url" | cut -d'?' -f2); if grep -qx "$full_param_string" temp_param_combinations.txt; then continue; else new_param_names=false; for param_name in $param_names; do if ! grep -qx "$param_name" temp_param_names.txt; then new_param_names=true; break; fi; done; if $new_param_names; then echo "$url" >> ibro-xss.txt; echo "$full_param_string" >> temp_param_combinations.txt; for param_name in $param_names; do echo "$param_name" >> temp_param_names.txt; done; fi; fi; fi; done < "${domain_name}-query.txt"; echo "Processed URLs with unique parameters: $(wc -l < ibro-xss.txt)") &

# Save the process ID (PID) of the background task
analysis_pid=$!

# Monitor the process in the background
while kill -0 $analysis_pid 2> /dev/null; do
    echo -e "${BOLD_BLUE}Analysis tool is still running...⌛️${NC}"
    sleep 30  # Check every 30 seconds
done

# When finished
echo -e "${BOLD_GREEN}Analysis completed. $(wc -l < ibro-xss.txt) URLs with repeated parameters have been saved.${NC}"
rm temp_param_names.txt temp_param_combinations.txt
sleep 3

    # Step 4: Cleanup and rename the output file
    show_progress "Cleaning up intermediate files and setting final output"
    rm -r "${domain_name}-query.txt"
    mv ibro-xss.txt "${domain_name}-query.txt"
    echo -e "${BOLD_BLUE}Cleaned up and renamed output to ${domain_name}-query.txt.${NC}"
    sleep 3

# Step 4: Cleanup and rename the output file
show_progress "Cleaning up intermediate files and setting final output"

# Filter the file ${domain_name}-query.txt using the specified awk command
show_progress "Filtering ${domain_name}-query.txt for unique and normalized URLs"
awk '{ gsub(/^https:/, "http:"); gsub(/^http:\/\/www\./, "http://"); if (!seen[$0]++) print }' "${domain_name}-query.txt" | tr -d '\r' > "${domain_name}-query1.txt"

# Remove the old query file
rm -r "${domain_name}-query.txt"

# Rename the filtered file to the original name
mv "${domain_name}-query1.txt" "${domain_name}-query.txt"

# Count the number of URLs in the renamed file
url_count=$(wc -l < "${domain_name}-query.txt")

## Final message with progress count
echo -e "${BOLD_BLUE}Cleaned up and renamed output to ${domain_name}-query.txt.${NC}"
echo -e "${BOLD_BLUE}Total URLs to be tested for Page Reflection: ${url_count}${NC}"
sleep 3

# Add links from arjun_output.txt into ${domain_name}-query.txt
if [ -f "arjun_output.txt" ]; then
    echo -e "${BOLD_WHITE}Adding links from arjun_output.txt into ${domain_name}-query.txt.${NC}"
    cat arjun_output.txt >> "${domain_name}-query.txt"
    echo -e "${BOLD_BLUE}Links from arjun_output.txt added to ${domain_name}-query.txt.${NC}"
else
    echo -e "${YELLOW}No Arjun output links to add. Proceeding without additional links.${NC}"
fi

# Extract unique subdomains and append search queries
echo -e "${BOLD_WHITE}Processing unique subdomains to append search queries...${NC}"

# Define the list of search queries to append
search_queries=(
    "search?q=aaa"
    "?query=aaa"
    "en-us/Search#/?search=aaa"
    "Search/Results?q=aaa"
    "q=aaa"
    "search.php?query=aaa"
    "en-us/search?q=aaa"
    "s=aaa"
    "find?q=aaa"
    "result?q=aaa"
    "query?q=aaa"
    "search?term=aaa"
    "search?query=aaa"
    "search?keywords=aaa"
    "search?text=aaa"
    "search?word=aaa"
    "find?query=aaa"
    "result?query=aaa"
    "search?input=aaa"
    "search/results?query=aaa"
    "search-results?q=aaa"
    "search?keyword=aaa"
    "results?query=aaa"
    "search?search=aaa"
    "search?searchTerm=aaa"
    "search?searchQuery=aaa"
    "search?searchKeyword=aaa"
    "search.php?q=aaa"
    "search/?query=aaa"
    "search/?q=aaa"
    "search/?search=aaa"
    "search.aspx?q=aaa"
    "search.aspx?query=aaa"
    "search.asp?q=aaa"
    "index.asp?id=aaa"
    "dashboard.asp?user=aaa"
    "blog/search/?query=aaa"
    "pages/searchpage.aspx?id=aaa"
    "search.action?q=aaa"
    "search.json?q=aaa"
    "search/index?q=aaa"
    "lookup?q=aaa"
    "browse?q=aaa"
    "search-products?q=aaa"
    "products/search?q=aaa"
    "news?q=aaa"
    "articles?q=aaa"
    "content?q=aaa"
    "explore?q=aaa"
    "search/advanced?q=aaa"
    "search-fulltext?q=aaa"
    "products?query=aaa"
    "search?product=aaa"
    "catalog/search?q=aaa"
    "store/search?q=aaa"
    "shop?q=aaa"
    "items?query=aaa"
    "search?q=aaa&category=aaa"
    "store/search?term=aaa"
    "marketplace?q=aaa"
    "blog/search?q=aaa"
    "news?query=aaa"
    "articles?search=aaa"
    "topics?q=aaa"
    "stories?q=aaa"
    "newsfeed?q="
    "search-posts?q=aaa"
    "blog/posts?q=aaa"
    "search/article?q=aaa"
    "api/search?q=aaa"
    "en/search/explore?q=aaa"
    "bs-latn-ba/Search/Results?q=aaa"
    "en-us/marketplace/apps?search=aaa"
    "search/node?keys=aaaa"
    "v1/search?q=aaa"
    "api/v1/search?q=aaa"
)

# Extract unique subdomains (normalize to remove protocol and www)
normalized_subdomains=$(awk -F/ '{print $1 "//" $3}' "${domain_name}-query.txt" | sed -E 's~(https?://)?(www\.)?~~' | sort -u)

# Create a mapping of preferred protocols for unique subdomains
declare -A preferred_protocols
while read -r url; do
    # Extract protocol, normalize subdomain
    protocol=$(echo "$url" | grep -oE '^https?://')
    subdomain=$(echo "$url" | sed -E 's~(https?://)?(www\.)?~~' | awk -F/ '{print $1}')

    # Set protocol preference: prioritize http over https
    if [[ "$protocol" == "http://" ]]; then
        preferred_protocols["$subdomain"]="http://"
    elif [[ -z "${preferred_protocols["$subdomain"]}" ]]; then
        preferred_protocols["$subdomain"]="https://"
    fi
done < "${domain_name}-query.txt"

# Create a new file for the appended URLs
append_file="${domain_name}-query-append.txt"
> "$append_file"

# Append each search query to the preferred subdomains
for subdomain in $normalized_subdomains; do
    protocol="${preferred_protocols[$subdomain]}"
    for query in "${search_queries[@]}"; do
        echo "${protocol}${subdomain}/${query}" >> "$append_file"
    done
done

# Combine the original file with the appended file
cat "${domain_name}-query.txt" "$append_file" > "${domain_name}-query-final.txt"

# Replace the original file with the combined result
mv "${domain_name}-query-final.txt" "${domain_name}-query.txt"

echo -e "${BOLD_BLUE}Appended URLs saved and combined into ${domain_name}-query.txt.${NC}"

# Step 3: Checking page reflection on the URLs
if [ -f "reflection.py" ]; then
    echo -e "${BOLD_WHITE}Checking page reflection on the URLs with command: python3 reflection.py ${domain_name}-query.txt --threads 2${NC}"
    python3 reflection.py "${domain_name}-query.txt" --threads 2 || handle_error "reflection.py execution"
    sleep 5

    # Check if xss.txt is created after reflection.py
    if [ -f "xss.txt" ]; then
        # Check if xss.txt has any URLs (non-empty file)
        total_urls=$(wc -l < xss.txt)
        if [ "$total_urls" -eq 0 ]; then
            # If no URLs were found, stop the tool
            echo -e "\033[1;36mNo reflective URLs were identified. The process will terminate, and no further XSS testing will be conducted.\033[0m"
            exit 0
        else
            echo -e "${BOLD_WHITE}Page reflection done! New file created: xss.txt${NC}"

            # Display the number of URLs affected by reflection
            echo -e "${BOLD_WHITE}Total URLs reflected: ${RED}${total_urls}${NC}"

            # Filtering duplicate URLs
            echo -e "${BOLD_BLUE}Filtering duplicate URLs...${NC}"
            awk '{ gsub(/^https:/, "http:"); gsub(/^http:\/\/www\./, "http://"); if (!seen[$0]++) print }' "xss.txt" | tr -d '\r' > "xss1.txt"
            sleep 3

            # Remove the original xss.txt file
            echo -e "${BOLD_BLUE}Removing the old xss.txt file...${NC}"
            rm -rf xss.txt arjun_output.txt arjun-final.txt "${domain_name}-query-append.txt"
            sleep 3

            # Removing 99% similar parameters with bash command
            echo -e "${BOLD_BLUE}Removing 99% similar parameters...${NC}"
            awk -F'[?&]' '{gsub(/:80/, "", $1); base_url=$1; domain=base_url; params=""; for (i=2; i<=NF; i++) {split($i, kv, "="); if (!seen[domain kv[1]]++) {params=params kv[1]; if (i<NF) params=params "&";}} full_url=base_url"?"params; if (!param_seen[full_url]++) print $0 > "xss-urls.txt";}' xss1.txt
            sleep 5

            # Remove the intermediate xss1.txt file
            echo -e "${BOLD_BLUE}Removing the intermediate xss1.txt file...${NC}"
            rm -rf xss1.txt
            sleep 3

            # Running URO for xss-urls.txt file
            echo -e "${BOLD_BLUE}Running URO for xss-urls.txt file...${NC}"
            uro -i xss-urls.txt -o xss-urls1337.txt
            rm -r xss-urls.txt
            mv xss-urls1337.txt xss-urls.txt
            sleep 5

            # Final message with the total number of URLs in xss-urls.txt
            total_urls=$(wc -l < xss-urls.txt)
            echo -e "${BOLD_WHITE}New file is ready for XSS testing: xss-urls.txt with TOTAL URLs: ${total_urls}${NC}"
            echo -e "${BOLD_WHITE}Initial Total Merged URLs in the beginning : ${RED}${total_merged_urls}${NC}"
            echo -e "${BOLD_WHITE}Filtered Final URLs for XSS Testing: ${RED}${total_urls}${NC}"

        fi
    else
        echo -e "${RED}xss.txt not found. No reflective URLs identified.${NC}"
        echo -e "\033[1;36mNo reflective URLs were identified. The process will terminate, and no further XSS testing will be conducted.\033[0m"
        exit 0
    fi
else
    echo -e "${RED}reflection.py not found in the current directory. Skipping page reflection step.${NC}"
fi


