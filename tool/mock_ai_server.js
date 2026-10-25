// Mock OpenAI-compatible server cho kiểm thử end-to-end GĐ17 trên thiết bị.
// Chạy: node tool/mock_ai_server.js [port]
// Log mọi request (prompt + response) vào tool/mock_ai_requests.log để đối chiếu
// contract request/response thực tế mà app gửi/nhận.
const http = require('http');
const fs = require('fs');
const path = require('path');

const PORT = Number(process.argv[2] || 8765);
const LOG = path.join(__dirname, 'mock_ai_requests.log');

function log(obj) {
  const line = JSON.stringify(obj);
  console.log(line);
  fs.appendFileSync(LOG, line + '\n');
}

// Bài học trả về ĐÚNG camelCase như prompt trong http_ai_provider.dart yêu cầu.
function buildLesson(topic) {
  const body =
    'Nội dung chi tiết về ' + topic + '. ' +
    'Phần giải thích mở rộng với nhiều ví dụ thực tế giúp người học nắm chắc kiến thức nền tảng. '.repeat(8);
  return {
    title: 'Bài học: ' + topic,
    learningObjectives: [
      'Hiểu bản chất của ' + topic,
      'Áp dụng ' + topic + ' vào bài toán thực tế',
    ],
    introduction: 'Mở đầu về ' + topic + '. ' + body,
    concepts: [
      { name: 'Khái niệm nền của ' + topic, explanation: 'Giải thích chi tiết. ' + body },
    ],
    sections: [
      { heading: 'Phần 1: Tổng quan', body: body },
      { heading: 'Phần 2: Ứng dụng', body: body },
    ],
    keyPoints: ['Ý chính 1 về ' + topic, 'Ý chính 2 về ' + topic, 'Ý chính 3 về ' + topic],
    examples: ['Ví dụ 1 về ' + topic, 'Ví dụ 2 về ' + topic],
    commonMistakes: ['Sai lầm 1 về ' + topic, 'Sai lầm 2 về ' + topic],
    summary: 'Tóm tắt về ' + topic + '. ' + body,
    questions: [
      { question: 'Câu hỏi 1 về ' + topic + '?', answer: 'Đáp án 1.', explanation: 'Giải thích 1.' },
      { question: 'Câu hỏi 2 về ' + topic + '?', answer: 'Đáp án 2.', explanation: 'Giải thích 2.' },
    ],
    sources: [{ title: 'Nguồn tham khảo về ' + topic, url: 'https://example.com/' + encodeURIComponent(topic) }],
    medical: false,
  };
}

function buildKnowledge(text) {
  const base = (text || 'Chủ đề').slice(0, 60);
  return {
    items: [
      { title: 'Thông tin nhanh 1: ' + base, content: 'Nội dung chi tiết 1 về ' + base + '. '.padEnd(120, 'x'), details: 'Chi tiết 1' },
      { title: 'Thông tin nhanh 2: ' + base, content: 'Nội dung chi tiết 2 về ' + base + '. '.padEnd(120, 'y'), details: 'Chi tiết 2' },
      { title: 'Thông tin nhanh 3: ' + base, content: 'Nội dung chi tiết 3 về ' + base + '. '.padEnd(120, 'z'), details: 'Chi tiết 3' },
    ],
  };
}

function buildTopics() {
  return {
    topics: [
      { title: 'Chủ đề khám phá 1', description: 'Mô tả ngắn chủ đề 1' },
      { title: 'Chủ đề khám phá 2', description: 'Mô tả ngắn chủ đề 2' },
      { title: 'Chủ đề khám phá 3', description: 'Mô tả ngắn chủ đề 3' },
    ],
  };
}

const server = http.createServer((req, res) => {
  let raw = '';
  req.on('data', (c) => (raw += c));
  req.on('end', () => {
    let payload = {};
    try {
      payload = JSON.parse(raw || '{}');
    } catch (e) {
      payload = { parseError: String(e), raw };
    }
    const messages = payload.messages || [];
    const system = (messages.find((m) => m.role === 'system') || {}).content || '';
    const user = (messages.find((m) => m.role === 'user') || {}).content || '';

    let content;
    if (/CẤU TRÚC BẮT BUỘC/.test(system)) {
      const m = /Chủ đề: ([^\n]+)/.exec(user);
      content = JSON.stringify(buildLesson(m ? m[1].trim() : 'Chủ đề'));
    } else if (/phân tích văn bản đầu vào/.test(system)) {
      const m = /Văn bản:\n([\s\S]*)$/.exec(user);
      content = JSON.stringify(buildKnowledge(m ? m[1].trim() : ''));
    } else if (/Generate a JSON object \{"topics"/.test(system)) {
      content = JSON.stringify(buildTopics());
    } else if (/Câu hỏi:/.test(system) && /Đáp án đúng:/.test(system)) {
      content = JSON.stringify({ verdict: 'correct', comment: 'Đáp án đúng.', score: 1.0 });
    } else {
      content = JSON.stringify({ explanation: 'Giải thích mẫu.', example: 'Ví dụ mẫu.' });
    }

    const out = {
      id: 'chatcmpl-mock',
      object: 'chat.completion',
      choices: [{ index: 0, message: { role: 'assistant', content }, finish_reason: 'stop' }],
    };
    log({ t: Date.now(), path: req.url, model: payload.model, system: system.slice(0, 400), user: user.slice(0, 400), content });
    res.writeHead(200, { 'Content-Type': 'application/json; charset=utf-8' });
    res.end(JSON.stringify(out));
  });
});

server.listen(PORT, '127.0.0.1', () => {
  log({ t: Date.now(), event: 'listen', port: PORT });
  console.log('mock_ai_server listening on http://127.0.0.1:' + PORT + '/v1');
});
