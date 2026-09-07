import re
import collections
from pathlib import Path

def extract_ip(text):
    ip_address = re.compile(r'(\d{1,3}\.){3}\d{1,3}')
    return ip_address.search(text).group()


BASE_DIR = Path(__file__).resolve().parent
path = BASE_DIR / "example_data" / "auth.log"


IP_dict = collections.defaultdict(int)

with open(path) as log_file:
    for line in log_file:
        if "Failed password" in line:
            ip = extract_ip(line)
            if "message repeated" in line:
                number_of_repeats = line.split()[7]
                IP_dict[ip] += int(number_of_repeats)
            else:
                IP_dict[ip] += 1

                
sorted_ips = sorted(IP_dict.items(), key=lambda x: x[1], reverse=True)
for counter in range(10):
    print(f"{sorted_ips[counter][1]} attempts from {sorted_ips[counter][0]}")