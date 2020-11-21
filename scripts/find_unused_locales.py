from pathlib import Path
import re
import sys


def getEntries():
    keys = []
    with open("locales/enUS.lua") as f:
        for line in f.readlines():
            if line.strip().startswith("L["):
                m = re.match(r'L\["(.+)"\] ', line)
                if m and m.group(1):
                    keys.append(m.group(1))
    return keys


def findUses(entries, path):
    uses = dict.fromkeys(entries, 0)
    with open(path) as f:
        for line in f.readlines():
            for entry in entries:
                if entry in line:
                    uses[entry] += 1
    return uses


def findUnused(entries):
    totalUses = dict.fromkeys(entries, 0)
    paths = ["Bindings.lua"]
    paths.extend(str(p) for p in Path("src").rglob("*.lua"))
    for path in paths:
        uses = findUses(entries, path)
        for k in uses.keys():
            totalUses[k] += uses[k]
    return [e for e in totalUses.keys() if totalUses[e] == 0]


# Get entries.
print("Retrieving entries...", end=" ")
entries = getEntries()
print(f"{len(entries)} found.")

# Find unused entries.
print("Searching for unused entries...", end=" ")
unusedEntries = findUnused(entries)
if len(unusedEntries) == 0:
    print("none found.")
else:
    print(f"{len(unusedEntries)} found:")
    for key in unusedEntries:
        print(f"  {key}")
    sys.exit(1)
