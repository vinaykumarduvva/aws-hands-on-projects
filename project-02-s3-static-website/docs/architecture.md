# Architecture: Static Website on S3 + CloudFront

This document illustrates the architecture for globally distributing a highly-available static website using AWS S3 and CloudFront.

## Overview

The solution provides a secure, fast, and cost-effective way to host a static portfolio website. It leverages Amazon S3 for origin storage and Amazon CloudFront as a Content Delivery Network (CDN) to ensure low latency and HTTPS security worldwide.

## Architecture Diagram

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

## Component Details

1. **Web Browser (User)**: The client requesting the website content. All connections are forced to use HTTPS for security.
2. **CloudFront CDN**: A global content delivery network spanning over 400 edge locations worldwide. It caches static assets closer to the users, terminates SSL/TLS connections, and significantly reduces latency.
3. **Amazon S3 (Origin Bucket)**: The foundational storage layer holding the website's static files (`index.html`, `error.html`, CSS, JS). It is configured for static website hosting and grants public read access to its objects.

## Traffic Flow

1. **Request**: A user requests the website via their browser. The request is routed to the nearest CloudFront Edge Location.
2. **Cache Check**: CloudFront checks its local cache. If the content is available (Cache Hit), it serves the content immediately to the user over HTTPS.
3. **Origin Fetch**: If the content is not cached (Cache Miss), CloudFront securely fetches the files from the S3 Origin Bucket over HTTP, caches them for future requests, and returns them to the user.
