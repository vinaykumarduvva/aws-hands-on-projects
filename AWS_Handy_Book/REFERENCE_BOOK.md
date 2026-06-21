# 📖 AWS Handy Definitions: Reference Book

<img src="images/aws_reference_book.png" align="right" width="280" alt="AWS Reference Book" style="margin-left: 20px; margin-bottom: 20px;" />

*A curated study and documentation notebook for AWS services, ordered from **Beginner** ➔ **Advanced** within each service category.*

Use this guide to master key cloud architectures, CLI commands, Infrastructure as Code configurations, and operational trade-offs for AWS certification exams (CLF-C02, SAA-C03) and practical projects.

<br clear="right" />

---

## 🧭 Table of Contents

### 💻 [Compute Services](#category-compute)
1. [EC2 (Elastic Compute Cloud) 🟢](#1-ec2-elastic-compute-cloud)
2. [Lightsail 🟢](#2-lightsail)
3. [Elastic Beanstalk 🟢](#3-elastic-beanstalk)
4. [Lambda 🟡](#4-lambda)
5. [ECS (Elastic Container Service) 🟡](#5-ecs-elastic-container-service)
6. [Fargate 🟡](#6-fargate)
7. [EKS (Elastic Kubernetes Service) 🔴](#7-eks-elastic-kubernetes-service)
8. [Batch 🔴](#8-batch)
9. [Outposts 🔴](#9-outposts)

### 💾 [Storage Services](#category-storage)
10. [S3 (Simple Storage Service) 🟢](#10-s3-simple-storage-service)
11. [EBS (Elastic Block Store) 🟢](#11-ebs-elastic-block-store)
12. [Glacier (S3 Glacier Storage Classes) 🟢](#12-glacier-s3-glacier-storage-classes)
13. [EFS (Elastic File System) 🟡](#13-efs-elastic-file-system)
14. [Storage Gateway 🔴](#14-storage-gateway)
15. [FSx 🔴](#15-fsx)

---

# Category: Compute

## 1. EC2 (Elastic Compute Cloud)
*   **Difficulty:** 🟢 Beginner
*   **Level Rationale:** Conceptually maps to a familiar idea (a virtual server) and requires no prior AWS-specific knowledge to start.

> 💡 **Definition:** EC2 provides resizable virtual servers (instances) in the cloud, giving full control over the operating system, software stack, and configuration.

### ⚙️ Core Capabilities & Uses
*   Launch virtual machines from preconfigured or custom Amazon Machine Images (AMIs).
*   Choose instance types optimized for compute, memory, storage, or GPU workloads.
*   Attach block storage (EBS) and configure networking (VPC, security groups).
*   Scale manually or automatically (with Auto Scaling Groups).
*   Pay per second/hour, or commit to Reserved/Savings Plans for discounts.

### 🎯 Common Scenarios
*   Hosting web applications or web APIs.
*   Running legacy or custom software requiring OS-level access.
*   Self-managed databases or application servers.
*   Dev/test sandboxes.

### 💻 Quick Examples
*   **AWS CLI command to launch a micro instance:**
    ```bash
    aws ec2 run-instances --image-id ami-0abcdef1234567890 --instance-type t3.micro --key-name MyKey
    ```
*   **Terraform configuration:**
    ```hcl
    resource "aws_instance" "web" {
      ami           = "ami-0abcdef1234567890"
      instance_type = "t3.micro"
    }
    ```

### ⚠️ Key Concepts & Considerations
*   Billing is per-second (Linux) based on instance type and uptime.
*   Security groups act as virtual firewalls (stateful, allow-rules only).
*   Instance store is ephemeral (loses data on stop); EBS volumes persist independently of instance lifecycle.
*   Patching, scaling, and OS management are the customer's responsibility.

### 🔗 Related Services / Prerequisites
*   **Related:** VPC (networking), EBS (storage), IAM (access control).
*   **Prerequisite:** Basic Linux/Windows administration knowledge is helpful.

### 🚀 Next Step
Launch a `t3.micro` (free-tier eligible) EC2 instance in the console and SSH/Connect into it.

---

## 2. Lightsail
*   **Difficulty:** 🟢 Beginner
*   **Level Rationale:** Designed explicitly to simplify EC2/VPC/ELB concepts into a single bundled, beginner-friendly product.

> 💡 **Definition:** Lightsail is a simplified compute service offering pre-bundled virtual private servers with networking, storage, and DNS included at predictable, fixed monthly pricing.

### ⚙️ Core Capabilities & Uses
*   Launch VPS instances with predictable, bundled pricing.
*   Built-in load balancing, DNS management, and managed databases.
*   Simple container service for small containerized apps.
*   One-click application stacks (WordPress, LAMP, Node.js, etc.).

### 🎯 Common Scenarios
*   Small business websites or blogs.
*   Simple web apps without complex scaling needs.
*   Learning cloud basics before moving to EC2/VPC.

### 💻 Quick Examples
*   **AWS CLI command to launch a WordPress blueprint instance:**
    ```bash
    aws lightsail create-instances --instance-names MyServer --availability-zone us-east-1a --blueprint-id wordpress --bundle-id nano_2_0
    ```
*   **Architecture Outline:** Single Lightsail instance + Lightsail-managed DNS, no separate VPC configuration needed.

### ⚠️ Key Concepts & Considerations
*   Fixed monthly pricing simplifies budgeting versus EC2's granular billing.
*   Less flexible than EC2; fewer instance types and customization options.
*   Can be "upgraded" by connecting to a full VPC, but this is uncommon.
*   Good on-ramp service, not typically used in production enterprise architectures.

### 🔗 Related Services / Prerequisites
*   **Related:** Conceptually related to EC2 and Route 53.
*   **Prerequisites:** None required; designed as an EC2 alternative for simpler use cases.

### 🚀 Next Step
Spin up a Lightsail WordPress blueprint instance and access it via the assigned static IP.

---

## 3. Elastic Beanstalk
*   **Difficulty:** 🟢 Beginner
*   **Level Rationale:** Abstracts away infrastructure decisions; developers upload code and Beanstalk provisions everything else.

> 💡 **Definition:** Elastic Beanstalk is a Platform-as-a-Service (PaaS) that automatically provisions and manages the underlying infrastructure (EC2, load balancer, scaling) needed to run an uploaded application.

### ⚙️ Core Capabilities & Uses
*   Deploy applications by uploading code/containers; infrastructure is auto-provisioned.
*   Supports multiple platforms (Java, .NET, Node.js, Python, Ruby, Go, Docker, etc.).
*   Built-in health monitoring and rolling deployments.
*   Underlying resources (EC2, ELB, Auto Scaling) remain visible/adjustable if needed.

### 🎯 Common Scenarios
*   Developers who want to deploy quickly without managing infrastructure directly.
*   Standard web applications with predictable architecture needs.
*   Teams transitioning from traditional hosting to AWS without learning full IaC first.

### 💻 Quick Examples
*   **AWS CLI command to create an application wrapper:**
    ```bash
    aws elasticbeanstalk create-application --application-name MyApp
    ```
*   **Architecture Outline:** Beanstalk environment = ALB + Auto Scaling Group of EC2 instances, managed as one unit.

### ⚠️ Key Concepts & Considerations
*   Less control than raw EC2/VPC setup; opinionated defaults.
*   No additional charge for Beanstalk itself — pay only for underlying resources (EC2, ELB, etc.).
*   Good stepping stone toward understanding what EC2 + ELB + Auto Scaling do together.
*   Configuration via `.ebextensions` files for customization.

### 🔗 Related Services / Prerequisites
*   **Related:** EC2, Elastic Load Balancing, Auto Scaling (all managed under the hood).
*   **Prerequisites:** Basic understanding of your application's runtime requirements.

### 🚀 Next Step
Deploy a sample Node.js or Python app via the Elastic Beanstalk console quick-start.

---

## 4. Lambda
*   **Difficulty:** 🟡 Intermediate
*   **Level Rationale:** Simple to invoke, but understanding event-driven design, cold starts, and IAM execution roles requires moving beyond basic VM thinking.

> 💡 **Definition:** Lambda is a serverless compute service that runs code in response to events without provisioning or managing servers, billing only for execution time.

### ⚙️ Core Capabilities & Uses
*   Run code triggered by events (S3 uploads, API Gateway calls, EventBridge schedule, SQS queues, etc.).
*   Automatic scaling — concurrent executions handled transparently.
*   Supports multiple runtimes (Node.js, Python, Java, Go, custom via Docker containers).
*   No server or OS management; pay only for compute time consumed.

### 🎯 Common Scenarios
*   Event-driven backends (e.g., image processing on S3 upload).
*   API backends paired with API Gateway.
*   Scheduled automation tasks (cron-like jobs via EventBridge).
*   Glue logic connecting other AWS services.

### 💻 Quick Examples
*   **AWS CLI command to invoke a function:**
    ```bash
    aws lambda invoke --function-name MyFunction output.json
    ```
*   **Terraform configuration:**
    ```hcl
    resource "aws_lambda_function" "example" {
      function_name = "my_function"
      handler       = "index.handler"
      runtime       = "nodejs18.x"
      role          = aws_iam_role.lambda_exec.arn
      filename      = "function.zip"
    }
    ```

### ⚠️ Key Concepts & Considerations
*   Execution timeout limit (max 15 minutes per invocation).
*   Cold starts can add latency for infrequently invoked functions.
*   Requires an IAM execution role granting the function specific permissions.
*   Billing based on number of requests and execution duration (ms-level granularity).
*   Concurrency limits exist per account/region (can be adjusted).

### 🔗 Related Services / Prerequisites
*   **Related:** IAM (execution roles), API Gateway, EventBridge, S3 (common event sources).
*   **Prerequisites:** Basic understanding of event-driven architecture recommended.

### 🚀 Next Step
Create a Lambda function triggered by an S3 upload event and log the event details to CloudWatch.

---

## 5. ECS (Elastic Container Service)
*   **Difficulty:** 🟡 Intermediate
*   **Level Rationale:** Requires understanding of containers and task/service definitions, though AWS abstracts orchestration complexity versus raw Kubernetes.

> 💡 **Definition:** ECS is a fully managed container orchestration service for running and scaling Docker containers using AWS-native task definitions and clusters.

### ⚙️ Core Capabilities & Uses
*   Define and run containerized applications via task definitions.
*   Choose EC2-backed or Fargate (serverless) launch types.
*   Service auto-scaling and integrated load balancing.
*   Native integration with IAM, CloudWatch, and VPC networking.

### 🎯 Common Scenarios
*   Microservices architectures using Docker containers.
*   Batch or scheduled containerized jobs.
*   Migrating containerized workloads to AWS without full Kubernetes complexity.

### 💻 Quick Examples
*   **AWS CLI command to create an ECS cluster:**
    ```bash
    aws ecs create-cluster --cluster-name MyCluster
    ```
*   **Terraform configuration:**
    ```hcl
    resource "aws_ecs_cluster" "main" {
      name = "my-cluster"
    }
    ```

### ⚠️ Key Concepts & Considerations
*   Task definitions specify container image, CPU/memory, and networking mode.
*   EC2 launch type requires managing underlying instances; Fargate removes that layer.
*   IAM task roles control what each container can access.
*   Service discovery and load balancing integrate with ALB/NLB.

### 🔗 Related Services / Prerequisites
*   **Related:** ECR (image registry), Fargate, VPC, IAM.
*   **Prerequisites:** Docker and container fundamentals required.

### 🚀 Next Step
Containerize a simple app, push it to ECR, and deploy it as an ECS Fargate service.

---

## 6. Fargate
*   **Difficulty:** 🟡 Intermediate
*   **Level Rationale:** Simplifies container infrastructure but still requires container and task-definition knowledge from ECS/EKS.

> 💡 **Definition:** Fargate is a serverless compute engine for containers, removing the need to provision or manage the underlying EC2 instances for ECS or EKS workloads.

### ⚙️ Core Capabilities & Uses
*   Run containers without managing servers or clusters of EC2 instances.
*   Works as a launch type within ECS or EKS.
*   Automatic scaling per-task based on defined CPU/memory.
*   Pay-per-task based on vCPU/memory allocated and runtime.

### 🎯 Common Scenarios
*   Teams wanting container benefits without infrastructure management overhead.
*   Variable or bursty containerized workloads.
*   Simplifying ECS/EKS operations for smaller teams.

### 💻 Quick Examples
*   **AWS CLI command to run a task on Fargate:**
    ```bash
    aws ecs run-task --cluster MyCluster --launch-type FARGATE --task-definition my-task
    ```
*   **Architecture Outline:** ECS Service (Fargate launch type) ➔ no EC2 instances visible or managed by user.

### ⚠️ Key Concepts & Considerations
*   Generally higher per-unit cost than self-managed EC2-backed clusters, trading cost for operational simplicity.
*   No SSH access to underlying infrastructure (fully abstracted).
*   Task-level resource limits (CPU/memory) must be defined explicitly.
*   Networking still requires VPC/subnet configuration (`awsvpc` network mode).

### 🔗 Related Services / Prerequisites
*   **Related:** ECR, VPC, IAM task roles.
*   **Prerequisites:** Requires ECS or EKS as the orchestration layer.

### 🚀 Next Step
Convert an existing ECS EC2-launch-type service to Fargate launch type and compare configuration differences.

---

## 7. EKS (Elastic Kubernetes Service)
*   **Difficulty:** 🔴 Advanced
*   **Level Rationale:** Requires solid Kubernetes knowledge on top of AWS-specific networking, IAM, and add-on configuration.

> 💡 **Definition:** EKS is a managed Kubernetes service that runs the Kubernetes control plane on AWS, letting users deploy standard Kubernetes workloads without self-managing master nodes.

### ⚙️ Core Capabilities & Uses
*   Fully managed Kubernetes control plane (highly available, patched by AWS).
*   Worker nodes run on EC2 or Fargate.
*   Native integration with IAM (via IRSA — IAM Roles for Service Accounts).
*   Supports standard Kubernetes tooling (`kubectl`, `Helm`, etc.).

### 🎯 Common Scenarios
*   Organizations standardized on Kubernetes across multi-cloud or hybrid environments.
*   Complex microservices requiring fine-grained orchestration control.
*   Teams with existing Kubernetes expertise migrating to AWS.

### 💻 Quick Examples
*   **AWS CLI command to create a cluster:**
    ```bash
    aws eks create-cluster --name MyCluster --role-arn arn:aws:iam::123456789012:role/EksRole --resources-vpc-config subnetIds=subnet-abc,subnet-def
    ```
*   **Kubernetes Manifest Execution:** Standard Kubernetes manifests work natively (`kubectl apply -f deployment.yaml`) against EKS clusters.

### ⚠️ Key Concepts & Considerations
*   Requires Kubernetes conceptual knowledge (pods, deployments, services, namespaces) independent of AWS.
*   Control plane has an hourly cost separate from worker node costs.
*   IAM-to-Kubernetes-RBAC mapping adds a security layer to learn.
*   Cluster upgrades and add-on management require ongoing operational attention.

### 🔗 Related Services / Prerequisites
*   **Related:** VPC (networking/CNI plugin), IAM (IRSA), ECR, Fargate (optional worker type).
*   **Prerequisites:** Strong Kubernetes fundamentals required.

### 🚀 Next Step
Deploy a managed EKS cluster using `eksctl` and run a sample deployment with `kubectl`.

---

## 8. Batch
*   **Difficulty:** 🔴 Advanced
*   **Level Rationale:** Requires combining compute provisioning, job queue design, and container/IAM configuration for non-trivial batch workloads.

> 💡 **Definition:** AWS Batch dynamically provisions compute resources to run batch computing jobs at scale, handling queuing, scheduling, and scaling automatically.

### ⚙️ Core Capabilities & Uses
*   Define job queues, compute environments, and job definitions.
*   Automatically provisions EC2 or Fargate compute based on job requirements.
*   Handles job retries, dependencies, and priority scheduling.
*   Scales compute environment to zero when idle.

### 🎯 Common Scenarios
*   Large-scale parallel data processing (genomics, simulations, rendering).
*   ETL or batch analytics jobs run on a schedule or event trigger.
*   Workloads with highly variable compute demand.

### 💻 Quick Examples
*   **AWS CLI command to submit a batch job:**
    ```bash
    aws batch submit-job --job-name MyJob --job-queue MyQueue --job-definition MyJobDef
    ```
*   **Architecture Outline:** Job Queue ➔ Compute Environment (EC2/Fargate) ➔ Job Definition (container image + resource requirements).

### ⚠️ Key Concepts & Considerations
*   Requires defining compute environments (managed or unmanaged) correctly sized for job needs.
*   Jobs run as containers, so container/Docker knowledge is required.
*   Integrates with Spot Instances for cost optimization, requiring interruption-handling awareness.
*   IAM roles needed for both the Batch service and job execution.

### 🔗 Related Services / Prerequisites
*   **Related:** ECS (Batch uses ECS under the hood), EC2, IAM, ECR.
*   **Prerequisites:** Container fundamentals and job-scheduling concepts.

### 🚀 Next Step
Set up a basic compute environment and job queue, then submit a sample containerized batch job.

---

## 9. Outposts
*   **Difficulty:** 🔴 Advanced
*   **Level Rationale:** Involves hybrid infrastructure planning, physical hardware logistics, and enterprise networking — well beyond typical cloud-only setups.

> 💡 **Definition:** AWS Outposts extends AWS infrastructure and services to on-premises data centers, delivering a consistent hybrid cloud experience using AWS-managed hardware installed on-site.

### ⚙️ Core Capabilities & Uses
*   Run select AWS services (EC2, EBS, ECS/EKS, RDS) locally on-premises.
*   Physical AWS rack hardware delivered, installed, and maintained by AWS.
*   Consistent APIs/tools as the AWS cloud, extended to local infrastructure.
*   Connects back to a parent AWS Region for management and additional services.

### 🎯 Common Scenarios
*   Low-latency workloads requiring on-premises processing (manufacturing floors, hospitals).
*   Data residency requirements where data cannot leave a specific physical location.
*   Hybrid architectures migrating gradually to full cloud.

### 💻 Quick Examples
*   **AWS CLI command to list Outposts associated with your account:**
    ```bash
    aws outposts list-outposts
    ```
*   **Architecture Outline:** On-prem Outposts rack ↔ VPN/Direct Connect ↔ parent AWS Region, running EC2 instances locally with cloud-style APIs.

### ⚠️ Key Concepts & Considerations
*   Requires physical site prep (power, space, cooling) and a contractual capacity commitment.
*   Network connectivity back to AWS Region is required for control plane operations.
*   Pricing involves both upfront and ongoing infrastructure costs (not purely consumption-based).
*   Service availability on Outposts is a subset of full AWS Region service availability.

### 🔗 Related Services / Prerequisites
*   **Related:** EC2, EBS, ECS/EKS, RDS (subset of services deployable on Outposts).
*   **Prerequisites:** Solid understanding of VPC, Direct Connect/VPN, and hybrid network architecture required.

### 🚀 Next Step
Review AWS's Outposts site requirements documentation to understand physical and network prerequisites before any deployment planning.

---

# Category: Storage

## 10. S3 (Simple Storage Service)
*   **Difficulty:** 🟢 Beginner
*   **Level Rationale:** Conceptually simple (upload/download files via API or console) with no infrastructure to provision.

> 💡 **Definition:** S3 is an object storage service for storing and retrieving any amount of data — files, backups, static assets — accessed via a simple HTTP-based API.

### ⚙️ Core Capabilities & Uses
*   Store objects (files) in buckets, organized by key (path-like naming).
*   Multiple storage classes for different access patterns and cost (Standard, Infrequent Access, Glacier).
*   Versioning, lifecycle policies, and cross-region replication.
*   Static website hosting and event notifications (e.g., trigger Lambda on upload).

### 🎯 Common Scenarios
*   Backup and archival storage.
*   Hosting static website assets (HTML, CSS, images).
*   Data lake storage for analytics pipelines.
*   Storing application file uploads (images, documents).

### 💻 Quick Examples
*   **AWS CLI command to copy a local file to S3:**
    ```bash
    aws s3 cp myfile.txt s3://my-bucket/myfile.txt
    ```
*   **Terraform configuration:**
    ```hcl
    resource "aws_s3_bucket" "data" {
      bucket = "my-unique-bucket-name"
    }
    ```

### ⚠️ Key Concepts & Considerations
*   Bucket names must be globally unique across all AWS accounts.
*   Default access is private; public access requires explicit bucket policy/ACL changes (and removal of Block Public Access settings).
*   Pricing based on storage volume, requests, and data transfer out.
*   99.999999999% (11 nines) durability design target; not the same as availability.
*   Lifecycle rules can auto-transition or expire objects to reduce cost.

### 🔗 Related Services / Prerequisites
*   **Related:** IAM (bucket policies/permissions), CloudFront (CDN in front of S3), Lambda (event triggers).
*   **Prerequisites:** No major prerequisites; good first AWS storage service to learn.

### 🚀 Next Step
Create a bucket, upload a file via CLI, and try generating a pre-signed URL for temporary access.

---

## 11. EBS (Elastic Block Store)
*   **Difficulty:** 🟢 Beginner
*   **Level Rationale:** Conceptually maps to a familiar idea (a hard drive attached to a server) and is typically learned alongside EC2.

> 💡 **Definition:** EBS provides persistent block-level storage volumes that attach to EC2 instances, functioning like a virtual hard drive.

### ⚙️ Core Capabilities & Uses
*   Create volumes of various types (SSD, HDD) optimized for IOPS or throughput.
*   Attach/detach volumes to EC2 instances within the same Availability Zone.
*   Take point-in-time snapshots stored in S3 for backup/recovery.
*   Resize volumes and change types without downtime (in most cases).

### 🎯 Common Scenarios
*   Boot volumes for EC2 instances.
*   Database storage requiring consistent, low-latency disk performance.
*   Application data requiring persistence independent of instance lifecycle.

### 💻 Quick Examples
*   **AWS CLI command to create an EBS volume:**
    ```bash
    aws ec2 create-volume --availability-zone us-east-1a --size 20 --volume-type gp3
    ```
*   **Terraform configuration:**
    ```hcl
    resource "aws_ebs_volume" "data" {
      availability_zone = "us-east-1a"
      size              = 20
      type              = "gp3"
    }
    ```

### ⚠️ Key Concepts & Considerations
*   Volumes are zonal — must reside in the same AZ as the attached EC2 instance.
*   Snapshots are incremental and stored in S3, billed separately from volume storage.
*   Volume types (gp3, io2, st1, sc1) differ significantly in cost and performance characteristics.
*   Deleting an instance does not automatically delete attached EBS volumes unless configured to do so ("delete on termination").

### 🔗 Related Services / Prerequisites
*   **Related:** EC2 (volumes attach to instances), S3 (snapshot storage backend).
*   **Prerequisites:** Basic EC2 knowledge recommended before learning EBS in depth.

### 🚀 Next Step
Attach an additional EBS volume to a running EC2 instance and mount/format it within the OS.

---

## 12. Glacier (S3 Glacier Storage Classes)
*   **Difficulty:** 🟢 Beginner
*   **Level Rationale:** Functionally an extension of S3 (same API, different storage class), so it adds minimal new conceptual overhead once S3 is understood.

> 💡 **Definition:** S3 Glacier refers to a set of low-cost S3 storage classes designed for data archiving, with retrieval times ranging from minutes to hours depending on the tier chosen.

### ⚙️ Core Capabilities & Uses
*   Significantly lower per-GB storage cost than S3 Standard.
*   Multiple tiers: Instant Retrieval, Flexible Retrieval, and Deep Archive (slowest, cheapest).
*   Managed via standard S3 API and lifecycle policies.
*   Configurable retrieval speed vs. cost tradeoffs.

### 🎯 Common Scenarios
*   Long-term compliance/regulatory data retention.
*   Backup archives rarely accessed.
*   Media archives (old footage, logs) kept for historical reference.

### 💻 Quick Examples
*   **AWS CLI command to copy a file directly to Glacier class:**
    ```bash
    aws s3 cp myfile.txt s3://my-bucket/myfile.txt --storage-class GLACIER
    ```
*   **Architecture Outline:** S3 lifecycle rule auto-transitions objects from Standard ➔ Glacier after 90 days.

### ⚠️ Key Concepts & Considerations
*   Retrieval from Glacier (non-instant tiers) is not immediate — ranges from minutes (Expedited) to ~12 hours (Deep Archive).
*   Early-deletion fees apply if objects are removed before minimum storage duration (varies by tier).
*   Retrieval requests incur additional cost beyond storage pricing.
*   Best used via S3 Lifecycle policies rather than manual class assignment for large-scale archiving.

### 🔗 Related Services / Prerequisites
*   **Related:** Requires S3 fundamentals; Glacier is accessed through the S3 API/console.

### 🚀 Next Step
Set up an S3 lifecycle rule that transitions objects to Glacier Deep Archive after a defined period.

---

## 13. EFS (Elastic File System)
*   **Difficulty:** 🟡 Intermediate
*   **Level Rationale:** Requires understanding NFS concepts and how shared, multi-instance file access differs from block storage (EBS).

> 💡 **Definition:** EFS is a managed, scalable NFS file system that can be mounted concurrently by multiple EC2 instances or containers across Availability Zones.

### ⚙️ Core Capabilities & Uses
*   Shared file storage accessible by multiple compute resources simultaneously.
*   Automatically scales storage capacity up/down as files are added/removed.
*   Multiple performance modes (General Purpose, Max I/O) and throughput modes.
*   Mountable from EC2, ECS, Lambda, and on-premises servers (via Direct Connect/VPN).

### 🎯 Common Scenarios
*   Shared content directories across a fleet of web servers.
*   Container workloads needing persistent, shared storage.
*   Lift-and-shift of applications relying on traditional NFS file shares.

### 💻 Quick Examples
*   **AWS CLI command to create an EFS file system:**
    ```bash
    aws efs create-file-system --performance-mode generalPurpose
    ```
*   **Architecture Outline:** EFS mount targets in multiple AZs ↔ mounted by EC2 instances in an Auto Scaling Group, all sharing the same file data.

### ⚠️ Key Concepts & Considerations
*   Pricing is based on storage used (pay-as-you-grow), unlike pre-provisioned EBS volume sizing.
*   Requires mount targets configured per-AZ for multi-AZ access.
*   Performance scales with storage size in General Purpose mode (or provisioned throughput for predictable performance).
*   Security via VPC security groups on mount targets and optional IAM-based access points.

### 🔗 Related Services / Prerequisites
*   **Related:** EC2/ECS (compute that mounts EFS), VPC (networking/mount targets), IAM (access points).
*   **Prerequisites:** Basic NFS/Linux file-sharing concepts helpful.

### 🚀 Next Step
Create an EFS file system, mount it on two separate EC2 instances, and verify shared file visibility.

---

## 14. Storage Gateway
*   **Difficulty:** 🔴 Advanced
*   **Level Rationale:** Involves hybrid architecture design, on-premises hardware/VM setup, and understanding of multiple gateway types and caching behavior.

> 💡 **Definition:** Storage Gateway is a hybrid storage service connecting on-premises environments to AWS cloud storage, presenting cloud storage through standard on-premises protocols (NFS, SMB, iSCSI).

### ⚙️ Core Capabilities & Uses
*   **File Gateway:** presents S3 as an NFS/SMB file share.
*   **Volume Gateway:** presents iSCSI block storage backed by S3, with local caching.
*   **Tape Gateway:** virtual tape library backed by S3/Glacier, for backup software compatibility.
*   Local caching of frequently accessed data for low-latency on-premises access.

### 🎯 Common Scenarios
*   Extending on-premises storage capacity into the cloud without app changes.
*   Cloud-based backup/disaster recovery for on-premises systems.
*   Replacing physical tape backup infrastructure with cloud-backed virtual tapes.

### 💻 Quick Examples
*   **AWS CLI command to list gateways:**
    ```bash
    aws storagegateway list-gateways
    ```
*   **Architecture Outline:** On-prem application ↔ Storage Gateway appliance (VM or hardware) ↔ S3/Glacier in AWS, with local cache for hot data.

### ⚠️ Key Concepts & Considerations
*   Requires deploying a gateway appliance (VM image or physical hardware) on-premises.
*   Network bandwidth to AWS affects sync performance and cache miss latency.
*   Different gateway types solve different problems — choosing the wrong type leads to poor fit.
*   Billing combines gateway usage, S3/Glacier storage, and data transfer costs.

### 🔗 Related Services / Prerequisites
*   **Related:** S3, Glacier (backing storage).
*   **Prerequisites:** Solid on-premises networking and storage protocol knowledge (NFS/SMB/iSCSI). VPN or Direct Connect typically recommended for production use.

### 🚀 Next Step
Review AWS's gateway-type decision guide (File vs Volume vs Tape) to map it against a specific hybrid use case before deploying.

---

## 15. FSx
*   **Difficulty:** 🔴 Advanced
*   **Level Rationale:** Requires knowledge of specific third-party file system protocols (Windows, Lustre, NetApp ONTAP, OpenZFS) and workload-specific tuning.

> 💡 **Definition:** FSx provides fully managed file systems built on popular third-party file system technologies — Windows File Server, Lustre, NetApp ONTAP, and OpenZFS — each optimized for specific workloads.

### ⚙️ Core Capabilities & Uses
*   **FSx for Windows File Server:** SMB-based file shares with Active Directory integration.
*   **FSx for Lustre:** high-performance file system for HPC and machine learning workloads.
*   **FSx for NetApp ONTAP:** enterprise NAS features (snapshots, cloning, replication) familiar to NetApp users.
*   **FSx for OpenZFS:** high-performance file storage with ZFS features (snapshots, compression).

### 🎯 Common Scenarios
*   Windows-based enterprise applications requiring native SMB file shares.
*   High-performance computing and ML training requiring fast, parallel file access (Lustre).
*   Enterprises migrating existing NetApp-based workflows to AWS.

### 💻 Quick Examples
*   **AWS CLI command to create a Windows FSx file system:**
    ```bash
    aws fsx create-file-system --file-system-type WINDOWS --storage-capacity 300 --subnet-ids subnet-abc123
    ```
*   **Architecture Outline:** FSx for Lustre file system ↔ linked to an S3 bucket as the data repository, accessed by EC2-based HPC cluster nodes.

### ⚠️ Key Concepts & Considerations
*   Choosing the right FSx variant depends heavily on workload type and existing technology stack.
*   FSx for Windows requires AWS Managed Microsoft AD or self-managed AD integration for full feature use.
*   Pricing varies significantly by variant and provisioned throughput/IOPS.
*   Not a one-size-fits-all service — requires understanding workload requirements before provisioning.

### 🔗 Related Services / Prerequisites
*   **Related:** Directory Service / Active Directory (for Windows variant), VPC, S3 (Lustre data repository integration).
*   **Prerequisites:** Familiarity with the specific underlying file system technology (SMB, Lustre, ZFS, ONTAP) is valuable.

### 🚀 Next Step
Identify which FSx variant matches a specific workload (e.g., Windows file shares vs. HPC) and review its dedicated getting-started guide.
