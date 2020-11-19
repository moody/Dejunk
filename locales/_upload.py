import json
import os
import requests
import sys

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


def getLocales():
    with open("locales/enUS.lua", encoding="utf-8") as f:
        return parse(f.readlines())


def getCurseLocales():
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


# Get locales.
print("Retrieving locales...")
locales = getLocales()

# Get locales from Curse.
print("Retrieving Curse locales...")
curseLocales = getCurseLocales()

# Upload unchanged locales so that any changed locales are deleted.
print("Uploading unchanged locales...")
upload([x for x in locales if x in curseLocales])

# Upload all locales.
print("Uploading all locales...")
upload(locales)

print("Success!")
