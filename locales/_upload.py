import json
import os
import requests
import sys


API_KEY = os.getenv("CF_API_KEY")
assert API_KEY

LOCALE_ENTRY_PREFIX = "L["
PROJECT_ID = "413260"
API_ENDPOINT = f"https://wow.curseforge.com/api/projects/{PROJECT_ID}/localization/import?token={API_KEY}"


# Get localizations
print("Retrieving locale entries...")
localizations = ""

with open("locales/enUS.lua") as f:
    entries = []

    for line in f.readlines():
        if line.startswith(LOCALE_ENTRY_PREFIX):
            print(f"  {line.split('=')[0]}")
            entries.append(line)

    localizations = "".join(entries)
    print(f"\nRetrieved {len(entries)} locale entries.\n")


# Upload to CurseForge
print("Uploading to CurseForge...")

payload = {
    "metadata": json.dumps(
        {"language": "enUS", "missing-phrase-handling": "DeletePhrase"}
    ),
    "localizations": localizations,
}

r = requests.post(url=API_ENDPOINT, data=payload)

if r.ok:
    print("Success!")
else:
    print(r.text)
    sys.exit(1)
