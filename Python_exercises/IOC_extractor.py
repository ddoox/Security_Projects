from pathlib import Path
import re
import collections


# TODO: Valid IPs, uniq, defanged 
ip_pattern = re.compile(r'(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)')


def ip_extract_from_file(file_path):
    IP_dict = collections.defaultdict(int)
    with open (file_path) as file:
        for line in file:
            results = re.findall(ip_pattern, line)
            for result in results:
                IP_dict[result] += 1
    sorted_IP_dict = sorted(IP_dict.items(), key=lambda x: x[1], reverse=True)
    return(sorted_IP_dict)





BASE_DIR = Path(__file__).resolve().parent
file_path = BASE_DIR / "example_data" / "sample_IOCs.txt"


ips = []
IP_dict = collections.defaultdict(int)

with open (file_path) as file:
    for line in file:
        results = re.findall(ip_pattern, line)
        ips.extend(re.findall(ip_pattern, line))
        print(f'Line result = {results}')
        for result in results:
            print(f'Line result loop = {result}')
            IP_dict[result] += 1

print()
print()
print()

print(ips)
print()
print(IP_dict)
print()
sorted_IP_dict = sorted(IP_dict.items(), key=lambda x: x[1], reverse=True)
print()
print(sorted_IP_dict)
print("function: ")
print(ip_extract_from_file(file_path))