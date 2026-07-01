# Testing Guide

Once the CloudFormation stack is successfully deployed (`CREATE_COMPLETE`), follow these steps to verify that the infrastructure is working as expected.

## 1. Verify Application Availability and Load Balancing
1. Navigate to the CloudFormation Console, select your stack, and go to the **Outputs** tab.
2. Locate the `ALBUrl` output value.
3. Open this URL in your web browser. You should see the "CloudFormation Deployed Instance" page.
4. Note the **Instance ID** and **AZ** on the page.
5. Hard-refresh the page (Ctrl+F5 or Cmd+Shift+R) a few times. You should see the Instance ID and AZ change as the Load Balancer distributes your requests across the multiple instances in the Auto Scaling Group.

## 2. Test High Availability / Self-Healing
1. Open the EC2 Console and navigate to **Instances**.
2. Select one of the running instances deployed by your stack and manually **Terminate** it.
3. Navigate to **Target Groups**, select your target group, and view the targets. You will see the terminated instance become unhealthy/draining.
4. Wait a few minutes. The Auto Scaling Group will detect the termination and automatically launch a new instance to replace it, bringing the desired capacity back to 2.

## 3. Test Auto Scaling (Scale Out)
To verify the CPU-based scaling policy, we need to artificially generate load on the instances.
1. Connect to one of your EC2 instances (you will need to temporarily allow SSH access and ensure you have the Key Pair, or use Session Manager if you attach the appropriate IAM role).
2. Install a stress-testing tool:
   ```bash
   sudo amazon-linux-extras install epel -y  # If on AL2
   sudo yum install stress -y
   ```
3. Run the stress tool to max out the CPU:
   ```bash
   stress --cpu 1 --timeout 300
   ```
4. Monitor the CloudWatch Alarm for your ASG, or simply watch the ASG capacity in the EC2 console. After a few minutes of high CPU, the ASG will launch additional instances.
