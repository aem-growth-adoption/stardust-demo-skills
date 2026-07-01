<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Audit · {{URL}}</title>
  <style>
    :root {
      --bg: #f5f0e6;
      --surface: #fffdf8;
      --sunken: #ece4d2;
      --amber: #e8b95e;
      --amber-deep: #c9822d;
      --amber-light: #ffd98a;
      --fg: rgba(26,31,56,0.95);
      --fg-muted: rgba(26,31,56,0.72);
      --fg-dim: rgba(26,31,56,0.52);
      --fg-faint: rgba(26,31,56,0.30);
      --hairline-soft: rgba(26,31,56,0.08);
      --hairline: rgba(26,31,56,0.14);
      --success: #5f9669;
      --danger: #c0453f;
      --display: "SF Pro Display", Inter, system-ui, sans-serif;
      --text: "SF Pro Text", Inter, system-ui, sans-serif;
      --mono: "SF Mono", "JetBrains Mono", ui-monospace, monospace;
      --ease: cubic-bezier(0.16, 1, 0.3, 1);
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    html, body {
      min-height: 100%;
      background: var(--bg);
      color: var(--fg);
      font-family: var(--text);
      font-size: 14px;
      line-height: 1.5;
      -webkit-font-smoothing: antialiased;
    }

    body {
      padding: 24px 20px 40px;
      display: flex;
      flex-direction: column;
      gap: 10px;
      max-width: 720px;
      margin: 0 auto;
    }

    .header {
      display: flex;
      align-items: center;
      gap: 10px;
      margin-bottom: 12px;
    }

    .header__eyebrow {
      font-family: var(--mono);
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 0.08em;
      color: var(--amber-deep);
      text-transform: uppercase;
    }

    .header__sep {
      width: 1px;
      height: 14px;
      background: var(--hairline);
      flex-shrink: 0;
    }

    .header__site {
      font-family: var(--mono);
      font-size: 12px;
      color: var(--fg-dim);
    }

    .header__spacer { flex: 1; }

    .header__pill {
      background: var(--sunken);
      color: var(--fg-dim);
      font-family: var(--mono);
      font-size: 11px;
      border-radius: 999px;
      padding: 4px 10px;
    }

    .tension-card {
      background: var(--surface);
      border: 1px solid var(--hairline-soft);
      border-radius: 13px;
      padding: 16px 18px;
      box-shadow: 0 1px 2px rgba(26,31,56,0.04);
      position: relative;
      padding-left: 22px;
      overflow: hidden;
    }

    .tension-card::before {
      content: '';
      position: absolute;
      left: 0;
      top: 0;
      bottom: 0;
      width: 3px;
      border-radius: 13px 0 0 13px;
    }

    .tension-card--dated-pattern::before  { background: var(--danger); }
    .tension-card--ia-clutter::before     { background: var(--amber-deep); }
    .tension-card--density::before        { background: var(--fg-dim); }
    .tension-card--cliche::before         { background: var(--danger); }
    .tension-card--missed-opportunity::before { background: var(--success); }

    .tension-card__top {
      display: flex;
      align-items: center;
      justify-content: space-between;
      margin-bottom: 7px;
      gap: 8px;
    }

    .tension-card__number {
      font-family: var(--mono);
      font-size: 11px;
      color: var(--fg-faint);
      letter-spacing: 0.06em;
      margin-left: auto;
      flex-shrink: 0;
    }

    .tag {
      display: inline-block;
      font-family: var(--mono);
      font-size: 10px;
      font-weight: 700;
      letter-spacing: 0.07em;
      text-transform: uppercase;
      border-radius: 999px;
      padding: 3px 9px;
    }

    .tag--dated-pattern { background: rgba(192,69,63,0.10); color: #c0453f; }
    .tag--ia-clutter { background: rgba(201,130,45,0.10); color: var(--amber-deep); }
    .tag--density { background: rgba(26,31,56,0.07); color: var(--fg-dim); }
    .tag--cliche { background: rgba(192,69,63,0.10); color: #c0453f; }
    .tag--missed-opportunity { background: rgba(95,150,105,0.10); color: var(--success); }

    .tension-card__title {
      font-family: var(--display);
      font-size: 15px;
      font-weight: 600;
      color: var(--fg);
      line-height: 1.35;
      margin-bottom: 8px;
    }

    .tension-card__body {
      font-family: var(--text);
      font-size: 13px;
      color: var(--fg-muted);
      line-height: 1.6;
    }

    @keyframes riseIn {
      from { opacity: 0; transform: translateY(8px); }
      to   { opacity: 1; transform: none; }
    }

    .stagger > * {
      opacity: 0;
      animation: riseIn .5s var(--ease) forwards;
    }

    .stagger > *:nth-child(1) { animation-delay: .04s; }
    .stagger > *:nth-child(2) { animation-delay: .10s; }
    .stagger > *:nth-child(3) { animation-delay: .16s; }
    .stagger > *:nth-child(4) { animation-delay: .22s; }
    .stagger > *:nth-child(5) { animation-delay: .28s; }
  </style>
</head>
<body>

  <div class="header">
    <span class="header__eyebrow">Audit</span>
    <span class="header__sep"></span>
    <span class="header__site">{{URL}}</span>
    <span class="header__spacer"></span>
    <span class="header__pill" id="count-pill"></span>
  </div>

  <div class="stagger" id="cards"></div>

  <!-- Data island: raw JSON, safe from shell escaping -->
  <script id="tensions-data" type="application/json">
{{TENSIONS_JSON}}
  </script>

  <script>
    var TENSIONS = JSON.parse(document.getElementById('tensions-data').textContent);

    var CATEGORY_LABELS = {
      'dated-pattern': 'Dated Pattern',
      'ia-clutter': 'IA / Clutter',
      'density': 'Density',
      'cliche': 'Cliché',
      'missed-opportunity': 'Missed Opportunity'
    };

    function escHtml(s) {
      return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }

    document.getElementById('count-pill').textContent = TENSIONS.length + ' tensions found';

    var container = document.getElementById('cards');
    TENSIONS.forEach(function(t, i) {
      var cat = t.category || 'density';
      container.insertAdjacentHTML('beforeend',
        '<article class="tension-card tension-card--' + cat + '">' +
          '<div class="tension-card__top">' +
            '<span class="tag tag--' + cat + '">' + escHtml(CATEGORY_LABELS[cat] || cat) + '</span>' +
            '<span class="tension-card__number">' + String(i + 1).padStart(2, '0') + '</span>' +
          '</div>' +
          '<h2 class="tension-card__title">' + escHtml(t.title) + '</h2>' +
          '<p class="tension-card__body">' + escHtml(t.body) + '</p>' +
        '</article>'
      );
    });
  </script>
</body>
</html>
