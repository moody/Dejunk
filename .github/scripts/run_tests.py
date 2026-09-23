from pathlib import Path
import subprocess
import sys

results = []
for path in sorted(Path("test").rglob("*-tests.lua")):
    result = subprocess.run(["lua", str(path)], capture_output=True, text=True)
    results.append((path.as_posix(), result))

failures = [(path, result) for path, result in results if result.returncode != 0]

for path, result in results:
    status = "FAIL" if result.returncode != 0 else "PASS"
    print(f"[{status}]: {path}")

for path, result in failures:
    print(f"\n{'=' * 60}")
    print(f"[FAIL]: {path}")
    print(f"{'=' * 60}")
    print(f"{result.stdout}{result.stderr}".rstrip())

total = len(results)
numFailed = len(failures)
numPassed = total - numFailed

print(f"\n{'-' * 60}")
print(f"[Test Results]: {numPassed} passed, {numFailed} failed, {total} total\n")

if numFailed > 0:
    sys.exit(1)
