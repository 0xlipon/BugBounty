import re
import subprocess
import time
from termcolor import colored

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
    # Find the last parameter in the URL
    last_param_match = re.search(r"&(\w+)=([^&]*)$", url)
    if last_param_match:
        last_param_name = last_param_match.group(1)
        last_param_value = last_param_match.group(2)

        # Loop through each payload
        for payload in payloads:
            # Escape single quotes in the payload
            payload = payload.replace("'", "%27")

            # Construct new URL with modified payload
            new_url = url.replace(f"&{last_param_name}={last_param_value}", f"&{last_param_name}={payload}")

            # Test new URL and get source code
            command = ['curl', '-s', '-i', '--url', new_url]
            try:
                output_bytes = subprocess.check_output(command, stderr=subprocess.DEVNULL)
            except subprocess.CalledProcessError:
                pass

            # Decode output from byte string to UTF-8 string
            output_str = output_bytes.decode('utf-8', errors='ignore')

            # Check for SQL errors and print message if so
            sql_matches = [error for error in sql_errors if error in output_str]
            if sql_matches:
                message = f"\n{colored('SQL ERROR FOUND', 'white')} ON {colored(url, 'red', attrs=['bold'])} with payload {colored(payload, 'white')}"
                with open('sql_errors.txt', 'a') as file:
                    file.write(url + payload + '\n')
                for match in sql_matches:
                    print(colored(" Match Words: " + match, 'cyan'))
                print(message)
            else:
                # Print safe payloads in green text
                print(colored(f"URL: {new_url} | Payload: {payload} | Status: safe", 'green'))

            # Update progress and calculate estimated remaining time
            progress += 1
            elapsed_seconds = time.time() - start_time
            remaining_seconds = (total_requests - progress) * (elapsed_seconds / progress)
            remaining_hours = int(remaining_seconds // 3600)
            remaining_minutes = int((remaining_seconds % 3600) // 60)
            percent_complete = round(progress / total_requests * 100, 2)

            # Print progress update
            print(f"{colored('Progress:', 'blue')} {progress}/{total_requests} ({percent_complete}%) - {remaining_hours}h:{remaining_minutes:02d}m")
