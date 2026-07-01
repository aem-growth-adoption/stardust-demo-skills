<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AUDIT · {{URL}}</title>
  <link rel="icon" href="triangle-alert" />
  <style>
    :root {
      --bg: #f5f0e6;
      --surface: #fffdf8;
      --sunken: #ece4d2;
      --amber-deep: #c9822d;
      --fg: rgba(26,31,56,0.95);
      --fg-dim: rgba(26,31,56,0.52);
      --hairline-soft: rgba(26,31,56,0.08);
      --text: "SF Pro Text", Inter, system-ui, sans-serif;
      --mono: "SF Mono", "JetBrains Mono", ui-monospace, monospace;
    }

    *, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }

    html, body { height: 100%; overflow: hidden; }

    body {
      display: flex;
      flex-direction: column;
      height: 100vh;
      background: var(--bg);
      color: var(--fg);
      font-family: var(--text);
    }

    .subheader {
      flex-shrink: 0;
      height: 46px;
      background: var(--surface);
      border-bottom: 1px solid var(--hairline-soft);
      display: flex;
      align-items: center;
      padding: 0 16px;
      gap: 10px;
    }

    .subheader__eyebrow {
      font-family: var(--mono);
      font-size: 10px;
      font-weight: 600;
      letter-spacing: 0.08em;
      text-transform: uppercase;
      color: var(--amber-deep);
    }

    .subheader__sep {
      width: 1px;
      height: 14px;
      background: var(--hairline-soft);
      flex-shrink: 0;
    }

    .subheader__site {
      font-family: var(--text);
      font-size: 13px;
      color: var(--fg-dim);
      font-weight: 400;
    }

    .preview-frame {
      flex: 1;
      width: 100%;
      border: none;
      background: var(--bg);
      display: block;
    }
  </style>
</head>
<body>
  <header class="subheader">
    <span class="subheader__eyebrow">Audit</span>
    <div class="subheader__sep"></div>
    <span class="subheader__site">{{URL}}</span>
  </header>
  <iframe
    class="preview-frame"
    src="{{AUDIT_URL}}"
    title="{{URL}} Audit"
  ></iframe>
  <script>
    slicc.on('update', function(data) {});
  </script>
</body>
</html>
