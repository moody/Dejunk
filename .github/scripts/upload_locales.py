import json
import os
import requests

API_KEY = os.getenv("CF_API_KEY")
assert API_KEY

API_ENDPOINT = "https://wow.curseforge.com/api/projects/413260/localization"
EXPORT_URL = f"{API_ENDPOINT}/export?token={API_KEY}"
IMPORT_URL = f"{API_ENDPOINT}/import?token={API_KEY}"
IMPORT_METADATA = json.dumps(
    {"language": "enUS", "missing-phrase-handling": "DeletePhrase"}
)


def parse(lines):
    entries = []
    for line in lines:
        line = line.strip()
        if line.startswith("L["):
            entries.append(line)
    return entries


def getEntries():
    with open("src/locale.lua", encoding="utf-8") as f:
        return parse(f.readlines())


def getCurseEntries():
    r = requests.get(url=EXPORT_URL)
    if r.ok:
        return parse(r.text.splitlines())
    else:
        raise Exception(r.text)


def upload(localizations):
    localizations = "\n".join(localizations)

    r = requests.post(
        url=IMPORT_URL,
        data={"metadata": IMPORT_METADATA, "localizations": localizations},
    )

    if not r.ok:
        raise Exception(r.text)


# Get local entries.
print("Retrieving local entries...", end=" ")
entries = getEntries()
print(f"{len(entries)} entries retrieved.")

# Get CurseForge entries.
print("Retrieving CurseForge entries...", end=" ")
curseEntries = getCurseEntries()
print(f"{len(curseEntries)} entries retrieved.")

# Get unchanged entries.
unchangedEntries = [x for x in entries if x in curseEntries]

# Upload unchanged entries, so that stale entries are deleted.
print(f"Uploading {len(unchangedEntries)} unchanged entries...", end=" ")
upload(unchangedEntries)
print("Done.")

# Upload all entries.
print(f"Uploading {len(entries)} local entries:")
for k in entries:
    print(f"  {k}")
upload(entries)

print("Success!")
