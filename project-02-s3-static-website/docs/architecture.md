# Architecture: Static Website on S3 + CloudFront

This document illustrates the architecture for globally distributing a highly-available static website using AWS S3 and CloudFront.

## Overview

The solution provides a secure, fast, and cost-effective way to host a static portfolio website. It leverages Amazon S3 for origin storage and Amazon CloudFront as a Content Delivery Network (CDN) to ensure low latency and HTTPS security worldwide.

## Architecture Diagram

<svg viewBox="0 0 900 680" xmlns="http://www.w3.org/2000/svg" font-family="Segoe UI, Arial, sans-serif">
    <rect width="900" height="680" fill="#f8f9fa" rx="12"/>

    <text x="450" y="38" text-anchor="middle" font-size="20" font-weight="bold" fill="#232f3e">Project 2 — Static Website on S3 + CloudFront</text>
  <text x="450" y="58" text-anchor="middle" font-size="13" fill="#666">AWS Region: us-east-1</text>

    <rect x="30" y="75" width="840" height="580" rx="10" fill="none" stroke="#f90" stroke-width="2.5" stroke-dasharray="10,5"/>
  <text x="50" y="98" font-size="13" font-weight="bold" fill="#f90">AWS Regional Infrastructure: us-east-1</text>

    <rect x="370" y="82" width="220" height="38" rx="8" fill="#232f3e"/>
  <text x="480" y="106" text-anchor="middle" font-size="13" font-weight="bold" fill="white">Global Content Delivery Network</text>

    <line x1="480" y1="120" x2="480" y2="148" stroke="#555" stroke-width="2" marker-end="url(#arrow)"/>

    <rect x="360" y="148" width="240" height="44" rx="8" fill="#ff9900" />
  <text x="480" y="172" text-anchor="middle" font-size="12" font-weight="bold" fill="white">Global CloudFront Distribution</text>

    <line x1="480" y1="192" x2="480" y2="222" stroke="#555" stroke-width="2" marker-end="url(#arrow)"/>

    <rect x="360" y="222" width="240" height="44" rx="8" fill="#ff9900" />
  <text x="480" y="246" text-anchor="middle" font-size="12" font-weight="bold" fill="white">Origin Handoff (Global Origin)</text>

  <line x1="480" y1="266" x2="480" y2="296" stroke="#555" stroke-width="2" marker-end="url(#arrow)"/>
  <text x="495" y="282" font-size="11" fill="#555">Origin Request</text>

  <rect x="70" y="222" width="200" height="38" rx="8" fill="#232f3e"/>
  <text x="170" y="246" text-anchor="middle" font-size="13" font-weight="bold" fill="white">Internet / HTTPS</text>
  <line x1="270" y1="170" x2="355" y2="170" stroke="#555" stroke-width="2" marker-end="url(#arrow)"/>
  <text x="310" y="160" font-size="11" fill="#555">Public Traffic</text>
  <line x1="170" y1="260" x2="170" y2="290" stroke="#555" stroke-width="2" marker-end="url(#arrow)"/>
  <text x="185" y="280" font-size="11" fill="#555">Origin Flow</text>

  <line x1="245" y1="192" x2="245" y2="222" stroke="#555" stroke-width="2" marker-end="url(#arrow)"/>

    <rect x="55" y="296" width="380" height="312" rx="8" fill="#e8f4e8" stroke="#28a745" stroke-width="1.5"/>
  <text x="75" y="316" font-size="12" font-weight="bold" fill="#28a745">Regional Origin Conceptual Zone</text>

    <rect x="75" y="326" width="340" height="262" rx="8" fill="white" stroke="#ff9900" stroke-width="2"/>
  <rect x="75" y="326" width="340" height="30" rx="8" fill="#ff9900"/>
  <text x="245" y="346" text-anchor="middle" font-size="13" font-weight="bold" fill="white">Amazon S3 — [Your bucket name]</text>
  <text x="100" y="374" font-size="12" fill="#333">Bucket Region: us-east-1</text>
  <text x="100" y="392" font-size="12" fill="#333">Website Hosting: Enabled ✓</text>
  <text x="100" y="410" font-size="12" fill="#333">Index Document: index.html ✓</text>
  <text x="100" y="428" font-size="12" fill="#333">Error Document: error.html ✓</text>
  <text x="100" y="446" font-size="12" fill="#28a745">✓ Public Badge ✓ Accessible</text>
  
  <rect x="90" y="460" width="310" height="110" rx="6" fill="#ffe0b2" stroke="#f57c00" stroke-width="1.5"/>
  <text x="110" y="480" font-size="11" font-weight="bold" fill="#232f3e">Bucket Policy</text>
  <text x="110" y="500" font-size="10" fill="#333">Sid: PublicReadGetObject</text>
  <text x="110" y="515" font-size="10" fill="#333">Effect: Allow</text>
  <text x="110" y="530" font-size="10" fill="#333">Principal: *</text>
  <text x="110" y="545" font-size="10" fill="#333">Action: s3:GetObject</text>
  <text x="110" y="560" font-size="10" fill="#28a745">Resource: arn:aws:s3:::[bucket]/*</text>

    <rect x="465" y="296" width="380" height="60" rx="8" fill="#e8f4e8" stroke="#28a745" stroke-width="1.5" stroke-dasharray="6,4"/>
  <text x="485" y="322" font-size="12" font-weight="bold" fill="#28a745">S3 Website Endpoint logical zone</text>
  <text x="485" y="342" font-size="12" fill="#888">(Origin URL ending in s3-website-us-east-1...)</text>

  <line x1="655" y1="192" x2="655" y2="296" stroke="#555" stroke-width="2" marker-end="url(#arrow)"/>
  <text x="670" y="248" font-size="11" fill="#555">Origin Req Flow</text>

  <rect x="70" y="418" width="180" height="38" rx="8" fill="#eaf0fb" stroke="#1a73e8" stroke-width="1.5"/>
  <text x="160" y="442" text-anchor="middle" font-size="13" font-weight="bold" fill="#1a73e8">Update Traffic (CLI Sync)</text>
  <line x1="250" y1="437" x2="310" y2="437" stroke="#1a73e8" stroke-width="2.5" marker-end="url(#arrowBlue)"/>
  <text x="270" y="427" font-size="11" fill="#1a73e8">File Sync</text>

    <rect x="680" y="82" width="180" height="310" rx="8" fill="#fff8f0" stroke="#ff9900" stroke-width="1.5"/>
  <text x="770" y="102" text-anchor="middle" font-size="12" font-weight="bold" fill="#ff9900">Supporting Services</text>

  <rect x="695" y="110" width="150" height="44" rx="6" fill="#fff0e0" stroke="#ff9900" stroke-width="1"/>
  <text x="770" y="128" text-anchor="middle" font-size="11" font-weight="bold" fill="#232f3e">S3</text>
  <text x="770" y="144" text-anchor="middle" font-size="10" fill="#555">Static Website Hosting ✓</text>

  <rect x="695" y="162" width="150" height="44" rx="6" fill="#fff0e0" stroke="#ff9900" stroke-width="1"/>
  <text x="770" y="180" text-anchor="middle" font-size="11" font-weight="bold" fill="#232f3e">CloudFront</text>
  <text x="770" y="196" text-anchor="middle" font-size="10" fill="#555">Global CDN distribution ✓</text>

  <rect x="695" y="214" width="150" height="44" rx="6" fill="#fff0e0" stroke="#ff9900" stroke-width="1"/>
  <text x="770" y="232" text-anchor="middle" font-size="11" font-weight="bold" fill="#232f3e">IAM</text>
  <text x="770" y="248" text-anchor="middle" font-size="10" fill="#555">Bucket Policy ✓</text>

  <rect x="695" y="266" width="150" height="44" rx="6" fill="#fff0e0" stroke="#ff9900" stroke-width="1"/>
  <text x="770" y="284" text-anchor="middle" font-size="11" font-weight="bold" fill="#232f3e">AWS CLI</text>
  <text x="770" y="300" text-anchor="middle" font-size="10" fill="#555">s3 sync for upload ✓</text>

  <rect x="695" y="318" width="150" height="44" rx="6" fill="#fff0e0" stroke="#ff9900" stroke-width="1"/>
  <text x="770" y="336" text-anchor="middle" font-size="11" font-weight="bold" fill="#232f3e">CloudFront (Updates)</text>
  <text x="770" y="352" text-anchor="middle" font-size="10" fill="#555">cache invalidation ✓</text>

    <rect x="55" y="648" width="790" height="1" fill="#ddd"/>
  <text x="55" y="668" font-size="11" fill="#888">Legend: </text>
  <line x1="110" y1="663" x2="145" y2="663" stroke="#1a73e8" stroke-width="2.5" />
  <text x="150" y="668" font-size="11" fill="#888">Update sync traffic</text>
  <line x1="280" y1="663" x2="315" y2="663" stroke="#555" stroke-width="2"/>
  <text x="320" y="668" font-size="11" fill="#888">Public HTTPS traffic</text>
  <rect x="440" y="656" width="14" height="14" fill="#e8f4e8" stroke="#28a745" stroke-width="1.5"/>
  <text x="460" y="668" font-size="11" fill="#888">Regional Origin Zone</text>
  <rect x="580" y="656" width="14" height="14" fill="#ff9900" />
  <text x="600" y="668" font-size="11" fill="#888">Global CDN Zone</text>

    <defs>
    <marker id="arrow" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
      <polygon points="0 0, 10 3.5, 0 7" fill="#555"/>
    </marker>
    <marker id="arrowBlue" markerWidth="10" markerHeight="7" refX="9" refY="3.5" orient="auto">
      <polygon points="0 0, 10 3.5, 0 7" fill="#1a73e8"/>
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
