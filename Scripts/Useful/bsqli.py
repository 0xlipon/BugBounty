#!/usr/bin/env python3
import os
import requests
import time
import concurrent.futures
import random
import argparse
import logging

class Color:
    BLUE = '\033[94m'
    GREEN = '\033[1;92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    PURPLE = '\033[95m'
    RESET = '\033[0m'

class BSQLI:
    USER_AGENTS = [
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Version/14.1.2 Safari/537.36",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Edge/91.0.864.70",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Firefox/89.0",
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:91.0) Gecko/20100101 Firefox/91.0",
        "Mozilla/5.0 (Macintosh; Intel Mac OS X 10.15; rv:91.0) Gecko/20100101 Firefox/91.0",
        "Mozilla/5.0 (Linux; Android 10; SM-G973F) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36",
        "Mozilla/5.0 (Linux; Android 11; Pixel 5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.77 Mobile Safari/537.36",
    ]

    def __init__(self, verbose=False):
        self.vulnerabilities_found = 0
        self.total_tests = 0
        self.verbose = verbose
        self.vulnerable_urls = []
        logging.basicConfig(filename='error_log.txt', level=logging.ERROR)

    def get_random_user_agent(self):
        return random.choice(self.USER_AGENTS)

    def perform_request(self, base_url, modified_query, payload, cookie):
        request_url = f"{base_url}?{modified_query}"
        start_time = time.time()
        headers = {'User-Agent': self.get_random_user_agent()}
        try:
            response = requests.get(request_url, headers=headers, cookies={'cookie': cookie} if cookie else None)
            response.raise_for_status()
            response_time = time.time() - start_time
            success = True
        except requests.exceptions.RequestException as e:
            response_time = time.time() - start_time
            success = False
            return success, request_url, response_time, None, str(e)
        return success, request_url, response_time, response.status_code, None

    def read_file(self, path):
        try:
            with open(path) as file:
                return [line.strip() for line in file if line.strip()]
        except Exception as e:
            print(f"{Color.RED}Error reading file {path}: {e}{Color.RESET}")
            return []

    def save_vulnerable_urls(self, filename):
        try:
            with open(filename, 'w') as file:
                for url in self.vulnerable_urls:
                    file.write(f"{url}\n")
            print(f"{Color.GREEN}Vulnerable URLs saved to {filename}{Color.RESET}")
        except Exception as e:
            print(f"{Color.RED}Error saving vulnerable URLs to file: {e}{Color.RESET}")

    def scan_url(self, url, payload, cookie):
        try:
            base_url, query_string = url.split('?', 1)
        except ValueError:
            base_url = url
            query_string = ''

        pairs = query_string.split('&')
        for i in range(len(pairs)):
            if '=' in pairs[i]:
                key, value = pairs[i].split('=', 1)
                modified_pairs = pairs.copy()
                modified_pairs[i] = f"{key}={payload}"
                modified_query = '&'.join(modified_pairs)
                success, request_url, response_time, status_code, error_message = self.perform_request(base_url, modified_query, payload, cookie)
                self.total_tests += 1
                self.log_result(success, request_url, response_time, status_code)

    def run_scan(self, urls, payloads, cookie, threads):
        try:
            if threads == 0:
                for url in urls:
                    for payload in payloads:
                        self.scan_url(url, payload, cookie)
            else:
                with concurrent.futures.ThreadPoolExecutor(max_workers=threads) as executor:
                    futures = [executor.submit(self.scan_url, url, payload, cookie) for url in urls for payload in payloads]
                    for future in concurrent.futures.as_completed(futures):
                        future.result()
        except KeyboardInterrupt:
            print(f"{Color.YELLOW}Scan interrupted by user.{Color.RESET}")

    def log_result(self, success, url_with_payload, response_time, status_code):
        if success and status_code and response_time >= 10:
            self.vulnerabilities_found += 1
            self.vulnerable_urls.append(url_with_payload)
            if self.verbose:
                print(f"{Color.GREEN}✓ SQLi Found! URL: {url_with_payload} - Response Time: {response_time:.2f} seconds - Status Code: {status_code}{Color.RESET}")
            else:
                print(f"{Color.GREEN}✓ Vulnerable URL: {url_with_payload}{Color.RESET}")
        else:
            if self.verbose:
                print(f"{Color.RED}✗ Not Vulnerable: {url_with_payload} - Response Time: {response_time:.2f} seconds - Status Code: {status_code}{Color.RESET}")

def main():
    parser = argparse.ArgumentParser(description="BSQLI Tool - One Line Command Tool")
    parser.add_argument('-u', '--urls', type=str, required=True, help="Path to URL list file or a single URL")
    parser.add_argument('-p', '--payloads', type=str, required=True, help="Path to the payload file")
    parser.add_argument('-c', '--cookie', type=str, default="", help="Cookie to include in GET request")
    parser.add_argument('-t', '--threads', type=int, default=0, help="Number of concurrent threads (0-10)")
    parser.add_argument('-o', '--save', type=str, default="", help="Filename to save vulnerable URLs")
    parser.add_argument('-v', '--verbose', action='store_true', help="Enable verbose mode")
    parser.add_argument('-V', '--version', action='version', version='BSQLI Tool 1.0')

    args = parser.parse_args()

    scanner = BSQLI(verbose=args.verbose)

    urls = [args.urls] if not os.path.isfile(args.urls) else scanner.read_file(args.urls)
    if not urls:
        print(f"{Color.RED}No valid URLs provided.{Color.RESET}")
        return

    payloads = scanner.read_file(args.payloads)
    if not payloads:
        print(f"{Color.RED}No valid payloads found in file: {args.payloads}{Color.RESET}")
        return

    print(f"{Color.PURPLE}Starting scan...{Color.RESET}")
    scanner.run_scan(urls, payloads, args.cookie, args.threads)

    print(f"\n{Color.BLUE}Scan Complete.{Color.RESET}")
    print(f"{Color.YELLOW}Total Tests: {scanner.total_tests}{Color.RESET}")
    print(f"{Color.GREEN}BSQLi Found: {scanner.vulnerabilities_found}{Color.RESET}")

    if args.save:
        scanner.save_vulnerable_urls(args.save)

if __name__ == "__main__":
    main()
