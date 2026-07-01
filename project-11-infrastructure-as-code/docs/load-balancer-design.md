# Application Load Balancer Design

The Application Load Balancer (ALB) serves as the single point of contact for external users, distributing incoming web traffic across multiple EC2 instances in different Availability Zones.

## Load Balancer Configuration (`ApplicationLoadBalancer`)

- **Scheme**: `internet-facing` (Resolves to public IP addresses).
- **Subnets**: Attached to `PublicSubnetA` and `PublicSubnetB`. The ALB nodes must be placed in public subnets so they have a route to the Internet Gateway.
- **Type**: `application` (Operates at Layer 7 - HTTP/HTTPS, ideal for web traffic).
- **Security Groups**: Associated with `ALBSecurityGroup` which permits inbound HTTP traffic from anywhere (`0.0.0.0/0`).

## Listener Configuration (`ALBListener`)

The Listener process checks for connection requests.

- **Protocol**: `HTTP`
- **Port**: `80`
- **Default Action**: `forward` (Forwards all traffic to the Target Group).

*(Note: In a production environment, you would typically configure an HTTPS listener on Port 443 with an SSL certificate, and redirect Port 80 to 443).*

## Target Group Configuration (`WebServerTargetGroup`)

The Target Group is the destination for the traffic routed by the ALB.

- **Protocol**: `HTTP`
- **Port**: `80`
- **Health Checks**: Checks the root path (`/`) every 30 seconds to ensure the web server is responsive.

The Auto Scaling Group automatically registers new instances with this Target Group, and deregisters instances when they are terminated, ensuring the ALB always has an up-to-date list of healthy backend servers.
