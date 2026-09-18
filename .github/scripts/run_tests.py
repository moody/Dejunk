from pathlib import Path
import subprocess
import sys

passed = 0
failed = 0

for path in sorted(Path("test").rglob("*-tests.lua")):
    result = subprocess.run(["lua", str(path)], capture_output=True, text=True)
    if result.returncode == 0:
        passed += 1
        print(f"[PASS]: {path.as_posix()}")
    else:
        failed += 1
        print(f"\n[FAIL]: {path.as_posix()}")
        print(f"{result.stdout}{result.stderr}")

print(f"\n{'-' * 60}")
print(f"[Test Results]: {passed} passed, {failed} failed, {passed + failed} total\n")

if failed > 0:
    sys.exit(1)
