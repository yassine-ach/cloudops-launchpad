import json
def read_checkov(path):
   
    with open(path) as f:
        data = json.load(f)
    return data['results']['failed_checks']
checks = read_checkov("results.json")
print(f"{len(checks)} failed checks")

for check in checks:
    start = check['file_line_range'][0]
    end = check['file_line_range'][1]
    print(f"{check['check_id']} | {check['resource']} | {check['file_path']}:{start}-{end}") 


with open("trivy-results.json") as f1:
    data1 = json.load(f1)

vuln_count = 0
for result in data1["Results"]:
    for vuln in result.get("Vulnerabilities", []):
        vuln_count +=1 
        print(f"VulnerabilityID= {vuln['VulnerabilityID']} | package name= {vuln['PkgName']} | {vuln['InstalledVersion']} -> {vuln['FixedVersion']} | Severity= {vuln['Severity']}")

print(f"{vuln_count} Vulnerabilities")

