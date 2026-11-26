import json
def read_checkov(path):
   
    with open(path) as f:
        data = json.load(f)
    return data['results']['failed_checks']

def read_trivy(path):
    with open(path) as f:
        data = json.load(f)

    vulns = []                                    
    for result in data["Results"]:
        for vuln in result.get("Vulnerabilities", []):
            vulns.append(vuln)                    
    return vulns 
def main():
    checks = read_checkov("results.json")
    print(f"{len(checks)} failed checks")

    for check in checks:
        start = check['file_line_range'][0]
        end = check['file_line_range'][1]
        print(f"{check['check_id']} | {check['resource']} | {check['file_path']}:{start}-{end}") 



                                    
    vulns = read_trivy("trivy-results.json")
    print(f"{len(vulns)} vulnerabilities")

    for vuln in vulns:
        print(f"{vuln['VulnerabilityID']} | {vuln['PkgName']} | {vuln['InstalledVersion']} -> {vuln['FixedVersion']} | {vuln['Severity']}")

if __name__ == "__main__":
    main()