from pathlib import Path
import re
import sys


LOCALE_ENTRY_PATTERN = re.compile(r'L\["(.+)"\] ')
LOCALE_REFERENCE_PATTERN = re.compile(r"\bL\.(\w+)\b")


def getEntries():
    entries = []

    with open("locales/enUS.lua") as f:
        for line in f.readlines():
            if line.strip().startswith("L["):
                m = re.match(LOCALE_ENTRY_PATTERN, line)
                if m and m.group(1):
                    entries.append(m.group(1))

    return entries


def getReferences():
    references = {}

    paths = ["Bindings.lua"]
    paths.extend(str(p) for p in Path("src").rglob("*.lua"))

    for path in paths:
        with open(path) as f:
            lineNum = 0
            for line in f.readlines():
                lineNum += 1
                match = re.search(LOCALE_REFERENCE_PATTERN, line)
                if match:
                    for key in match.groups():
                        if not key in references:
                            references[key] = []
                        references[key].append(f"{path} (line: {lineNum})")

    return references


# Get entries.
print("Retrieving entries...", end=" ")
entries = getEntries()
print(f"{len(entries)} found.")

# Get references.
print("Retrieving references...", end=" ")
references = getReferences()
print(f"{len(references)} found.")

# Find unused entries.
print("\nChecking for unused entries...", end=" ")
unusedEntries = [e for e in entries if e not in references.keys()]
if len(unusedEntries) == 0:
    print("none found.")
else:
    print(f"{len(unusedEntries)} found:")
    for key in unusedEntries:
        print(f"  {key}")

# Find undefined references.
print("\nChecking for undefined references...", end=" ")
undefinedReferences = [e for e in references.keys() if e not in entries]
if len(undefinedReferences) == 0:
    print("none found.")
else:
    print(f"{len(undefinedReferences)} found:")
    for key in undefinedReferences:
        print(f"  {key}:")
        for path in references[key]:
            print(f"    {path}")

# Exit with an error if any unused entries or undefined references were found.
if len(unusedEntries) > 0 or len(undefinedReferences) > 0:
    sys.exit(1)
