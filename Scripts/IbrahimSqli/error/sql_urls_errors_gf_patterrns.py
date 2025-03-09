import re
import subprocess
import time
from termcolor import colored

# Define list of words to filter URLs
filter_words = ["id=", "select=", "report=", "artist=", "ID=", "searchfor=", "item=", "search=", "message_id=", "follower_id=", "user_agent=", "cookie=", "referer=", "document_id=", "post_id=", "comment_id=", "event_id=", "booking_id=", "ticket_id=", "track_id=", "image_id=", "invoice_id=", "subscription_id=", "feedback=", "category_id=", "order_id=", "transaction_id=", "country=", "zipcode=", "product_id=", "redirect=", "callback=", "action=", "avg=", "insert_into=", "values=", "address=", "user_id=", "search_term=", "filter_by=", "group_by=", "union=", "offset=", "grad=", "kat=", "role=", "update=", "query=", "user=", "name=", "sort=", "where=", "search=", "params=", "process=", "row=", "view=", "table=", "from=", "sel=", "results=", "sleep=", "fetch=", "order=", "keyword=", "column=", "field=", "delete=", "string=", "number=", "filter="]

# Read URLs from file
with open('urls.txt', 'r') as f:
    urls = f.read().splitlines()

# Read payloads from file
with open('sql_wordlist.txt', 'r') as f:
    payloads = f.read().splitlines()

# Define SQL errors
sql_errors = ["Syntax error", "Fatal error", "MariaDB", "corresponds", "Database Error", "syntax", "/home/", "/usr/www", "occured", "public_html", "database error", "on line", "RuntimeException", "mysql_", "Warning", "MySQL", "PSQLException", "at line", "You have an error in your SQL syntax", "mysql_query()", "pg_connect()"]

# Define regex pattern to extract elapsed time from curl output
time_pattern = re.compile(r"elapsed (\d+:\d+\.\d+)")

total_requests = len(urls) * len(payloads)
progress = 0
start_time = time.time()

# Loop through each URL
for url in urls:
    # Check if URL contains any filter word
    if not any(filter_word in url for filter_word in filter_words):
        continue
    
    # Loop through each payload
    for payload in payloads:
        # Escape single quotes in the payload
        payload = payload.replace("'", "%27")

        # Test URL with payload and get source code
        for filter_word in filter_words:
            if filter_word in url:
                index = url.find(filter_word)
                end_index = url.find('&', index)
                if end_index == -1:
                    end_index = len(url)
                modified_url = url[:index + len(filter_word)] + payload + url[end_index:]
                command = ['curl', '-s', '-i', '--url', modified_url]
                try:
                    output_bytes = subprocess.check_output(command, stderr=subprocess.DEVNULL)
                except subprocess.CalledProcessError:
                    pass

                # Decode output from byte string to UTF-8 string
                output_str = output_bytes.decode('utf-8', errors='ignore')

                # Check for SQL errors and print message if so
                sql_matches = [error for error in sql_errors if error in output_str]
                if sql_matches:
                    message = f"\n{colored('SQL ERROR FOUND', 'white')} ON {colored(modified_url, 'red', attrs=['bold'])} with payload {colored(payload, 'white')}"
                    with open('sql_errors.txt', 'a') as file:
                        file.write(modified_url + payload + '\n')
                    for match in sql_matches:
                        print(colored(" Match Words: " + match, 'cyan'))
                    print(message)
                else:
                    # Print safe payloads in green text
                    print(colored(f"URL: {modified_url} | Payload: {payload} | Status: safe", 'green'))

        # Update progress and calculate estimated remaining time
        progress += 1
        elapsed_seconds = time.time() - start_time
        remaining_seconds = (total_requests - progress) * (elapsed_seconds / progress)
        remaining_hours = int(remaining_seconds // 3600)
        remaining_minutes = int((remaining_seconds % 3600) // 60)
        percent_complete = round(progress / total_requests * 100, 2)

    # Print progress update
    print(f"{colored('Progress:', 'blue')} {progress}/{total_requests} ({percent_complete}%) - {remaining_hours}h:{remaining_minutes:02d}m")