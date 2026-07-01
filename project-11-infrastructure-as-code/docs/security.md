# Security Design

This project follows the Principle of Least Privilege when designing network security for the infrastructure. The primary security mechanism is the use of chained AWS Security Groups.

## Security Groups

The stack defines two security groups that work together:

### 1. ALB Security Group (`ALBSecurityGroup`)
This group is attached to the Application Load Balancer. It is the public face of the application.
- **Inbound (Ingress)**: Allows HTTP (Port `80`) traffic from **Anywhere** (`0.0.0.0/0`).
- **Outbound (Egress)**: By default in CloudFormation, allows all outbound traffic.

### 2. EC2 Security Group (`EC2SecurityGroup`)
This group is attached to the EC2 instances via the Launch Template. It protects the backend servers.
- **Inbound (Ingress)**: Allows HTTP (Port `80`) traffic **ONLY** from the `ALBSecurityGroup`. 
- **Outbound (Egress)**: Allows all outbound traffic (necessary for `yum update` and downloading packages during the User Data script execution).

**Security Benefit:**
By specifying the `ALBSecurityGroup` as the source in the `EC2SecurityGroup` ingress rule (`SourceSecurityGroupId: !Ref ALBSecurityGroup`), we prevent users from bypassing the Load Balancer and accessing the EC2 instances directly via their public IPs.

## SSH Access
By default, the template **does not** open Port 22 (SSH) in the `EC2SecurityGroup`. This is a best practice for immutable infrastructure where instances are replaced rather than patched manually. 
If SSH access is absolutely required for debugging, you should either:
1. Use AWS Systems Manager Session Manager (requires adding an IAM Instance Profile to the Launch Template).
2. Add a Port 22 ingress rule to the `EC2SecurityGroup` restricted strictly to your administrative IP address (never `0.0.0.0/0`).
