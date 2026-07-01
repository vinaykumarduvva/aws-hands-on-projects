# Auto Scaling Policies

Our infrastructure uses an AWS Auto Scaling Group (ASG) combined with a Target Tracking Scaling Policy to automatically adjust the number of running EC2 instances based on current demand.

## Auto Scaling Group Configuration

- **Minimum Size (`MinInstances`)**: 2 (Default)
- **Maximum Size (`MaxInstances`)**: 4 (Default)
- **Desired Capacity (`DesiredInstances`)**: 2 (Default)
- **Subnets**: Deployed across `PublicSubnetA` and `PublicSubnetB` for multi-AZ high availability.
- **Health Check Type**: `ELB` (Ensures the ASG replaces instances that fail Load Balancer health checks, not just EC2 status checks).
- **Grace Period**: `120` seconds (Allows instances time to run their User Data script and start Apache before health checks begin).

## Target Tracking Scaling Policy

We utilize a **Target Tracking Scaling Policy** (`CPUScalingPolicy`), which acts similarly to a thermostat. You set the target metric, and AWS handles the underlying CloudWatch alarms and scaling actions.

- **Metric**: `ASGAverageCPUUtilization`
- **Target Value**: `50.0%`
- **Estimated Instance Warmup**: `120` seconds

### How it Works:
1. **Scale Out**: If the average CPU utilization across all instances in the ASG goes above 50%, the ASG will launch new instances (up to the Maximum Size) to bring the average back down.
2. **Scale In**: If the average CPU utilization drops well below 50%, the ASG will terminate instances (down to the Minimum Size) to bring the average back up and save costs.
3. **Warmup**: The 120-second warmup period prevents the ASG from over-scaling by giving newly launched instances time to boot and start contributing to the metrics before further scaling decisions are made.
