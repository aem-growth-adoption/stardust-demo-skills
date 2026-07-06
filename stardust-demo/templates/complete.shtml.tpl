<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8"/>
  <link rel="icon" href="party-popper" />
  <meta name="viewport" content="width=device-width,initial-scale=1"/>
  <title>{{SLUG}} - complete</title>
  <style>
    :root {
      --ink: #0a1024;
      --bg: #f5f0e6;
      --surface: #fffdf8;
      --sunken: #ece4d2;
      --paper: #f3eee4;
      --amber: #e8b95e;
      --amber-deep: #c9822d;
      --amber-light: #ffd98a;
      --fg: rgba(26,31,56,0.95);
      --fg-muted: rgba(26,31,56,0.72);
      --fg-dim: rgba(26,31,56,0.52);
      --fg-faint: rgba(26,31,56,0.30);
      --hairline: rgba(26,31,56,0.14);
      --hairline-soft: rgba(26,31,56,0.08);
      --success: #5f9669;
      --success-bg: rgba(95,150,105,0.08);
      --display: "SF Pro Display", Inter, system-ui, sans-serif;
      --text: "SF Pro Text", Inter, system-ui, sans-serif;
      --mono: "SF Mono", "JetBrains Mono", ui-monospace, monospace;
      --ease: cubic-bezier(0.16, 1, 0.3, 1);
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    html, body {
      height: 100%;
      background: var(--bg);
      color: var(--fg);
      font: 400 14px/1.55 var(--text);
      -webkit-font-smoothing: antialiased;
    }

    @keyframes riseIn {
      from { opacity: 0; transform: translateY(8px); }
      to   { opacity: 1; transform: none; }
    }

    .fade { opacity: 0; transition: opacity .34s var(--ease); }
    body.ready .fade { opacity: 1; }

    .stagger > * {
      opacity: 0;
      animation: riseIn .56s var(--ease) forwards;
      animation-play-state: paused;
    }
    body.ready .stagger > * { animation-play-state: running; }
    .stagger > *:nth-child(1) { animation-delay: .04s; }
    .stagger > *:nth-child(2) { animation-delay: .12s; }
    .stagger > *:nth-child(3) { animation-delay: .20s; }
    .stagger > *:nth-child(4) { animation-delay: .28s; }

    .wrap { display: flex; flex-direction: column; height: 100vh; }

    .subheader {
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 16px;
      height: 46px;
      flex: none;
      padding: 0 14px;
      background: var(--surface);
      border-bottom: 1px solid var(--hairline-soft);
      position: sticky;
      top: 0;
      z-index: 10;
    }
    .sub-left  { display: flex; align-items: center; gap: 10px; }
    .eyebrow   { font: 500 11px/1 var(--mono); letter-spacing: 0.16em; text-transform: uppercase; color: var(--success); }
    .sub-meta  { font-size: 13px; color: var(--fg-dim); }

    .body {
      flex: 1;
      overflow-y: auto;
      padding: 20px 14px;
      display: flex;
      flex-direction: column;
      gap: 16px;
      scrollbar-width: thin;
      scrollbar-color: var(--hairline) transparent;
    }

    /* ── Live URL card ── */
    .live-card {
      background: var(--success-bg);
      border: 1px solid rgba(95,150,105,0.22);
      border-radius: 13px;
      padding: 16px 18px;
      display: flex;
      align-items: center;
      justify-content: space-between;
      gap: 12px;
    }
    .live-left { display: flex; flex-direction: column; gap: 4px; }
    .live-label {
      font: 600 10px/1 var(--mono);
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: var(--success);
    }
    .live-url {
      font: 500 13px/1.3 var(--mono);
      color: var(--fg);
      word-break: break-all;
    }
    .live-btn {
      display: inline-flex;
      align-items: center;
      gap: 6px;
      padding: 9px 14px;
      border: 1px solid rgba(95,150,105,0.35);
      border-radius: 9px;
      background: var(--surface);
      font: 600 12px/1 var(--mono);
      letter-spacing: 0.06em;
      text-transform: uppercase;
      color: var(--success);
      cursor: pointer;
      transition: all .18s var(--ease);
      text-decoration: none;
      flex: none;
    }
    .live-btn:hover {
      background: var(--success);
      color: #fff;
      border-color: var(--success);
    }

    /* ── Stats row ── */
    .stats {
      display: flex;
      gap: 10px;
    }
    .stat {
      flex: 1;
      background: var(--surface);
      border: 1px solid var(--hairline-soft);
      border-radius: 11px;
      padding: 14px 16px;
      display: flex;
      flex-direction: column;
      gap: 4px;
      box-shadow: 0 1px 2px rgba(26,31,56,0.04);
    }
    .stat-val {
      font: 700 22px/1 var(--display);
      letter-spacing: -0.02em;
      color: var(--fg);
    }
    .stat-label {
      font: 500 11px/1 var(--mono);
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--fg-dim);
    }

    /* ── Next steps ── */
    .next {
      background: var(--surface);
      border: 1px solid var(--hairline-soft);
      border-radius: 13px;
      padding: 16px 18px;
      box-shadow: 0 1px 2px rgba(26,31,56,0.04);
    }
    .next-header {
      font: 600 10px/1 var(--mono);
      letter-spacing: 0.14em;
      text-transform: uppercase;
      color: var(--amber-deep);
      margin-bottom: 12px;
    }
    .next-list {
      list-style: none;
      display: flex;
      flex-direction: column;
      gap: 10px;
    }
    .next-item {
      display: flex;
      align-items: center;
      gap: 12px;
      padding: 10px 12px;
      background: var(--bg);
      border: 1px solid var(--hairline-soft);
      border-radius: 9px;
      transition: all .18s var(--ease);
    }
    .next-item:hover {
      border-color: var(--hairline);
      box-shadow: 0 2px 6px -3px rgba(26,31,56,0.12);
    }
    .next-icon {
      width: 32px;
      height: 32px;
      border-radius: 8px;
      background: var(--sunken);
      display: grid;
      place-items: center;
      font-size: 15px;
      flex: none;
    }
    .next-body { display: flex; flex-direction: column; gap: 2px; flex: 1; }
    .next-title {
      font: 600 13px/1.2 var(--text);
      color: var(--fg);
    }
    .next-desc {
      font-size: 12px;
      color: var(--fg-dim);
      line-height: 1.35;
    }
    .next-link {
      font: 600 11px/1 var(--mono);
      letter-spacing: 0.04em;
      color: var(--amber-deep);
      text-decoration: none;
      flex: none;
    }
    .next-link:hover { text-decoration: underline; }
  </style>
</head>
<body>
<div class="wrap">

  <div class="subheader">
    <div class="sub-left">
      <span class="eyebrow">deployed</span>
      <span class="sub-meta">your redesigned site is live</span>
    </div>
  </div>

  <div class="body stagger">

    <div class="live-card fade">
      <div class="live-left">
        <span class="live-label">live url</span>
        <span class="live-url" id="live-url"></span>
      </div>
      <a class="live-btn" id="live-link" href="#" target="_blank" rel="noopener">open &#8599;</a>
    </div>

    <div class="stats fade" id="stats"></div>

    <div class="next fade">
      <div class="next-header">next steps</div>
      <ul class="next-list" id="next-steps"></ul>
    </div>

  </div>
</div>

<script id="complete-data" type="application/json">
{{COMPLETE_JSON}}
</script>

<script>
  var DATA = JSON.parse(document.getElementById('complete-data').textContent);

  function escHtml(s) {
    return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
  }

  function renderLiveUrl() {
    document.getElementById('live-url').textContent = DATA.liveUrl;
    var link = document.getElementById('live-link');
    link.href = DATA.liveUrl;
  }

  function renderStats() {
    var el = document.getElementById('stats');
    var stats = DATA.stats || [];
    el.innerHTML = stats.map(function(s) {
      return '<div class="stat"><span class="stat-val">' + escHtml(s.value) + '</span><span class="stat-label">' + escHtml(s.label) + '</span></div>';
    }).join('');
  }

  function renderNextSteps() {
    var el = document.getElementById('next-steps');
    var steps = DATA.nextSteps || [];
    el.innerHTML = steps.map(function(s) {
      var linkHtml = s.url
        ? '<a class="next-link" href="' + escHtml(s.url) + '" target="_blank" rel="noopener">' + escHtml(s.linkLabel || 'open') + ' &#8599;</a>'
        : '<span class="next-link">' + escHtml(s.linkLabel || '') + '</span>';
      return '<li class="next-item">' +
        '<span class="next-icon">' + (s.icon || '→') + '</span>' +
        '<div class="next-body"><span class="next-title">' + escHtml(s.title) + '</span><span class="next-desc">' + escHtml(s.description) + '</span></div>' +
        linkHtml +
      '</li>';
    }).join('');
  }

  renderLiveUrl();
  renderStats();
  renderNextSteps();

  setTimeout(function() { document.body.classList.add('ready'); }, 50);

  slicc.on('update', function(data) {});
</script>
</body>
</html>
