from pathlib import Path
import sys
import xml.etree.ElementTree as ET


def getEntries():
    root = ET.parse("Dejunk.xml").getroot()
    return [script.get("file").replace("\\", "/") for script in root.iter("Script")]


def getLuaFiles():
    paths = list(Path(".").glob("*.lua"))
    for directory in ["libs", "src"]:
        paths.extend(Path(directory).rglob("*.lua"))
    return sorted(p.as_posix() for p in paths)


# Get entries.
print("Retrieving entries...", end=" ")
entries = getEntries()
print(f"{len(entries)} found.")

# Get Lua files.
print("Retrieving Lua files...", end=" ")
luaFiles = getLuaFiles()
print(f"{len(luaFiles)} found.")

# Find missing files.
existing = {p.as_posix() for p in Path(".").rglob("*") if p.is_file()}
print("\nChecking for missing files...", end=" ")
missingFiles = [e for e in dict.fromkeys(entries) if e not in existing]
if len(missingFiles) == 0:
    print("none found.")
else:
    print(f"{len(missingFiles)} found:")
    for entry in missingFiles:
        print(f"  {entry}")

# Find unreferenced Lua files.
print("\nChecking for unreferenced Lua files...", end=" ")
unreferencedFiles = [f for f in luaFiles if f not in entries]
if len(unreferencedFiles) == 0:
    print("none found.")
else:
    print(f"{len(unreferencedFiles)} found:")
    for file in unreferencedFiles:
        print(f"  {file}")

# Find duplicate entries.
print("\nChecking for duplicate entries...", end=" ")
duplicateEntries = sorted({e for e in entries if entries.count(e) > 1})
if len(duplicateEntries) == 0:
    print("none found.")
else:
    print(f"{len(duplicateEntries)} found:")
    for entry in duplicateEntries:
        print(f"  {entry}")


# Exit with an error if any problems were found.
if len(missingFiles) + len(unreferencedFiles) + len(duplicateEntries) > 0:
    sys.exit(1)
