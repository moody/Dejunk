from pathlib import Path
import subprocess
import sys

# `loadfile` compiles a file without running it.
LUA_CHECK = """
for _, path in ipairs(arg) do
  local _, err = loadfile(path)
  if err then print(err) end
end
"""


def getLuaFiles():
    paths = list(Path(".").glob("*.lua"))
    paths.extend(Path("src").rglob("*.lua"))
    return sorted(p.as_posix() for p in paths)


# Get Lua files.
print("Retrieving Lua files...", end=" ")
luaFiles = getLuaFiles()
print(f"{len(luaFiles)} found.")

# Find syntax errors.
print("\nChecking for syntax errors...", end=" ")
result = subprocess.run(
    ["lua", "-", *luaFiles], input=LUA_CHECK, capture_output=True, text=True
)
errors = result.stdout.splitlines()

if result.returncode != 0 and len(errors) == 0:
    print(f"failed to run Lua:\n{result.stderr}")
    sys.exit(1)

if len(errors) == 0:
    print("none found.")
else:
    print(f"{len(errors)} found:")
    for error in errors:
        print(f"  {error}")


# Exit with an error if any syntax errors were found.
if len(errors) > 0:
    sys.exit(1)
