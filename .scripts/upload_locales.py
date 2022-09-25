import json
import os
import requests

API_KEY = os.getenv("CF_API_KEY")
assert API_KEY

API_ENDPOINT = "https://wow.curseforge.com/api/projects/413260/localization"
IMPORT_URL = f"{API_ENDPOINT}/import?token={API_KEY}"
IMPORT_METADATA = json.dumps(
    {"language": "enUS", "missing-phrase-handling": "DeletePhrase"}
)


def parse(lines):
    entries = []
    for line in lines:
        line = line.strip()
        if line.startswith("L."):
            entries.append(line)
    return entries


def getEntries():
    with open("src/locale.lua", encoding="utf-8") as f:
        return parse(f.readlines())


def upload(localizations):
    localizations = "\n".join(localizations)

    r = requests.post(
        url=IMPORT_URL,
        data={"metadata": IMPORT_METADATA, "localizations": localizations},
    )

    if not r.ok:
        raise Exception(r.text)


# Get entries.
print("Retrieving entries...", end=" ")
entries = getEntries()
print(f"{len(entries)} entries retrieved.")

# Upload entries.
print(f"Uploading {len(entries)} entries:")
for k in entries:
    print(f"  {k}")
upload(entries)

print("Success!")
