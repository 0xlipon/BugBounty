#!/usr/bin/python3

import os
import requests
import sys
import subprocess
from urllib.parse import urlunsplit, urlsplit, parse_qs, urlencode, urlparse, urlunparse, quote
import asyncio
from selenium.webdriver.chrome.service import Service
from concurrent.futures import ThreadPoolExecutor, as_completed
import random
import re
from colorama import Fore, Style, init
from time import sleep
from rich import print as rich_print
from rich.table import Table
from bs4 import BeautifulSoup
import urllib3
from prompt_toolkit import prompt
from prompt_toolkit.completion import PathCompleter
from requests.adapters import HTTPAdapter
from urllib3.util.retry import Retry
import argparse
import concurrent.futures
import time
import aiohttp
from selenium import webdriver
from selenium.webdriver.chrome.service import Service as ChromeService
from selenium.webdriver.common.by import By
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from webdriver_manager.chrome import ChromeDriverManager
from rich.console import Console
from selenium.common.exceptions import (TimeoutException, 
                                       UnexpectedAlertPresentException,
                                       NoAlertPresentException,
                                       WebDriverException)

# Suppress logging
import logging
from selenium.webdriver.remote.remote_connection import LOGGER
LOGGER.setLevel(logging.WARNING)
os.environ['WDM_LOG_LEVEL'] = '0'
os.environ['WDM_PRINT_FIRST_LINE'] = 'False'

class Color:
    BLUE = '\033[94m'
    GREEN = '\033[1;92m'
    YELLOW = '\033[93m'
    RED = '\033[91m'
    PURPLE = '\033[95m'
    CYAN = '\033[96m'
    RESET = '\033[0m'
    ORANGE = '\033[38;5;208m'
    BOLD = '\033[1m'
    UNBOLD = '\033[22m'
    ITALIC = '\033[3m'
    UNITALIC = '\033[23m'

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

init(autoreset=True)

def configure_driver():
    """Configure and return a reusable Chrome Service instance"""
    chrome_service = Service(ChromeDriverManager().install())

    chrome_options = Options()
    chrome_options.add_argument("--headless=new")
    chrome_options.add_argument("--disable-gpu")
    chrome_options.add_argument("--no-sandbox")
    chrome_options.add_argument("--disable-dev-shm-usage")
    chrome_options.add_argument("--ignore-certificate-errors")
    chrome_options.add_argument("--ignore-ssl-errors")
    chrome_options.add_argument("--log-level=3")
    chrome_options.add_experimental_option('excludeSwitches', ['enable-logging'])

    # Performance optimizations
    chrome_options.add_argument("--disable-extensions")
    chrome_options.add_argument("--disable-notifications")
    chrome_options.add_argument("--disable-browser-side-navigation")
    chrome_options.add_argument("--dns-prefetch-disable")

    return chrome_service, chrome_options

def run_xss_scanner(urls, scan_state=None):
    urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)
    logging.getLogger('WDM').setLevel(logging.ERROR)
    logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
    console = Console()

    from concurrent.futures import ThreadPoolExecutor, as_completed
    from queue import Queue
    from threading import Lock

    driver_pool = Queue()
    driver_lock = Lock()

    def load_payloads(payload_file):
        try:
            with open(payload_file, "r") as file:
                return [line.strip() for line in file if line.strip()]
        except Exception as e:
            print(Fore.RED + f"[!] Error loading payloads: {e}")
            os._exit(0)

    def generate_payload_urls(url, payload):
        url_combinations = []
        scheme, netloc, path, query_string, fragment = urlsplit(url)
        if not scheme:
            scheme = 'http'
        query_params = parse_qs(query_string, keep_blank_values=True)
        for key in query_params.keys():
            modified_params = query_params.copy()
            modified_params[key] = [payload]
            modified_query_string = urlencode(modified_params, doseq=True)
            modified_url = urlunsplit((scheme, netloc, path, modified_query_string, fragment))
            url_combinations.append(modified_url)
        return url_combinations

    def create_driver():
        chrome_options = Options()
        chrome_options.add_argument("--headless")
        chrome_options.add_argument("--no-sandbox")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-gpu")
        chrome_options.add_argument("--disable-extensions")
        chrome_options.add_argument("--disable-dev-shm-usage")
        chrome_options.add_argument("--disable-browser-side-navigation")
        chrome_options.add_argument("--disable-infobars")
        chrome_options.add_argument("--disable-notifications")
        chrome_options.page_load_strategy = 'eager'
        logging.disable(logging.CRITICAL)

        driver_service = Service(ChromeDriverManager().install())
        return webdriver.Chrome(service=driver_service, options=chrome_options)

    def get_driver():
        try:
            return driver_pool.get_nowait()
        except:
            with driver_lock:
                return create_driver()

    def return_driver(driver):
        driver_pool.put(driver)

    def check_vulnerability(url, payload, vulnerable_urls, total_scanned, timeout, scan_state):
        driver = get_driver()
        try:
            payload_urls = generate_payload_urls(url, payload)
            if not payload_urls:
                return

            for payload_url in payload_urls:
                try:
                    driver.get(payload_url)
                    total_scanned[0] += 1

                    try:
                        alert = WebDriverWait(driver, timeout).until(EC.alert_is_present())
                        alert_text = alert.text

                        if alert_text:
                            result = Fore.GREEN + f"[✓]{Fore.CYAN} Vulnerable:{Fore.GREEN} {payload_url} {Fore.CYAN} - Alert Text: {alert_text}"
                            print(result)
                            vulnerable_urls.append(payload_url)
                            if scan_state:
                                scan_state['vulnerability_found'] = True
                                scan_state['vulnerable_urls'].append(payload_url)
                                scan_state['total_found'] += 1
                            alert.accept()
                        else:
                            result = Fore.RED + f"[✗]{Fore.CYAN} Not Vulnerable:{Fore.RED} {payload_url}"
                            print(result)

                    except TimeoutException:
                        print(Fore.RED + f"[✗]{Fore.CYAN} Not Vulnerable:{Fore.RED} {payload_url}")

                    except UnexpectedAlertPresentException:
                        pass
                except Exception as e:
                    print(Fore.RED + f"[!] Error accessing {payload_url}: {e}")
        finally:
            return_driver(driver)

    def run_scan(urls, payload_file, timeout, scan_state):
        payloads = load_payloads(payload_file)
        vulnerable_urls = []
        total_scanned = [0]

        for _ in range(3):
            driver_pool.put(create_driver())

        try:
            with ThreadPoolExecutor(max_workers=2) as executor:
                futures = []
                for url in urls:
                    for payload in payloads:
                        futures.append(
                            executor.submit(
                                check_vulnerability,
                                url,
                                payload,
                                vulnerable_urls,
                                total_scanned,
                                timeout,
                                scan_state
                            )
                        )

                for future in as_completed(futures):
                    try:
                        future.result(timeout)
                    except Exception as e:
                        print(Fore.RED + f"[!] Error during scan: {e}")
        finally:
            while not driver_pool.empty():
                driver = driver_pool.get()
                driver.quit()

        return vulnerable_urls, total_scanned[0]

    def print_scan_summary(total_found, total_scanned, start_time):
        summary = [
            "→ Scanning finished.",
            f"• Total found: {Fore.GREEN}{total_found}{Fore.YELLOW}",
            f"• Total scanned: {total_scanned}",
            f"• Time taken: {int(time.time() - start_time)} seconds"
        ]
        for line in summary:
            print(Fore.YELLOW + line)

    # Execute scan with default parameters
    payload_file = "payloads.txt"
    timeout = 10
    start_time = time.time()
    vulnerable_urls, total_scanned = run_scan(urls, payload_file, timeout, scan_state)
    print_scan_summary(len(vulnerable_urls), total_scanned, start_time)

# Main Function
if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 xss-checker.py <urls_list>")
        sys.exit(1)

    urls = open(sys.argv[1]).read().splitlines()
    run_xss_scanner(urls)
