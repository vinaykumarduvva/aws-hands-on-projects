#!/bin/bash
# Runs as root on first boot via EC2 User Data
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<html>
<head><title>My EC2 Web Server</title></head>
<body style='font-family:Arial;text-align:center;padding:60px;background:#f0f2f5'>
<h1 style='color:#232f3e'>EC2 Web Server is Running</h1>
<p style='color:#555'>Hosted on Amazon EC2 t2.micro - Amazon Linux 2023</p>
<p style='color:#555'>Project 3 - AWS Cloud Engineering Bootcamp</p>
</body>
</html>" > /var/www/html/index.html