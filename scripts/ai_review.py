import json


def read_checkov(path):
    with open(path) as f:
        data = json.load(f)
    return data["results"]["failed_checks"]


def read_trivy(path):
    with open(path) as f:
        data = json.load(f)

    vulns = []
    for result in data["Results"]:
        for vuln in result.get("Vulnerabilities", []):
            vulns.append(vuln)
    return vulns


def minimal_checkov(check):
    return {
        "id": check["check_id"],
        "name": check["check_name"],
        "resource": check["resource"],
    }


def minimal_trivy(vuln):
    return {
        "id": vuln["VulnerabilityID"],
        "package": vuln["PkgName"],
        "installed_version": vuln["InstalledVersion"],
        "fixed_version": vuln.get("FixedVersion", "no fix available"),
        "severity": vuln["Severity"],
        "title": vuln.get("Title", "no title"),
    }


def main():
    checks = read_checkov("results.json")
    print(f"{len(checks)} failed checks")
    for check in checks:
        m = minimal_checkov(check)
        start = check["file_line_range"][0]
        end = check["file_line_range"][1]
        print(f"{m['id']} | {m['resource']} | {check['file_path']}:{start}-{end}")

    vulns = read_trivy("trivy-results.json")
    print(f"{len(vulns)} vulnerabilities")
    for vuln in vulns:
        m = minimal_trivy(vuln)
        print(f"{m['id']} | {m['package']} | {m['installed_version']} -> {m['fixed_version']} | {m['severity']}")


if __name__ == "__main__":
    main()