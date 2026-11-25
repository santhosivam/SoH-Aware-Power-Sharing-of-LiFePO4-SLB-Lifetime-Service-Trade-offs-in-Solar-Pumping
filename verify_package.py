"""Verify the SHA-256 inventory for this public simulation folder."""
from pathlib import Path
import hashlib
import sys

root = Path(__file__).resolve().parent
manifest = root / "SHA256_MANIFEST.txt"
files = sorted(p for p in root.rglob("*") if p.is_file()
               and not ({".git", "slprj", "__pycache__"} & set(p.relative_to(root).parts))
               and p != manifest
               and p.suffix.lower() not in {".slxc", ".pyc"})
expected = "\n".join(
    f"{hashlib.sha256(p.read_bytes()).hexdigest()}  {p.relative_to(root).as_posix()}"
    for p in files
) + "\n"
if "--write" in sys.argv:
    manifest.write_text(expected, encoding="utf-8")
    print(f"Wrote {len(files)} SHA-256 entries")
else:
    assert manifest.read_text(encoding="utf-8") == expected, "Package manifest mismatch"
    print(f"Verified {len(files)} SHA-256 entries")
