<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>AUDIT · {{URL}}</title>
  <link rel="icon" href="triangle-alert" />
  <style>
    html, body { height: 100%; margin: 0; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: none; display: block; }
  </style>
</head>
<body>
  <iframe src="{{AUDIT_URL}}" title="{{URL}} Audit"></iframe>
  <script>
    slicc.on('update', function(data) {});
  </script>
</body>
</html>
