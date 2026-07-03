# 🧹 Project 10 Cleanup Guide

To avoid incurring any unexpected charges on your AWS account, it is important to delete all the resources provisioned during this project. Follow these steps in order to cleanly tear down the infrastructure.

> [!WARNING]
> **ASG Warning**: The Auto Scaling Group will continuously re-launch instances if you terminate them manually without first deleting or scaling down the ASG. Always set desired capacity to 0 or delete the ASG before terminating instances.

## 1. Scale ASG to Zero and Delete

- [ ] Go to the **EC2 Console** > **Auto Scaling Groups**.
- [ ] Select **`web-server-asg`**.
- [ ] Click **Edit** and set Min, Max, and Desired to **0**.
- [ ] Wait for all instances to terminate (~1 minute).
- [ ] Select the ASG again and click **Delete**.

Alternatively via CLI:
```powershell
aws autoscaling update-auto-scaling-group `
    --auto-scaling-group-name web-server-asg `
    --min-size 0 --max-size 0 --desired-capacity 0

Start-Sleep -Seconds 60

aws autoscaling delete-auto-scaling-group `
    --auto-scaling-group-name web-server-asg `
    --force-delete
```

## 2. Delete the Application Load Balancer

- [ ] Go to the **EC2 Console** > **Load Balancers**.
- [ ] Select **`my-alb`**.
- [ ] Click **Actions** > **Delete load balancer**.
- [ ] Type `confirm` and click **Delete**.
- [ ] Wait ~30 seconds for the ALB to fully deregister.

## 3. Delete the Target Group

- [ ] Go to the **EC2 Console** > **Target Groups**.
- [ ] Select **`web-server-tg`**.
- [ ] Click **Actions** > **Delete**.
- [ ] Confirm deletion.

> [!NOTE]
> If deletion fails with "Target group is currently in use", wait for the ALB to finish deleting and try again.

## 4. Delete the Launch Template

- [ ] Go to the **EC2 Console** > **Launch Templates**.
- [ ] Select **`web-server-lt`**.
- [ ] Click **Actions** > **Delete template**.
- [ ] Type `Delete` and confirm.

## 5. Delete Security Groups

- [ ] Go to the **EC2 Console** > **Security Groups**.
- [ ] Select **`asg-ec2-sg`** and click **Actions** > **Delete security groups**.
- [ ] Select **`alb-sg`** and click **Actions** > **Delete security groups**.

> [!NOTE]
> Delete `asg-ec2-sg` first (it references `alb-sg`). If deletion fails, wait 60 seconds for ENIs to release and retry.

## 6. Verify All Instances Are Terminated

- [ ] Go to the **EC2 Console** > **Instances**.
- [ ] Filter by tag `Project: project-10-asg-alb`.
- [ ] Verify all instances show state **Terminated**.

---

## Deletion Order Summary

```text
1. ASG      → stops launching new instances
2. ALB      → releases ENIs and public DNS
3. Target Group → can only delete after ALB is gone
4. Launch Template → safe to delete anytime after ASG
5. Security Groups → delete EC2 SG first, then ALB SG
```

---

**🎉 Cleanup Complete!**
Your AWS environment is now clean from Project 10 resources and you will not incur further charges related to this project.
