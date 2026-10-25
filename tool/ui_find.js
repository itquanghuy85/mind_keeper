// Helper thao tác UI Android qua adb + uiautomator.
// Đọc từ khóa tìm kiếm từ tool/ui_query.txt (UTF-8) để tránh vấn đề
// encoding khi truyền tiếng Việt qua command line PowerShell.
//
//   node tool/ui_find.js            → dump + tìm (không tap)
//   node tool/ui_find.js tap        → dump + tìm + tap vào match đầu tiên
//   node tool/ui_find.js tap 2      → tap vào match thứ 2 (0-based)
//   node tool/ui_find.js list       → liệt kê toàn bộ text hiển thị
//   node tool/ui_find.js scroll     → cuộn xuống 1 màn hình rồi tìm
//   node tool/ui_find.js scroll N   → cuộn xuốn N màn hình rồi tìm
const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

const ROOT = path.join(__dirname, '..');
const QUERY_FILE = path.join(__dirname, 'ui_query.txt');
const OUT_FILE = path.join(__dirname, 'ui_out.txt');

function sh(cmd) {
  return execSync(cmd, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'pipe'] });
}

function dump() {
  sh('adb shell uiautomator dump /sdcard/mk_ui.xml');
  return sh('adb exec-out cat /sdcard/mk_ui.xml');
}

function parse(xml) {
  return xml.split('<node ').slice(1).map((chunk) => {
    const a = {};
    const re = /([a-zA-Z-]+)="([^"]*)"/g;
    let m;
    while ((m = re.exec(chunk)) !== null) a[m[1]] = m[2];
    return a;
  });
}

const mode = process.argv[2] || 'find';
const index = Number(process.argv[3] || 0);
const lines = [];

try {
  let parsed = parse(dump());

  if (mode === 'list') {
    const seen = new Set();
    for (const n of parsed) {
      for (const k of ['text', 'content-desc']) {
        if (n[k] && !seen.has(n[k])) {
          seen.add(n[k]);
          lines.push(`[${k}] ${n[k]}  bounds=${n.bounds}`);
        }
      }
    }
  } else {
    const q = fs.readFileSync(QUERY_FILE, 'utf8').trim();
    if (!q) throw new Error('tool/ui_query.txt rỗng');

    if (mode === 'scroll' || mode === 'scrollup') {
      // Cuộn theo hướng yêu cầu, tìm theo từng bước cho tới khi thấy mục tiêu.
      const up = mode === 'scrollup';
      for (let i = 0; i <= index; i++) {
        const hit = parsed.filter((n) => {
          const blob = `${n.text || ''} ${n['content-desc'] || ''}`;
          return blob && blob.toLowerCase().includes(q.toLowerCase());
        });
        if (hit.length > 0 && i === index) {
          lines.push(`FOUND at scroll ${i} (${hit.length} match(es))`);
          hit.forEach((n, k) => {
            lines.push(`  [${k}] text='${n.text || ''}' desc='${n['content-desc'] || ''}' bounds=${n.bounds} clickable=${n.clickable}`);
          });
          const b = hit[0].bounds;
          const m = /\[(\d+),(\d+)\]\[(\d+),(\d+)\]/.exec(b);
          if (m) {
            const x = Math.round((Number(m[1]) + Number(m[3])) / 2);
            const y = Math.round((Number(m[2]) + Number(m[4])) / 2);
            lines.push(`TAP (${x},${y})`);
            sh(`adb shell input tap ${x} ${y}`);
          }
          break;
        }
        if (i === index) {
          lines.push(`NOT_FOUND after ${i} scroll(s)`);
          break;
        }
        if (up) sh('adb shell input swipe 540 700 540 1600 300');
        else sh('adb shell input swipe 540 1600 540 700 300');
        await_sleep(600);
        parsed = parse(dump());
      }
    } else {
      const found = parsed.filter((n) => {
        const blob = `${n.text || ''} ${n['content-desc'] || ''}`;
        return blob && blob.toLowerCase().includes(q.toLowerCase());
      });
      lines.push(`QUERY="${q}" -> ${found.length} match(es)`);
      found.forEach((n, i) => {
        lines.push(`  [${i}] text='${n.text || ''}' desc='${n['content-desc'] || ''}' bounds=${n.bounds} clickable=${n.clickable}`);
      });
      if (mode === 'tap' && found.length > index) {
        const m = /\[(\d+),(\d+)\]\[(\d+),(\d+)\]/.exec(found[index].bounds);
        if (!m) throw new Error('bounds không parse được');
        const x = Math.round((Number(m[1]) + Number(m[3])) / 2);
        const y = Math.round((Number(m[2]) + Number(m[4])) / 2);
        lines.push(`TAP (${x},${y})`);
        sh(`adb shell input tap ${x} ${y}`);
      }
    }
  }
} catch (e) {
  lines.push('ERROR: ' + (e && e.message ? e.message : String(e)));
}

function await_sleep(ms) {
  const end = Date.now() + ms;
  while (Date.now() < end) {}
}

fs.writeFileSync(OUT_FILE, lines.join('\n'), 'utf8');
console.log(lines.join('\n'));
