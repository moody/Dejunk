import os
import requests


PROJECT_ID = "257636"
API_KEY = os.getenv("CF_API_KEY")

assert API_KEY

API_ENDPOINT = f"https://wow.curseforge.com/api/projects/{PROJECT_ID}/localization/import?token={API_KEY}"


# Get localizations
localizations = ""

with open("locales/enUS.lua") as f:
    entries = []

    for line in f.readlines():
        if "L[" in line:
            entries.append(line)

    localizations = "".join(entries)


# POST to CurseForge
payload = {
    "metadata": {"language": "enUS", "missing-phrase-handling": "DeletePhrase"},
    "localizations": localizations,
}

requests.post(url=API_ENDPOINT, data=payload)
