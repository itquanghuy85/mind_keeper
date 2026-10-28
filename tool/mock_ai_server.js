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

// Bài học NGẮN (khoảng 150 từ), trả về ĐÚNG camelCase như prompt trong http_ai_provider.dart.
function buildLesson(topic) {
  return {
    title: 'Bài học: ' + topic,
    learningObjectives: ['Hiểu ý chính của ' + topic, 'Áp dụng vào thực tế'],
    introduction: 'Bài học ngắn giúp bạn nắm nhanh ' + topic + ' và dùng được ngay hằng ngày.',
    concepts: [
      { name: 'Ý cốt lõi', explanation: 'Điều quan trọng nhất cần nhớ để không nhầm lẫn khi áp dụng.' },
    ],
    sections: [
      { heading: 'Phần 1: Tổng quan', body: 'Hãy nhìn chủ đề này như một bức tranh lớn gồm vài ý chính liên kết với nhau. Nắm được sườn ý, bạn sẽ dễ nhớ các chi tiết nhỏ hơn.' },
      { heading: 'Phần 2: Ứng dụng', body: 'Hãy gắn nó với một việc quen thuộc trong ngày, rồi tự giải thích lại bằng lời của mình để nhớ lâu hơn.' },
    ],
    keyPoints: ['Hiểu bản chất trước khi ghi nhớ', 'Liên hệ với ví dụ quen thuộc', 'Ôn lại đúng lúc để nhớ lâu'],
    examples: ['Ví dụ: giải thích ' + topic + ' cho một người bạn trong một câu.'],
    commonMistakes: ['Học vẹt mà không hiểu bản chất'],
    summary: 'Nắm sườn ý chính rồi tự giải thích lại để nhớ lâu.',
    memoryTip: 'Gắn ý chính với một hình ảnh quen thuộc rồi tự kể lại.',
    questions: [
      { question: 'Ý chính của ' + topic + ' là gì?', answer: 'Nắm sườn ý chính rồi tự giải thích lại.', explanation: 'Xem lại Phần 1.' },
      { question: 'Làm sao nhớ lâu hơn?', answer: 'Liên hệ ví dụ quen thuộc và ôn lại đúng lúc.', explanation: 'Xem lại Phần 2.' },
      { question: 'Sai lầm thường gặp khi học?', answer: 'Học vẹt mà không hiểu bản chất.', explanation: 'Xem mục Sai lầm thường gặp.' },
    ],
    sources: [],
    medical: false,
  };
}

function buildKnowledge(text) {
  const base = (text || 'Chủ đề').slice(0, 60);
  return {
    items: [
      { title: 'Thông tin nhanh 1: ' + base, content: 'Ý chính thứ nhất về ' + base + ' là hiểu bản chất trước khi ghi nhớ. Khi hiểu rõ nguyên lý, bạn sẽ tự suy ra nhiều điều mà không cần học thuộc lòng.', details: 'Chi tiết 1' },
      { title: 'Thông tin nhanh 2: ' + base, content: 'Ý chính thứ hai về ' + base + ' là gắn kiến thức với ví dụ quen thuộc. Ví dụ gần gũi giúp não bộ nhớ lâu hơn.', details: 'Chi tiết 2' },
      { title: 'Thông tin nhanh 3: ' + base, content: 'Ý chính thứ ba về ' + base + ' là ôn lại đúng lúc. Việc nhắc lại chủ động củng cố trí nhớ tốt hơn đọc lướt.', details: 'Chi tiết 3' },
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

// GĐ23: đề cương + mẩu khóa học.
function buildOutline(user) {
  const t = /Chủ đề: ([^\n]+)/.exec(user);
  const n = /Số mẩu: (\d+)/.exec(user);
  const topic = t ? t[1].trim() : 'Chủ đề';
  const count = n ? Number(n[1]) : 5;
  const aspects = ['Khái niệm cơ bản', 'Nguyên lý hoạt động', 'Ứng dụng đời sống', 'Hiểu lầm phổ biến', 'Lịch sử hình thành', 'Thành phần chính', 'So sánh giải pháp', 'Mẹo sử dụng', 'Giới hạn và rủi ro', 'Xu hướng'];
  const titles = [];
  for (let i = 0; i < count; i++) {
    titles.push(topic + ' - ' + aspects[i % aspects.length] + (i >= aspects.length ? ' ' + (Math.floor(i / aspects.length) + 1) : ''));
  }
  return { titles };
}

function buildBite(user) {
  const t = /Chủ đề: ([^\n]+)/.exec(user);
  const m = /Mẩu (\d+)\/(\d+): ([^\n]+)/.exec(user);
  const topic = t ? t[1].trim() : 'Chủ đề';
  const idx = m ? m[1] : '1';
  const title = m ? m[3].trim() : 'Mẩu';
  // Mẩu NGẮN 120-180 từ, tối đa 3 ý chính.
  const content = 'Đây là nội dung mẩu ' + idx + ' của chủ đề ' + topic + ': ' + title + '. ' +
    'Ý chính thứ nhất: hiểu bản chất của vấn đề trước khi ghi nhớ chi tiết, vì khi hiểu rõ nguyên lý bạn sẽ tự suy ra được nhiều điều mà không cần học thuộc lòng từng câu chữ riêng lẻ. ' +
    'Ý chính thứ hai: liên hệ nội dung này với một tình huống quen thuộc trong cuộc sống hằng ngày, bởi những ví dụ gần gũi giúp não bộ gắn kiến thức mới vào trải nghiệm đã có và nhớ lâu hơn. ' +
    'Ý chính thứ ba: ôn lại sau một khoảng thời gian ngắn bằng cách tự giải thích bằng lời của chính mình, vì việc nhắc lại chủ động củng cố trí nhớ tốt hơn nhiều so với chỉ đọc lướt.';
  return {
    title,
    content,
    summary: 'Hiểu bản chất, liên hệ ví dụ quen thuộc và tự giải thích lại: ' + title + '.',
    memoryTip: 'Nhớ "' + title + '" bằng một hình ảnh quen thuộc rồi tự kể lại.',
    example: 'Hãy giải thích mẩu ' + idx + ' cho một người bạn chỉ trong một câu.',
    sources: ['Giáo trình ' + topic + ' (mẫu kiểm thử)'],
    question: 'Ý chính của mẩu ' + idx + ' về ' + topic + ' là gì?',
    answer: 'Hiểu bản chất, liên hệ ví dụ và tự giải thích lại.',
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
    if (/lập đề cương gồm ĐÚNG/.test(system)) {
      content = JSON.stringify(buildOutline(user));
    } else if (/soạn một mẩu kiến thức ngắn/.test(system)) {
      content = JSON.stringify(buildBite(user));
    } else if (/CẤU TRÚC BẮT BUỘC/.test(system)) {
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
