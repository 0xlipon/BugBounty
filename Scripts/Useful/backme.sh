#!/bin/bash

# Prompt user to define the target
read -p "Please enter the target (e.g., example.com): " target

# Check if the target is empty
if [ -z "$target" ]; then
  echo "Error: No target provided. Exiting..."
  exit 1
fi

# ╭─────────────────────╮
# |         GOSPIDER    |
# ╰─────────────────────╮

echo "[*] Running GOSPIDER scan on https://${target} ..."
gospider -s "https://${target}" \
  --user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36" \
  --quiet --depth 5 --concurrent 20 --threads 40 --delay 1 --random-delay 1 --timeout 10 \
  --js --robots --other-source --include-subs --include-other-source --subs --sitemap \
  --no-redirect --raw | anew gospider.txt

# ╭─────────────────────╮
# |         CRAWLEY     |
# ╰─────────────────────╮

echo "[*] Running CRAWLEY scan on https://${target} ..."
crawley -all -user-agent "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36" \
  -subdomains -headless -depth -1 -silent -skip-ssl -workers 50 -timeout 10s -robots crawl https://${target} | anew crawley.txt

# ╭─────────────────────╮
# |         CARIDDI     |
# ╰─────────────────────╮

echo "[*] Running CARIDDI scan on https://${target} ..."
echo https://${target} | cariddi -s -d 2 -c 200 -e -ext 7 -cache -t 10 -intensive -rua -err -info | anew cariddi.txt

# ╭─────────────────────╮
# |         GAU         |
# ╰─────────────────────╮

echo "[*] Running GAU scan on ${target} ..."
echo ${target} | gau --providers wayback,commoncrawl,otx,urlscan --retries 2 --subs --threads 100 --timeout 10 | anew gau.txt

# ╭─────────────────────╮
# |         GAUPLUS     |
# ╰─────────────────────╮

echo "[*] Running GAUPLUS scan on ${target} ..."
echo ${target} | gauplus -random-agent -subs -retries 2 -t 100 -providers wayback,otx,commoncrawl | anew gauplus.txt

# ╭─────────────────────╮
# |     hakrawler       |
# ╰─────────────────────╮

echo "[*] Running hakrawler scan on https://www.${target} ..."
echo "https://www.${target}" | hakrawler -d 5 -dr -insecure -t 10 -timeout 3600 -subs | tee hakrawler.txt

# ╭─────────────────────╮
# |     KATANA PASSIVE  |
# ╰─────────────────────╮

echo "[*] Running KATANA PASSIVE scan on ${target} ..."
echo "${target}" | katana -passive -jc -jsl -fx -xhr -kf all -c 50 -silent | anew katana_passive.txt

# ╭─────────────────────╮
# |    KATANA ACTIVE    |
# ╰─────────────────────╮

echo "[*] Running KATANA ACTIVE (Depth-First) scan on ${target} ..."
echo "${target}" | katana -d 5 -jc -ct 1h -aff -fx -s depth-first -c 50 -silent | anew katana_df.txt

# ╭─────────────────────╮
# |    KATANA ACTIVE    |
# ╰─────────────────────╮

echo "[*] Running KATANA ACTIVE (Breadth-First) scan on ${target} ..."
echo "${target}" | katana -d 5 -jc -ct 1h -aff -fx -s breadth-first -c 50 -silent | anew katana_bf.txt

# ╭─────────────────────╮
# |     WAYBACKURLS     |
# ╰─────────────────────╮

echo "[*] Running WAYBACKURLS scan on ${target} ..."
echo "${target}" | waybackurls | egrep -v "^[[:blank:]]*$" | anew waybackurls.txt

# ╭─────────────────────╮
# |     WAYMORE         |
# ╰─────────────────────╮

echo "[*] Running WAYMORE scan on ${target} ..."
echo "${target}" | waymore -i ${target} -mode U --retries 3 --timeout 10 --memory-threshold 95 --processes 5 --config ~/.config/waymore/config.yml --output-urls waymore.txt

# Final message indicating the completion of the scanning
echo "[*] All scans completed for ${target} successfully!"
