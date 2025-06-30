import requests
import json

url = "http://192.168.12.1:1306/wifi"
headers = {"Content-Type": "application/json"}
data = {"uuid": "hotspot1", "password": "luna-rocks"}

response = requests.post(url, headers=headers, data=json.dumps(data))

print(response.status_code)
print(response.text)