#!/usr/bin/env bash
BOLD_BLUE="\033[1;34m"
RED="\033[0;31m"
NC="\033[0m"
BOLD_YELLOW="\033[1;33m"

# arjun with multi domain

if [[ $UID -eq 0 ]]; then

    banner(){
        echo -e "\e[1;34m██╗     ██╗███╗   ██╗██╗  ██╗███████╗██╗███╗   ██╗██████╗ ███████╗██████╗ \e[0m"
        echo -e "\e[1;34m██║     ██║████╗  ██║██║ ██╔╝██╔════╝██║████╗  ██║██╔══██╗██╔════╝██╔══██╗\e[0m"
        echo -e "\e[1;34m██║     ██║██╔██╗ ██║█████╔╝ █████╗  ██║██╔██╗ ██║██║  ██║█████╗  ██████╔╝\e[0m"
        echo -e "\e[1;34m██║     ██║██║╚██╗██║██╔═██╗ ██╔══╝  ██║██║╚██╗██║██║  ██║██╔══╝  ██╔══██╗\e[0m"
        echo -e "\e[1;34m███████╗██║██║ ╚████║██║  ██╗██║     ██║██║ ╚████║██████╔╝███████╗██║  ██║\e[0m"
        echo -e "\e[1;34m╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝╚═╝     ╚═╝╚═╝  ╚═══╝╚═════╝ ╚══════╝╚═╝  ╚═╝\e[0m"
    }
    banner
    # Function to display usage message
    display_usage() {
        echo ""
        echo "Options:"
        echo "     -h               Display this help message"
        echo "     -d               Single Domain link Spidering"
        echo "     -l               Multi Domain link Spidering"
        echo "     -ml              Path of urls to link Spidering"
        echo "     -i               Check required tool installed or not."
        echo -e "${BOLD_YELLOW}Usage:${NC}"
        echo -e "${BOLD_YELLOW}    sudo $0 -d http://example.com${NC}"
        echo -e "${BOLD_YELLOW}    sudo $0 -l http://example.com${NC}"
        echo -e "${BOLD_YELLOW}    sudo $0 -ml path/to/subdomains.txt${NC}"
        echo -e "${RED}Required Tools:${NC}"
        echo -e "              ${RED}https://github.com/tomnomnom/qsreplace
                https://github.com/lc/gau
                https://github.com/tomnomnom/waybackurls
                https://github.com/xnl-h4ck3r/waymore
                https://github.com/projectdiscovery/katana
                https://github.com/bhunterex/reflection
                https://github.com/bhunterex/Pattern-Matching
                https://github.com/tomnomnom/anew
                https://github.com/projectdiscovery/urlfinder
                https://github.com/bhunterex/matcher${NC}"
        exit 0
    }

    # Function to check installed tools
    check_tools() {
        tools=("gau" "waymore" "waybackurls" "katana" "urlfinder" "reflection" "anew" "qsreplace" "match" "pm")

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

    # Function to handle errors
    handle_error() {
        echo -e "${RED}Error occurred during the execution of ${NC}${BOLD_BLUE}$1.${NC} ${RED}Exiting.${NC}"
        echo "Error during: $1" >> error.log
        exit 1
    }

    # help function execution
    if [[ "$1" == "-h" ]]; then
        display_usage
        exit 0
    fi

    # multi domain url getting
    if [[ "$1" == "-l" ]]; then
        # removing protocols
        domain_Without_Protocol=$(echo "$2" | sed 's,http://,,;s,https://,,;s,www\.,,;')
        # making directory
        main_dir="bug_hunting_report/$domain_Without_Protocol"
        base_dir="$main_dir/single_domain/recon/urls"
        trash_dir="$base_dir/trash_files"
        sudo mkdir -p $main_dir
        if [[ $? -ne 1 ]]; then
            echo -e "${BOLD_YELLOW}🌐 Multi Domain URLs collecting${NC}"
            echo -e "${BOLD_YELLOW}📁 Directory created successfully: ${NC}${BOLD_BLUE}$main_dir${NC}"
        else
            echo -e "${RED}❌ Directory making failed${NC}"
        fi
        sudo mkdir -p $base_dir
        sudo mkdir -p $trash_dir

        # directory permission read, write, execute
        sudo chmod -R 777 $main_dir
        if [[ $? -ne 1 ]]; then
            echo -e "${BOLD_YELLOW}🔓 All permission grant for above created directory${NC}"
        else
            echo -e "${RED}❌ Permission denied${NC}"
        fi

        # urlfinder url collecting
        sleep 1
        echo -e "${BOLD_YELLOW}🛠️  Urlfinder tool running, please wait....⏳${NC}"
        urlfinder -all -d "$domain_Without_Protocol" -silent -o $base_dir/urlfinder.txt || handle_error "urlfinder execution problem"
        if [[ $? -eq 0 ]]; then
            echo -e "${BOLD_YELLOW}🛠️  Urlfinder completed ✅${NC}"
            sleep 3
        else
            echo -e "${RED}❌ urlfinder failed${NC}"
        fi

        # waymore url collecting
        sleep 1
        echo -e "${BOLD_YELLOW}🛠️  waymore tool running, please wait....⏳${NC}"
        waymore -i "$domain_Without_Protocol" -mode U --providers wayback,otx,urlscan,virustotal -oU $base_dir/waymore.txt || handle_error "waymore execution problem"
        if [[ $? -eq 0 ]]; then
            echo -e "${BOLD_YELLOW}🛠️  Waymore completed ✅${NC}"
            sleep 3
        else
            echo -e "${RED}❌ waymore failed${NC}"
        fi

        # katana url collecting
        sleep 1
        echo -e "${BOLD_YELLOW}🛠️ katana tool running, please wait....⏳${NC}"
        katana -u "$domain_Without_Protocol" -rl 170 -timeout 5 -retry 2 -aff -d 4 -duc -ps -pss waybackarchive,commoncrawl,alienvault -silent -o $base_dir/katana.txt || handle_error "katana execution problem"
        if [[ $? -eq 0 ]]; then
            echo -e "${BOLD_YELLOW}🛠️  katana completed ✅${NC}"
            # cat $base_dir/katana.txt | tee /dev/tty | wc -l
            sleep 3
        else
            echo -e "${RED}❌ katana failed${NC}"
        fi

        # gau url collecting
        sleep 1
        echo -e "${BOLD_YELLOW}🛠️  gau tool running, please wait....⏳${NC}"
        gau "$domain_Without_Protocol" --subs --providers wayback,commoncrawl,otx,urlscan --o $base_dir/gau.txt || handle_error "gau execution problem"
        if [[ $? -eq 0 ]]; then
            echo -e "${BOLD_YELLOW}🛠️  gau completed ✅${NC}"
            # cat $base_dir/gau.txt | tee /dev/tty | wc -l
            sleep 3
        else
            echo -e "${RED}❌ gau failed${NC}"
        fi

        # waybackurls url collecting
        sleep 1
        echo -e "${BOLD_YELLOW}🛠️  waybackurls tool running, please wait....⏳${NC}"
        waybackurls "$domain_Without_Protocol" > $base_dir/waybackurls.txt || handle_error "waybackurls execution problem"
        if [[ $? -eq 0 ]]; then
            echo -e "${BOLD_YELLOW}🛠️  waybackurls completed ✅${NC}"
            # cat $base_dir/waybackurls.txt | tee /dev/tty | wc -l
            sleep 3
        else
            echo -e "${RED}❌ waybackurls failed${NC}"
        fi

        echo -e "${BOLD_YELLOW}🏁 All urls finding finished 🏁${NC}"
        echo ""
        # urlfinder tool url counting
        if [[ -f "$base_dir/urlfinder.txt" ]]; then
            urlfinder_file=$(cat $base_dir/urlfinder.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 urlfinder urls found:${NC} ${RED}$urlfinder_file${NC}"
            sleep 3
        else
            basename $base_dir/urlfinder.txt
            echo -e "${RED}❌ $basename file not found.${NC}"
        fi

        # waymore tool url counting
        if [[ -f "$base_dir/waymore.txt" ]]; then
            waymore_file=$(cat $base_dir/waymore.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 waymore urls found:${NC} ${RED}$waymore_file${NC}"
            sleep 3
        else
            basename $base_dir/waymore.txt
            echo -e "${RED}❌ $basename file not found.${NC}"
        fi

        # katana tool url counting
        if [[ -f "$base_dir/katana.txt" ]]; then
            katana_file=$(cat $base_dir/katana.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 katana urls found:${NC} ${RED}$katana_file${NC}"
            sleep 3
        else
            basename $base_dir/katana.txt
            echo -e "${RED}❌ $basename file not found.${NC}"
        fi

        # gau tool url counting
        if [[ -f "$base_dir/gau.txt" ]]; then
            gau_file=$(cat $base_dir/gau.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 gau urls found:${NC} ${RED}$gau_file${NC}"
            sleep 3
        else
            basename $base_dir/gau.txt
            echo -e "${RED}❌ $basename file not found.${NC}"
        fi

        # waybackurls tool url counting
        if [[ -f "$base_dir/waybackurls.txt" ]]; then
            waybackurls_file=$(cat $base_dir/gau.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 waybackurls urls found:${NC} ${RED}$waybackurls_file${NC}"
            sleep 3
            echo ""
        else
            basename $base_dir/waybackurls.txt
            echo -e "${RED}❌ $basename file not found.${NC}"
        fi

        # urlfinder file filtering by uro
        uro -i $base_dir/urlfinder.txt -o $base_dir/urlfinder_uro.txt || handle_error "uro problem with urlfinder"
        if [[ $? -eq 0 ]]; then
            urlfinder_file_filter_uro=$(cat $base_dir/urlfinder_uro.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 After filtered by uro, now urlfinder urls are:${NC} ${RED}$urlfinder_file_filter_uro${NC}"
            sleep 3
        else
            basename $base_dir/urlfinder.txt
            echo -e "${RED}❌ uro not work properly or $basename file not found.${NC}"
        fi

        # waymore file filtering by uro
        uro -i $base_dir/waymore.txt -f hasparams -o $base_dir/waymore_uro.txt || handle_error "uro problem with waymore"
        if [[ $? -eq 0 ]]; then
            waymore_file_filter_uro=$(cat $base_dir/waymore_uro.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 After filtered by uro, now waymore urls are:${NC} ${RED}$waymore_file_filter_uro${NC}"
            sleep 3
        else
            basename $base_dir/waymore.txt
            echo -e "${RED}❌ uro not work properly or $basename file not found.${NC}"
        fi

        # katana file filtering by uro
        uro -i $base_dir/katana.txt -f hasparams -o $base_dir/katana_uro.txt || handle_error "uro problem with katana"
        if [[ $? -eq 0 ]]; then
            katana_file_filter_uro=$(cat $base_dir/katana_uro.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 After filtered by uro, now katana urls are:${NC} ${RED}$katana_file_filter_uro${NC}"
            sleep 3
        else
            basename $base_dir/katana.txt
            echo -e "${RED}❌ uro not work properly or $basename file not found.${NC}"
        fi

        # gau file filtering by uro
        uro -i $base_dir/gau.txt -f hasparams -o $base_dir/gau_uro.txt || handle_error "uro problem with gau"
        if [[ $? -eq 0 ]]; then
            gau_file_filter_uro=$(cat $base_dir/gau_uro.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 After filtered by uro, now gau urls are:${NC} ${RED}$gau_file_filter_uro${NC}"
            sleep 3
        else
            basename $base_dir/gau.txt
            echo -e "${RED}❌ uro not work properly or $basename file not found.${NC}"
        fi

        # waybackurls file filtering by uro
        uro -i $base_dir/waybackurls.txt -f hasparams -o $base_dir/waybackurls_uro.txt || handle_error "uro problem with waybackurls"
        if [[ $? -eq 0 ]]; then
            waybackurls_file_filter_uro=$(cat $base_dir/waybackurls_uro.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 After filtered by uro, now waybackurls urls are:${NC} ${RED}$waybackurls_file_filter_uro${NC}"
            sleep 3
        else
            basename $base_dir/waybackurls.txt
            echo -e "${RED}❌ uro not work properly or $basename file not found.${NC}"
        fi

        # all files merging
        cat $base_dir/urlfinder.txt $base_dir/waymore.txt $base_dir/katana.txt $base_dir/gau.txt $base_dir/waybackurls.txt | anew > $base_dir/all_unique_urls.txt || handle_error "All urls merging problem"
        if [[ $? -eq 0 ]]; then
            # count merging old file
            all_merging_old_url_count=$(cat $base_dir/urlfinder.txt $base_dir/waymore.txt $base_dir/katana.txt $base_dir/gau.txt $base_dir/waybackurls.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 All old urls are: ${NC} ${RED}$all_merging_old_url_count${NC}"
            sleep 1

            # Deleting anew old files
            echo -e "${BOLD_BLUE} Deleting old files${NC}${RED}(urlfinder.txt, waymore.txt, gau.txt, katana.txt, waybackurls.txt).${NC}"
            sudo mv $base_dir/urlfinder.txt $base_dir/waymore.txt $base_dir/katana.txt $base_dir/gau.txt $base_dir/waybackurls.txt $trash_dir
            echo ""
        else
            echo -e "${RED}❌ All urls merging failed.${NC}"
        fi


        # all uro files merging
        cat $base_dir/urlfinder_uro.txt $base_dir/waymore_uro.txt $base_dir/katana_uro.txt $base_dir/gau_uro.txt $base_dir/waybackurls_uro.txt | anew > $base_dir/all_uro_unique_urls.txt || handle_error "uro merging problem"
        if [[ $? -eq 0 ]]; then
            # count merging old file
            uro_merging_url_count=$(cat $base_dir/urlfinder_uro.txt $base_dir/waymore_uro.txt $base_dir/katana_uro.txt $base_dir/gau_uro.txt $base_dir/waybackurls_uro.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 Uro merging all old urls are: ${NC} ${RED}$uro_merging_url_count${NC}"
            sleep 1

            # count total uro merging unique urls
            uro_merging_unique_url_count=$(cat $base_dir/all_uro_unique_urls.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍✅ Uro unique urls are:${NC} ${RED}$uro_merging_unique_url_count${NC}"
            sleep 1

            # Deleting uro old files
            echo -e "${BOLD_BLUE} Deleting old files${NC}${RED}(urlfinder_uro.txt, waymore_uro.txt, gau_uro.txt, katana_uro.txt, waybackurls_uro.txt).${NC}"
            sudo mv $base_dir/urlfinder_uro.txt $base_dir/waymore_uro.txt $base_dir/katana_uro.txt $base_dir/gau_uro.txt $base_dir/waybackurls_uro.txt $trash_dir
            echo ""
        else
            echo -e "${RED}❌ All file merging failed.${NC}"
        fi

         # deleting javascript files from parameter urls
        cat $base_dir/all_uro_unique_urls.txt | grep -avE '\.js($|\s|\?|&|#|/|\.)|\.json($|\s|\?|&|#|/|\.)\.css($|\s|\?|&|#|/|\.)' | anew > $base_dir/get_params2.txt || handle_error "Javascript urls deteting problem"

        # matching only parameters by equal(=) sign
        cat $base_dir/get_params2.txt | qsreplace -a "FUZZ" | match -p "FUZZ" -r -v -o $base_dir/get_params3.txt || handle_error "qsreplace get params problem"
        if [[ $? -eq 0 ]]; then
            # count parameter urls after delete javascript urls
            get_params3=$(cat $base_dir/get_params3.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 qsreplace based get parameters are: ${NC} ${RED}$get_params3${NC}"
            sleep 1
        else
            echo -e "${RED}❌ qsreplace get params failed.${NC}"
        fi

        pm -f $base_dir/get_params2.txt -p /opt/Pattern-Matching/patterns/xss.txt -c -o $base_dir/get_params4.txt || handle_error "Pattern Matching get params problem"
        if [[ $? -eq 0 ]]; then
            # count parameter urls after delete javascript urls
            get_params4=$(cat $base_dir/get_params4.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 Pattern Matching based get parameters are: ${NC} ${RED}$get_params4${NC}"
            sleep 1
        else
            echo -e "${RED}❌ Pattern Matching get params failed.${NC}"
        fi

        # Final get parameters
        cat $base_dir/get_params3.txt $base_dir/get_params4.txt | anew > $base_dir/final_get_params.txt || handle_error "final get params problem"
        if [[ $? -eq 0 ]]; then
            # count final get parameter urls
            final_get_params=$(cat $base_dir/final_get_params.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 Final get parameters are: ${NC} ${RED}$final_get_params${NC}"
            sleep 1

            # Deleting old parameter files
            echo -e "${BOLD_BLUE} Deleting old files${NC}${RED}(get_params2.txt, get_params3.txt, get_params4.txt).${NC}"
            sudo mv $base_dir/get_params2.txt $base_dir/get_params3.txt $base_dir/get_params4.txt $trash_dir
            echo ""
        else
            echo -e "${RED}❌ Final get params failed.${NC}"
        fi

        # hidden parameter finding
        # reducing unwanted extensions
        cat $base_dir/all_uro_unique_urls.txt | grep -a -E -v '\.css($|\s|\?|&|#|/|\.)|\.js($|\s|\?|&|#|/|\.)|\.jpg($|\s|\?|&|#|/|\.)|\.JPG($|\s|\?|&|#|/|\.)|\.PNG($|\s|\?|&|#|/|\.)|\.GIF($|\s|\?|&|#|/|\.)|\.avi($|\s|\?|&|#|/|\.)|\.dll($|\s|\?|&|#|/|\.)|\.pl($|\s|\?|&|#|/|\.)|\.webm($|\s|\?|&|#|/|\.)|\.c($|\s|\?|&|#|/|\.)|\.py($|\s|\?|&|#|/|\.)|\.bat($|\s|\?|&|#|/|\.)|\.tar($|\s|\?|&|#|/|\.)|\.swp($|\s|\?|&|#|/|\.)|\.tmp($|\s|\?|&|#|/|\.)|\.sh($|\s|\?|&|#|/|\.)|\.deb($|\s|\?|&|#|/|\.)|\.exe($|\s|\?|&|#|/|\.)|\.zip($|\s|\?|&|#|/|\.)|\.mpeg($|\s|\?|&|#|/|\.)|\.mpg($|\s|\?|&|#|/|\.)|\.flv($|\s|\?|&|#|/|\.)|\.wmv($|\s|\?|&|#|/|\.)|\.wma($|\s|\?|&|#|/|\.)|\.aac($|\s|\?|&|#|/|\.)|\.m4a($|\s|\?|&|#|/|\.)|\.ogg($|\s|\?|&|#|/|\.)|\.mp4($|\s|\?|&|#|/|\.)|\.mp3($|\s|\?|&|#|/|\.)|\.bat($|\s|\?|&|#|/|\.)|\.dat($|\s|\?|&|#|/|\.)|\.cfg($|\s|\?|&|#|/|\.)|\.cfm($|\s|\?|&|#|/|\.)|\.bin($|\s|\?|&|#|/|\.)|\.jpeg($|\s|\?|&|#|/|\.)|\.JPEG($|\s|\?|&|#|/|\.)|\.ps.gz($|\s|\?|&|#|/|\.)|\.gz($|\s|\?|&|#|/|\.)|\.gif($|\s|\?|&|#|/|\.)|\.tif($|\s|\?|&|#|/|\.)|\.tiff($|\s|\?|&|#|/|\.)|\.csv($|\s|\?|&|#|/|\.)|\.png($|\s|\?|&|#|/|\.)|\.ttf($|\s|\?|&|#|/|\.)|\.ppt($|\s|\?|&|#|/|\.)|\.pptx($|\s|\?|&|#|/|\.)|\.ppsx($|\s|\?|&|#|/|\.)|\.doc($|\s|\?|&|#|/|\.)|\.woff($|\s|\?|&|#|/|\.)|\.xlsx($|\s|\?|&|#|/|\.)|\.xls($|\s|\?|&|#|/|\.)|\.mpp($|\s|\?|&|#|/|\.)|\.mdb($|\s|\?|&|#|/|\.)|\.json($|\s|\?|&|#|/|\.)|\.woff2($|\s|\?|&|#|/|\.)|\.icon($|\s|\?|&|#|/|\.)|\.pdf($|\s|\?|&|#|/|\.)|\.docx($|\s|\?|&|#|/|\.)|\.svg($|\s|\?|&|#|/|\.)|\.txt($|\s|\?|&|#|/|\.)|\.jar($|\s|\?|&|#|/|\.)|\.0($|\s|\?|&|#|/|\.)|\.1($|\s|\?|&|#|/|\.)|\.2($|\s|\?|&|#|/|\.)|\.3($|\s|\?|&|#|/|\.)|\.4($|\s|\?|&|#|/|\.)|\.m4r($|\s|\?|&|#|/|\.)|\.kml($|\s|\?|&|#|/|\.)|\.pro($|\s|\?|&|#|/|\.)|\.yao($|\s|\?|&|#|/|\.)|\.gcn3($|\s|\?|&|#|/|\.)|\.PDF($|\s|\?|&|#|/|\.)|\.egy($|\s|\?|&|#|/|\.)|\.par($|\s|\?|&|#|/|\.)|\.lin($|\s|\?|&|#|/|\.)|\.yht($|\s|\?|&|#|/|\.)' | anew > $base_dir/filtered_unwanted_extensions.txt
        echo -e "${BOLD_YELLOW}🔍 Filtered unwanted extensions.${NC}"

        cat $base_dir/filtered_unwanted_extensions.txt | 
        grep -aE "\.php($|\s|\?|&|#|/|\.)|\.asp($|\s|\?|&|#|/|\.)|\.aspx($|\s|\?|&|#|/|\.)|\.cfm($|\s|\?|&|#|/|\.)|\.jsp($|\s|\?|&|#|/|\.)|\.jspx($|\s|\?|&|#|/|\.)" | \
        awk -v dir="$base_dir" '{print > dir"/arjun_ready_urls1.txt"; print > dir"/other_php_links.txt"}' || 
        handle_error "filter and extract php, jsp, asp extensions problem"
        echo -e "${BOLD_YELLOW}🔍 Filtered specific extensions like (php, asp, aspx, jsp, jspx, cfm).${NC}"

        # Remove noise from specified extension
        cat $base_dir/arjun_ready_urls1.txt | awk -F'?' '{print $1}' | awk '!seen[$0]++' > $base_dir/arjun_ready_urls2.txt || handle_error "Noise removing awk problem"
        echo -e "${BOLD_YELLOW}🔍 Remove noise from specified extensions.${NC}"
        sleep 5
        subprober -f $base_dir/arjun_ready_urls2.txt -sc -nc -mc 200 201 202 204 301 302 304 307 308 403 500 504 401 407 -c 100 -o $base_dir/arjun_ready_urls3.txt
        echo -e "${BOLD_YELLOW}🛠️  subprober completed ✅${NC}"

        echo -e "${BOLD_YELLOW}🔍 Ready only urls for match tool.${NC}"
        cat $base_dir/arjun_ready_urls3.txt | awk '{print $1}' | anew > $base_dir/arjun_ready_urls4.txt || handle_error "get and post params merging problem"

        echo -e "${BOLD_YELLOW}🛠️  match tool running, please wait....⏳${NC}"
        match -f $base_dir/arjun_ready_urls4.txt -p "http" -r -v -o $base_dir/arjun_ready_urls5.txt || handle_error "web port filtering problem"
        echo -e "${BOLD_YELLOW}🛠️  match completed ✅${NC}"

        sleep 1
        arjun -i $base_dir/arjun_ready_urls5.txt -oT $base_dir/arjun_output.txt -w /usr/share/wordlists/payloads/hidden-params.txt || handle_error "Arjun command problem"
        echo -e "${BOLD_YELLOW}🛠️  arjun completed ✅${NC}"
        echo ""

        # merging get and post params
        cat $base_dir/final_get_params.txt $base_dir/arjun_output.txt | anew > $base_dir/final_get_post_params1.txt || handle_error "get and post params 1 merging problem"
        if [[ $? -eq 0 ]]; then
            # count final get post parameter urls
            final_get_post_params1=$(cat $base_dir/final_get_post_params1.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 Final get, post parameters are: ${NC} ${RED}$final_get_post_params1${NC}"
            sleep 1
            echo ""
        else
            echo -e "${RED}❌ Final get post params failed.${NC}"
        fi

        # live params finding
        subprober -f $base_dir/final_get_post_params1.txt -sc -nc -mc 200 201 202 204 301 302 304 307 308 403 500 504 401 407 -c 100 -o $base_dir/final_get_post_live_params2.txt

        cat $base_dir/final_get_post_live_params2.txt | awk '{print $1}' | anew > $base_dir/final_get_post_live_params.txt || handle_error "Final get and post params merging problem"
        if [[ $? -eq 0 ]]; then
            # count final get post live parameter urls
            # Deleting old get post parameter files
            echo -e "${BOLD_BLUE} Deleting old files${NC}"
            sudo mv $base_dir/filtered_unwanted_extensions.txt $base_dir/arjun_ready_urls1.txt $base_dir/arjun_ready_urls2.txt $base_dir/arjun_ready_urls3.txt $base_dir/other_php_links.txt $base_dir/arjun_ready_urls4.txt $base_dir/arjun_output.txt $base_dir/final_get_post_params1.txt $base_dir/final_get_post_live_params2.txt $base_dir/arjun_ready_urls5.txt $trash_dir
        else
            echo -e "${RED}❌ Final get post live params failed.${NC}"
        fi

        match -f $base_dir/final_get_post_live_params.txt -p "http" -r -v -o $base_dir/final_get_post_live_params1.txt
        echo -e "${BOLD_YELLOW}🔍 Ready urls for reflection tool${NC}"

        reflection -f $base_dir/final_get_post_live_params1.txt -p "FUZZ" -o $base_dir/all_reflected_params1.txt
        if [[ $? -eq 0 ]]; then
            # all parameter urls after filtering
            cat $base_dir/all_reflected_params1.txt | sed 's/FUZZ.*$/FUZZ/' | sed 's/FUZZ//g' | anew > $base_dir/all_reflected_params.txt
            all_params_url_path=$base_dir/all_reflected_params.txt
            all_params_url_count=$(cat $base_dir/all_reflected_params.txt | wc -l)
            echo -e "${BOLD_YELLOW}🔍 reflection completed${NC}"
            echo ""
        else
            echo -e "${RED}❌ no reflected parameter found.${NC}"
        fi

        pm -f $base_dir/final_get_post_live_params1.txt -c -r "XSS" -p /opt/Pattern-Matching/patterns/xss.txt -o $base_dir/excerpt_reflected_live_params.txt
        echo -e "${BOLD_YELLOW}🔍 GF parameters found${NC}"

        pm -f $base_dir/final_get_post_live_params1.txt -r "SQLI" -p /opt/Pattern-Matching/patterns/sqli.txt -o $base_dir/sqli_live_params.txt
        echo -e "${BOLD_YELLOW}🔍 SQLi parameters found${NC}"

        pm -f $base_dir/final_get_post_live_params1.txt -c -r "OPENREDIRECT" -p /opt/Pattern-Matching/patterns/or.txt -o $base_dir/or_live_params.txt
        echo -e "${BOLD_YELLOW}🔍 Open redirect parameters found${NC}"

        pm -f $base_dir/final_get_post_live_params1.txt -c -r "LFI" -p /opt/Pattern-Matching/patterns/lfi.txt -o $base_dir/lfi_live_params.txt
        echo -e "${BOLD_YELLOW}🔍 lfi parameters found${NC}"
        sudo mv $base_dir/final_get_post_live_params1.txt $base_dir/all_reflected_params1.txt $trash_dir

        # make this condition final
        # All urls printing
        anew_merging_unique_url_path=$base_dir/all_unique_urls.txt
        anew_merging_unique_url_count=$(cat $base_dir/all_unique_urls.txt | wc -l)
        echo -e "${BOLD_YELLOW}🔍 ✅ All unique urls are${NC}(${RED}$anew_merging_unique_url_count${NC}): ${BOLD_BLUE}$anew_merging_unique_url_path${NC}"


        # All live parameters printing
        final_get_post_live_params_path=$base_dir/final_get_post_live_params.txt
        final_get_post_live_params=$(cat $base_dir/final_get_post_live_params.txt | wc -l)
        echo -e "${BOLD_YELLOW}🔍✅ Final get, post live parameters are${NC}(${RED}$final_get_post_live_params${NC}): ${BOLD_BLUE}$final_get_post_live_params_path${NC}"
        sleep 1

        # GF live parameters
        GF_live_params_path=$base_dir/excerpt_reflected_live_params.txt
        GF_live_params_count=$(cat $base_dir/excerpt_reflected_live_params.txt | wc -l)
        echo -e "${BOLD_YELLOW}🔍✅ GF live parameters are${NC}(${RED}$GF_live_params_count${NC}): ${BOLD_BLUE}$GF_live_params_path${NC}"
        sleep 1

        # Reflected live parameters
        rxss_live_params_path=$base_dir/all_reflected_params.txt
        rxss_live_params_count=$(cat $base_dir/all_reflected_params.txt | wc -l)
        echo -e "${BOLD_YELLOW}🔍✅ Reflected live parameters are${NC}(${RED}$rxss_live_params_count${NC}): ${BOLD_BLUE}$rxss_live_params_path${NC}"
        sleep 1

        # SQLi live parameters
        sqli_live_params_path=$base_dir/sqli_live_params.txt
        sqli_live_params_count=$(cat $base_dir/sqli_live_params.txt | wc -l)
        echo -e "${BOLD_YELLOW}🔍✅ SQLi live parameters are${NC}(${RED}$sqli_live_params_count${NC}): ${BOLD_BLUE}$sqli_live_params_path${NC}"
        sleep 1

        # Open redirect live parameters
        or_live_params_path=$base_dir/or_live_params.txt
        or_live_params_count=$(cat $base_dir/or_live_params.txt | wc -l)
        echo -e "${BOLD_YELLOW}🔍✅ Open redirect live parameters are${NC}(${RED}$or_live_params_count${NC}): ${BOLD_BLUE}$or_live_params_path${NC}"
        sleep 1

        # lfi live parameters
        lfi_live_params_path=$base_dir/lfi_live_params.txt
        lfi_live_params_count=$(cat $base_dir/lfi_live_params.txt | wc -l)
        echo -e "${BOLD_YELLOW}🔍✅ lfi live parameters are${NC}(${RED}$lfi_live_params_count${NC}): ${BOLD_BLUE}$lfi_live_params_path${NC}"
        sleep 1

        sudo chmod -R 777 $base_dir

        exit 0
    fi
else
    echo -e "Must run with${BOLD_YELLOW} sudo ${NC}privillage"
    echo -e "${BOLD_YELLOW}Usage:${NC}"
    echo -e "${BOLD_YELLOW}    sudo $0 -d http://example.com${NC}"
    echo -e "${BOLD_YELLOW}    sudo $0 -l http://example.com${NC}"
    echo -e "${BOLD_YELLOW}    sudo $0 -ml path/to/subdomains.txt${NC}"
    exit 0
fi
