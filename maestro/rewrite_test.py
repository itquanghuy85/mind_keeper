import sys

filepath = r'D:\JOB\mind_kepper\mind_keeper\maestro\gd17_study_plan.yaml'

with open(filepath, 'r', encoding='utf8') as f:
    content = f.read()

# Replace the entire content with the fixed version
new_content = """# GD17.3 - Nghiem thu Kế hoạch học chủ động trên OPPO CPH2237 (Android 13).
# Chạy: maestro test --device VCZX4LGQIVVSJNBE maestro/gd17_study_plan.yaml
# Lưu ý: phải set JAVA_OPTS="-Dfile.encoding=UTF-8 -Dsun.jnu.encoding=UTF-8"
# để Maestro đọc được tiếng Việt trong selector.
appId: com.mindkeeper.mind_keeper
name: GD17.3 Study Plan E2E Acceptance
--- 
- launchApp:
    clearState: false
- extendedWaitUntil:
    visible: "Trang ch?"
    timeout: 20000
- takeScreenshot: "gd17_01_home"
# Navigate to profile section - tap on profile tab
- tapOn: textStartsWith: "Ho so"
- extendedWaitUntil:
    visible: "Cai dat thong bao chi tiet"
    timeout: 15000
- takeScreenshot: "gd17_02_profile"
# Scroll to study plan and navigate
- scrollUntilVisible:
    element: "Ke hoach hoc"
    direction: DOWN
    visibilityPercentage: 40
    centerElement: true
    timeout: 15000
- tapOn: "Ke hoach hoc"
- extendedWaitUntil:
    visible: "Ke hoach hoc"
    timeout: 15000
- takeScreenshot: "gd17_03_study_plan_opened"
# Verify main components visible
- assertVisible: "Thong tin nhanh moi ngay"
- assertVisible: "Bai viet moi ngay"
- assertVisible: "Tao truoc"
- assertVisible: "Bat dau khung gio"
- assertVisible: "Thong bao bai moi"
- assertVisible: " Chu the the doi"
- takeScreenshot: "gd17_04_components"
# Change quota to 3
- tapOn: "Thong tin nhanh moi ngay"
- extendedWaitUntil:
    visible: "3"
    timeout: 10000
- tapOn: "3"
- extendedWaitUntil:
    visible: "3 muc"
    timeout: 10000
- takeScreenshot: "gd17_05_quota_changed"
# Tap on notification setting
- tapOn: "Thong bao bai moi"
- extendedWaitUntil:
    visible: "3 muc"
    timeout: 10000
    # Buoc quan trong tren Android 13: xac nhan quyen notification da duoc cap
- tapOn:
    text: ".*(Cho phep|Allow).*"
    optional: true
- takeScreenshot: "gd17_06_notifications_enabled"
# Tap "Dong tai ngay" sync button
- tapOn: "Dong tai ngay"
- extendedWaitUntil:
    visible: "Dong tai ngay"
    timeout: 30000
- takeScreenshot: "gd17_07_after_sync"
# Go back to profile and verify settings persisted
- tapOn: "Ho so"
- extendedWaitUntil:
    visible: "Cai dat thong bao chi tiet"
    timeout: 15000
- scrollUntilVisible:
    element: "Ke hoach hoc"
    direction: DOWN
    visibilityPercentage: 40
    centerElement: true
    timeout: 15000
- tapOn: "Ke hoach hoc"
- extendedWaitUntil:
    visible: "Ke hoach hoc"
    timeout: 15000
- assertVisible: "3 muc"
- assertVisible: "Thong bao bai moi"
- takeScreenshot: "gd17_08_settings_persisted"
# Final screenshot
- takeScreenshot: "gd17_09_final"
"""

with open(filepath, 'w', encoding='utf8') as f:
    f.write(new_content)

print('File rewritten successfully')