# Architecture: S3 + CloudFront Static Hosting

This diagram details the flow of traffic. The user requests the webpage, which hits the nearest CloudFront edge location. If the file is not cached, CloudFront pulls it from the S3 bucket origin.

```xml
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 700 300">
  <rect width="700" height="300" fill="#f8f9fa" rx="10"/>
  <rect x="50" y="110" width="120" height="80" fill="#e0e0e0" stroke="#757575" stroke-width="2" rx="5"/>
  <text x="110" y="150" font-family="Arial" font-size="14" text-anchor="middle" font-weight="bold">Web Browser</text>
  <text x="110" y="170" font-family="Arial" font-size="12" text-anchor="middle">(User)</text>
  <rect x="270" y="90" width="160" height="120" fill="#e1bee7" stroke="#8e24aa" stroke-width="2" rx="5"/>
  <text x="350" y="145" font-family="Arial" font-size="14" text-anchor="middle" font-weight="bold">CloudFront CDN</text>
  <text x="350" y="165" font-family="Arial" font-size="12" text-anchor="middle">(Global Edge Cache)</text>
  <text x="350" y="185" font-family="Arial" font-size="12" text-anchor="middle">HTTPS</text>
  <rect x="520" y="100" width="130" height="100" fill="#c8e6c9" stroke="#388e3c" stroke-width="2" rx="5"/>
  <text x="585" y="145" font-family="Arial" font-size="14" text-anchor="middle" font-weight="bold">Amazon S3</text>
  <text x="585" y="165" font-family="Arial" font-size="12" text-anchor="middle">(Origin Bucket)</text>
  <text x="585" y="185" font-family="Arial" font-size="12" text-anchor="middle">HTTP</text>
  <path d="M 170 150 L 265 150" stroke="#333" stroke-width="2" marker-end="url(#arrow)"/>
  <path d="M 430 150 L 515 150" stroke="#333" stroke-width="2" marker-end="url(#arrow)"/>
  <defs>
    <marker id="arrow" markerWidth="10" markerHeight="10" refX="9" refY="3" orient="auto" markerUnits="strokeWidth">
      <path d="M0,0 L0,6 L9,3 z" fill="#333" />
    </marker>
  </defs>
</svg>
```
