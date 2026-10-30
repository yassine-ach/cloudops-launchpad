import argparse
import sys
import requests

parser = argparse.ArgumentParser(description="access url")
parser.add_argument("--url", required=True)
parser.add_argument("--timeout", type=int, default=5)
args = parser.parse_args()

def check(url, timeout):
    try:
        r = requests.get(url,timeout = timeout)
        if r.status_code != 200:
            return False, f"FAIL: {url} status {r.status_code}"
        body = r.json()
        stat =body.get("status")

        if stat != "ok":
            return False, f"FAIL: {url} status value {stat}"
        return True, f"PASS: {url}"
        
      
    except requests.exceptions.JSONDecodeError:
        return False, f"FAIL: {url} body not json"
    
    except requests.exceptions.RequestException as e :
        return False, f"FAIL: {url} no answer: {e}"
    

if __name__ == "__main__":
    ok, message = check(args.url, args.timeout)
    print(message)
    if not ok: 
        sys.exit(1)
    sys.exit(0)