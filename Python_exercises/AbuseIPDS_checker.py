from pathlib import Path
import requests
import json
import re


BASE_DIR = Path(__file__).resolve().parent
ip_path = BASE_DIR / "example_data" / "ips.txt"
abuseipdb_API_KEY_path = BASE_DIR / "credentials" / "AbuseIPDB_API_KEY.txt"

ABUSEIPDB_API_KEY = open(abuseipdb_API_KEY_path).read().strip()

url = 'https://api.abuseipdb.com/api/v2/check'

def check_ip(ip_address):
    querystring = {
        'ipAddress': ip_address,
        'maxAgeInDays': '90'
    }

    headers = {
        'Accept': 'application/json',
        'Key': ABUSEIPDB_API_KEY
    }

    response = requests.request(method='GET', url=url, headers=headers, params=querystring)

    # Formatted output
    decodedResponse = json.loads(response.text)
    print(json.dumps(decodedResponse, sort_keys=True, indent=4))





with open(ip_path) as ip_file:
    ips = []
    for line in ip_file:
        ips.extend(re.findall(r"[^,\s;]+", line))   # Not a comma, whitespace, or semicolon

for ip in ips:
    check_ip(ip)