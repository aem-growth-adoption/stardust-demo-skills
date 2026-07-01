<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Brand Review · {{URL}}</title>
  <link rel="icon" href="palette" />
  <style>
    html, body { height: 100%; margin: 0; overflow: hidden; }
    iframe { width: 100%; height: 100%; border: none; display: block; }
  </style>
</head>
<body>
  <iframe src="{{BRAND_REVIEW_URL}}" title="{{URL}} Brand Review"></iframe>
  <script>
    slicc.on('update', function(data) {});
  </script>
</body>
</html>
