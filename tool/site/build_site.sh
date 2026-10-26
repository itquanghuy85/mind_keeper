#!/usr/bin/env bash
# Dựng site tĩnh (chính sách quyền riêng tư, điều khoản, hỗ trợ) từ thư mục site/
# bằng cách thay các biến {{...}} → thư mục đầu ra (mặc định build_site/).
#   CONTACT_EMAIL=ban@example.com DEVELOPER_NAME="Tên của bạn" \
#     bash tool/site/build_site.sh [thư_mục_đầu_ra]
# Địa chỉ liên hệ là thông tin CÔNG KHAI → do chủ ứng dụng tự cung cấp, không
# được commit sẵn trong mã nguồn.
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${CONTACT_EMAIL:?Cần đặt CONTACT_EMAIL (email liên hệ công khai trên chính sách)}"
: "${DEVELOPER_NAME:?Cần đặt DEVELOPER_NAME (tên nhà phát triển / tổ chức)}"
OUT="${1:-build_site}"
LAST_UPDATED="${LAST_UPDATED:-$(date +%d/%m/%Y)}"
YEAR="$(date +%Y)"
rm -rf "$OUT"
cp -r site "$OUT"
find "$OUT" -name "*.html" -print0 | while IFS= read -r -d '' f; do
  sed -i \
    -e "s|{{CONTACT_EMAIL}}|${CONTACT_EMAIL}|g" \
    -e "s|{{DEVELOPER_NAME}}|${DEVELOPER_NAME}|g" \
    -e "s|{{LAST_UPDATED}}|${LAST_UPDATED}|g" \
    -e "s|{{YEAR}}|${YEAR}|g" "$f"
done
if grep -rq "{{" "$OUT" --include=*.html; then
  echo "Còn biến chưa thay trong $OUT" >&2
  grep -rn "{{" "$OUT" --include=*.html >&2
  exit 1
fi
echo "Đã dựng site vào $OUT"
