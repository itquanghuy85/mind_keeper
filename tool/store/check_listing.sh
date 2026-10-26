#!/usr/bin/env bash
# Kiểm giới hạn ký tự của nội dung trang cửa hàng (store/listing/*.md).
# Mỗi mục "## Tên (≤ N ...)" được đo số ký tự phần thân bên dưới.
#   bash tool/store/check_listing.sh
set -euo pipefail
cd "$(dirname "$0")/../.."
PYTHONIOENCODING=utf-8 python - <<'PY'
import glob
import re
import sys

bad = 0
for path in sorted(glob.glob("store/listing/*.md")):
    text = open(path, encoding="utf-8").read()
    for block in re.split(r"(?m)^## ", text)[1:]:
        head, _, body = block.partition("\n")
        m = re.search(r"≤\s*(\d+)", head)
        if not m:
            continue
        limit = int(m.group(1))
        body = body.strip()
        n = len(body)
        ok = n <= limit
        bad += 0 if ok else 1
        print(f"{'OK ' if ok else 'LỖI'} {path}: {head.strip()}: {n}/{limit}")
sys.exit(1 if bad else 0)
PY
