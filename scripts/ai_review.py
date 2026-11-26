import json

with open("results.json") as f:
    data = json.load(f)

failed_checks= data['results']['failed_checks']

print(f"{len(failed_checks)} failed checks")
       
for failed in failed_checks:
    print(f"check_id= {failed['check_id']} resource= {failed['resource']} file path= {failed['file_path']}")