import re
import subprocess
import time
from termcolor import colored
import requests
import chardet


# Read the list of URLs to test from a file
with open("urls.txt", "rb") as f:
    raw_data = f.read()
    result = chardet.detect(raw_data)
    encoding = result["encoding"]

with open("urls.txt", "r", encoding=encoding) as f:
    urls = [line.strip() for line in f.readlines()]


# Set the list of payloads to test
with open("sql_wordlist.txt", "r") as f:
    payloads = [line.strip() for line in f.readlines()]

# Iterate through each URL and payload
vulnerable_urls = []
total_requests = len(urls) * len(payloads)
progress = 0

for url in urls:
    for payload in payloads:
        try:
            # Construct the request URL with the payload
            request_url = url + payload

            # Send the request and measure the response time
            start_time = time.time()
            response = requests.get(request_url)
            end_time = time.time()

            # Check if the response time is greater than 15 seconds
            if end_time - start_time >= 15:
                # Highlight vulnerable URLs in red bold
                url_payload = re.sub(r":hacked$", "", request_url)
                print(colored(url_payload, 'red', attrs=['bold']) + colored(" hacked", 'white'))
                vulnerable_urls.append(request_url)
            else:
                # Print safe URLs in green text
                print(colored(f"{request_url} safe", 'green'))

            # Print elapsed time
            elapsed_time = round(end_time - start_time, 2)
            print(f"Elapsed time: {elapsed_time}s")

            # Update progress and calculate estimated remaining time
            progress += 1
            elapsed_seconds = time.time() - start_time
            remaining_seconds = (total_requests - progress) * (elapsed_seconds / progress)
            remaining_hours = int(remaining_seconds // 3600)
            remaining_minutes = int((remaining_seconds % 3600) // 60)
            percent_complete = round(progress / total_requests * 100, 2)

            # Print progress update
            print(f"{colored('Progress:', 'blue')} {progress}/{total_requests} ({percent_complete}%) - {remaining_hours}h:{remaining_minutes:02d}m")
        
        except KeyboardInterrupt:
            print("Program interrupted by user. Saving vulnerable URLs to file...")
            break
        
        except Exception as e:
            print(f"An error occurred: {e}. Saving vulnerable URLs to file...")
            break

# Save vulnerable URLs to file
with open("hack.txt", "w") as f:
    for url in vulnerable_urls:
        f.write(url + "\n")

print("Vulnerable URLs saved to file.")
