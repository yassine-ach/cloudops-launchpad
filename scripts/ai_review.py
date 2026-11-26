import json

with open("results.json") as f:
    data = json.load(f)

failed_checks= data['results']['failed_checks']


print(f"{len(failed_checks)} failed checks")
       
for failed in failed_checks:
    start = failed['file_line_range'][0]
    end = failed['file_line_range'][1]
    print(f"check_id= {failed['check_id']} | resource= {failed['resource']} | {failed['file_path']}:{start}-{end}")

with open("trivy-results.json") as f1:
    data1 = json.load(f1)

vuln_count = 0
for result in data1["Results"]:
    for vuln in result.get("Vulnerabilities", []):
        vuln_count +=1 
        print(f"VulnerabilityID= {vuln['VulnerabilityID']} | package name= {vuln['PkgName']} | {vuln['InstalledVersion']} -> {vuln['FixedVersion']} | Severity= {vuln['Severity']}")

print (f"{vuln_count} Vulnerabilities")

