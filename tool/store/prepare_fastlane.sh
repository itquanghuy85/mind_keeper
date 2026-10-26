#!/usr/bin/env bash
# Sinh cây thư mục fastlane (metadata + ảnh) từ store/listing/*.md và store/*.
#   SITE_URL=https://<tài-khoản>.github.io/mind_keeper bash tool/store/prepare_fastlane.sh
# Đầu ra: fastlane/metadata/android/<locale>/..., fastlane/metadata/<ios-locale>/...
# và fastlane/screenshots/... — sẵn cho `fastlane supply` (Google Play) và
# `fastlane deliver` (App Store Connect). Không tự đăng gì lên cửa hàng.
set -euo pipefail
cd "$(dirname "$0")/../.."
: "${SITE_URL:?Cần đặt SITE_URL (địa chỉ site chứa /privacy/)}"
bash tool/store/check_listing.sh >/dev/null
SITE_URL="$SITE_URL" PYTHONIOENCODING=utf-8 python - <<'PY'
import os
import re
import shutil

site = os.environ["SITE_URL"].rstrip("/")


def sections(path):
    text = open(path, encoding="utf-8").read()
    out = {}
    for block in re.split(r"(?m)^## ", text)[1:]:
        head, _, body = block.partition("\n")
        out[head.split(" — ")[0].split(" (")[0].strip()] = body.strip()
    return out


def write(path, content):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        f.write(content.strip() + "\n")


def lines_after(body, *names):
    return body


locales = {
    # tệp nguồn: (mã Play, mã iOS, khoá tên, subtitle, short, promo, keywords, full, notes)
    "store/listing/vi-VN.md": ("vi-VN", "vi", "Tên ứng dụng", "Tiêu đề phụ", "Mô tả ngắn",
                               "Văn bản quảng bá", "Từ khóa", "Mô tả đầy đủ", "Nội dung có gì mới"),
    "store/listing/en-US.md": ("en-US", "en-US", "App name", "Subtitle", "Short description",
                               "Promotional text", "Keywords", "Full description", "Release notes"),
}
for src, (play, ios, k_name, k_sub, k_short, k_promo, k_kw, k_full, k_notes) in locales.items():
    s = sections(src)
    base = f"fastlane/metadata/android/{play}"
    write(f"{base}/title.txt", s[k_name])
    write(f"{base}/short_description.txt", s[k_short])
    write(f"{base}/full_description.txt", s[k_full])
    write(f"{base}/changelogs/1.txt", s[k_notes])
    ib = f"fastlane/metadata/{ios}"
    write(f"{ib}/name.txt", s[k_name])
    write(f"{ib}/subtitle.txt", s[k_sub])
    write(f"{ib}/promotional_text.txt", s[k_promo])
    write(f"{ib}/keywords.txt", s[k_kw])
    write(f"{ib}/description.txt", s[k_full])
    write(f"{ib}/release_notes.txt", s[k_notes])
    write(f"{ib}/privacy_url.txt", f"{site}/privacy/")
    write(f"{ib}/support_url.txt", f"{site}/support/")
    write(f"{ib}/marketing_url.txt", f"{site}/")

# Ảnh Google Play (vi-VN)
img = "fastlane/metadata/android/vi-VN/images"
os.makedirs(f"{img}/phoneScreenshots", exist_ok=True)
shutil.copy("store/play/icon_512.png", f"{img}/icon.png")
shutil.copy("store/play/feature_graphic_1024x500.png", f"{img}/featureGraphic.png")
for f in sorted(os.listdir("store/screenshots/android_phone")):
    shutil.copy(f"store/screenshots/android_phone/{f}", f"{img}/phoneScreenshots/{f}")

# Ảnh App Store (vi): fastlane deliver nhận theo thư mục ngôn ngữ, tự nhận kích cỡ.
for folder, label in (("ios_6.7", "6.7"), ("ios_6.5", "6.5"), ("ios_5.5", "5.5"), ("ipad_12.9", "ipad")):
    dst = f"fastlane/screenshots/vi/{label}"
    os.makedirs(dst, exist_ok=True)
    for f in sorted(os.listdir(f"store/screenshots/{folder}")):
        shutil.copy(f"store/screenshots/{folder}/{f}", f"{dst}/{f}")
shutil.copy("store/appstore/icon_1024.png", "fastlane/app_store_icon_1024.png")
print("Đã sinh fastlane/ từ store/")
PY
