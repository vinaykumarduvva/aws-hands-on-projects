const commandsData = [
            {
                category: "Beginner",
                command: "aws sts get-caller-identity",
                service: "IAM",
                action: "Verify Identity",
                purpose: "Retrieves details about the IAM identity (User, Role, or Federated Profile) currently active in your CloudShell session.",
                meaning: "<b>aws</b>: Invokes the AWS CLI.<br><b>sts</b>: Points to the Security Token Service.<br><b>get-caller-identity</b>: The specific action requesting current session credentials metadata.",
                usage: "Frequently used as the 'hello world' of the AWS CLI or when you first open CloudShell to verify which account ID, user ARN, and role session you are operating under before running destructive commands.",
                reason: "<b>Security and Context Validation.</b> In environments where cross-account access or multiple role assumptions are common, this command guarantees you do not execute commands in the wrong AWS environment or with unintended privilege scopes."
            },
            {
                category: "Beginner",
                command: "aws s3 ls",
                service: "S3",
                action: "List Buckets",
                purpose: "Lists all Amazon Simple Storage Service (S3) buckets associated with the active AWS account, or lists the contents of a specific bucket.",
                meaning: "<b>aws</b>: Invokes the AWS CLI.<br><b>s3</b>: Interacts with the Amazon S3 service.<br><b>ls</b>: The directory listing command (analogous to the Unix ls).",
                usage: "Used to quickly browse storage structures. Running 'aws s3 ls' lists all buckets, while running 'aws s3 ls s3://my-bucket-name/' lists files and subdirectories inside that specific bucket.",
                reason: "<b>Frictionless Data Verification.</b> CloudShell has a built-in ephemeral storage space, and engineers frequently need to pull down configs, code artifacts, or logs from S3. Checking bucket names and file hierarchies directly from the terminal saves trips to the visual AWS Console."
            },
            {
                category: "Beginner",
                command: "aws ec2 describe-instances",
                service: "EC2",
                action: "List Virtual Machines",
                purpose: "Lists and provides architectural/metadata details about your Amazon Elastic Compute Cloud (EC2) instances.",
                meaning: "<b>aws</b>: Invokes the AWS CLI.<br><b>ec2</b>: Interacts with the Amazon EC2 service.<br><b>describe-instances</b>: Retrieves configuration information (IDs, status, IP addresses, instance types) for instances within the current region.",
                usage: "Used by administrators to check if virtual machines are running, stopped, or pending, and to fetch public or private IP addresses for remote connections.",
                reason: "<b>Resource Monitoring and Inventory.</b> Allows rapid status checks on compute nodes without navigating the multi-step EC2 web console, especially when checking on instances after an automation script or scaling event has run."
            },
            {
                category: "Beginner",
                command: "aws configure list",
                service: "CLI Configuration",
                action: "Verify Environment",
                purpose: "Displays the current active configuration values (Access Keys, Region, Output) along with their source.",
                meaning: "<b>aws</b>: Invokes the AWS CLI.<br><b>configure</b>: Interacts with the AWS CLI's configurations.<br><b>list</b>: Commands the CLI to read out active configurations in a clean tabular format.",
                usage: "Run this when a command fails with regional errors or permission errors to confirm whether CloudShell has mapped you to your desired AWS Region.",
                reason: "<b>Debugging and Environment Clarity.</b> Because CloudShell auto-injects temporary security credentials and sets default regions based on where you launched it, running this command ensures your CLI configurations match your intended operational parameters."
            },
            {
                category: "Beginner",
                command: "aws lambda list-functions",
                service: "Lambda",
                action: "List Functions",
                purpose: "Lists all AWS Lambda functions deployed in your current active region.",
                meaning: "<b>aws lambda</b>: Targets the Lambda serverless Compute environment.<br><b>list-functions</b>: Requests high-level configurations of all serverless functions in the current region context.",
                usage: "Used when verifying deployment status or finding names of active microservices before attempting triggers or parameter checks.",
                reason: "<b>Development Inventory.</b> Provides a quick regional snapshot of all functional code resources, allowing engineers to audit runtime environments, memory configurations, or deployment package formats."
            },
            {
                category: "Beginner",
                command: "aws rds describe-db-instances",
                service: "RDS",
                action: "List Databases",
                purpose: "Lists and details status information for all running Amazon RDS database instances.",
                meaning: "<b>aws rds</b>: Targets the Relational Database Service.<br><b>describe-db-instances</b>: Requests physical state, sizing, network end points, and engine versions of all provisioned database systems.",
                usage: "Crucial for capturing the database endpoints and security groups necessary for application connection setups.",
                reason: "<b>Architectural Verification.</b> Allows developers to confirm that the database is actively in an 'available' state and fetch connection details securely without loading the full RDS Console layout."
            },
            {
                category: "Beginner",
                command: "aws dynamodb list-tables",
                service: "DynamoDB",
                action: "List NoSQL Tables",
                purpose: "Returns an array of all active Amazon DynamoDB table names inside the current region.",
                meaning: "<b>aws dynamodb</b>: Targets the DynamoDB NoSQL service.<br><b>list-tables</b>: Performs a quick scan of existing table namespaces.",
                usage: "Used when starting administrative scripts to identify database storage structures.",
                reason: "<b>Lightweight Auditing.</b> Returns a super-fast, minimal payload, saving read throughput and helping you verify table existences programmatically."
            },
            {
                category: "Beginner",
                command: "aws sqs list-queues",
                service: "SQS",
                action: "List Message Queues",
                purpose: "Lists all Simple Queue Service (SQS) message queues in your active region.",
                meaning: "<b>aws sqs</b>: Targets the decoupled messaging queue service.<br><b>list-queues</b>: Returns URLs of all active message queues.",
                usage: "Used to verify asynchronous microservice message pipes and fetch logical URLs for event triggers.",
                reason: "<b>Decoupled Architecture Diagnostics.</b> Quickly lists endpoints so administrators can copy queue URLs for message publishing or polling."
            },
            {
                category: "Intermediate",
                command: "aws s3 sync <source_path> <destination_path>",
                service: "S3",
                action: "Synchronize Directories",
                purpose: "Recursively synchronizes directories, files, or prefixes between a local directory in CloudShell and an S3 bucket (or between two S3 buckets).",
                meaning: "<b>aws s3</b>: Interacts with S3.<br><b>sync</b>: Performs a delta synchronization.<br><b>&lt;source_path&gt;</b>: The origin file system path.<br><b>&lt;destination_path&gt;</b>: The target path.",
                usage: "Used to upload locally generated CloudShell files to an S3 bucket for permanent archiving, or conversely, pulling a full static website folder down from S3 to modify it locally inside CloudShell.",
                reason: "<b>Efficiency and Cost-Effectiveness.</b> Unlike bulk copying which overrides files unconditionally, sync only copies modified or missing assets. This reduces network overhead, speeds up processing time, and reduces S3 API call charges."
            },
            {
                category: "Intermediate",
                command: "aws ec2 start-instances --instance-ids <id_1> <id_2>",
                service: "EC2",
                action: "State Management",
                purpose: "Powers on one or more stopped Amazon EC2 instances.",
                meaning: "<b>aws ec2</b>: Interacts with EC2.<br><b>start-instances</b>: Triggers the boot sequence.<br><b>--instance-ids</b>: Flag designating the target EC2 Instance IDs.",
                usage: "Commonly executed during morning routine tasks to spin up development boxes, jump-hosts, or staging systems that were turned off overnight to control costs.",
                reason: "<b>Operational Lifecycle Management.</b> It is a fast, programmatic approach to state management. When combined with terminal alias features or scripts in CloudShell, it eliminates the latency of navigating through standard web portals."
            },
            {
                category: "Intermediate",
                command: "aws ssm get-parameter --name \"/path/to/parameter\" --with-decryption",
                service: "Systems Manager",
                action: "Secrets Retrieval",
                purpose: "Retrieves secure string configuration parameters, database connection details, or API keys stored in the AWS Systems Manager (SSM) Parameter Store.",
                meaning: "<b>aws ssm</b>: Invokes Systems Manager.<br><b>get-parameter</b>: Requests specific name.<br><b>--name</b>: Specifies hierarchy.<br><b>--with-decryption</b>: Decrypts configurations on-the-fly using AWS KMS.",
                usage: "Programmatically injecting API tokens, system variables, or private SSH keys into your active CloudShell terminal session so that they can be utilized by deployment scripts without hardcoding secrets.",
                reason: "<b>Zero-Hardcoding Compliance.</b> Storing secrets directly in scripts presents a severe risk of exposure. Using Systems Manager ensures that operational scripts remain clean, parameterized, and compliant with security frameworks."
            },
            {
                category: "Intermediate",
                command: "aws iam list-users",
                service: "IAM",
                action: "User Auditing",
                purpose: "Generates a comprehensive list of all Identity and Access Management (IAM) users configured inside the current AWS Account.",
                meaning: "<b>aws iam</b>: Targets IAM service.<br><b>list-users</b>: Requests a list of users, returns output in JSON, including User ID, ARN, Creation Date, and Path.",
                usage: "Routinely utilized during user audits, permission reviews, or compliance verification tasks to inspect which administrative or developer accounts currently exist.",
                reason: "<b>Security Auditability.</b> Quickly auditing access controls is critical. Running this command inside CloudShell bypasses administrative lag and presents quick, parseable structural data of your human resource catalog."
            },
            {
                category: "Intermediate",
                command: "aws secretsmanager get-secret-value --secret-id <secret-id>",
                service: "Secrets Manager",
                action: "Access Credentials",
                purpose: "Retrieves decrypted secret details (such as database credentials or API keys) securely stored in AWS Secrets Manager.",
                meaning: "<b>aws secretsmanager</b>: Invokes Secrets Manager for high-security, rotating secrets management.<br><b>get-secret-value</b>: Retrieves value details for a given identifier.<br><b>--secret-id</b>: Identifies target secret.",
                usage: "Utilized during custom script executions when calling third-party services requiring real-time, decrypted programmatic access keys.",
                reason: "<b>Enterprise Security Standards.</b> Implements credential rotation automatically. Pulling credentials dynamically ensures that static copies are never stored on persistent storage blocks."
            },
            {
                category: "Intermediate",
                command: "aws lambda invoke --function-name <name> response.json",
                service: "Lambda",
                action: "Execute Serverless Code",
                purpose: "Invokes an active AWS Lambda function synchronously and writes the runtime execution payload response to a local JSON file.",
                meaning: "<b>aws lambda invoke</b>: Triggers code run in isolation.<br><b>--function-name</b>: Designates the targeted function.<br><b>response.json</b>: Local file path where return status is saved.",
                usage: "Commonly used when testing Lambda logic, REST routes, or event triggers from the command-line workspace.",
                reason: "<b>Programmatic Diagnostic and Fast Feedback Loops.</b> Lets developers bypass console trigger interfaces, sending mock JSON inputs directly to function stacks and storing outputs locally for log inspection."
            },
            {
                category: "Intermediate",
                command: "aws logs tail /aws/lambda/<name> --follow",
                service: "CloudWatch",
                action: "Tail Live Log Streams",
                purpose: "Tails CloudWatch log streams for a specific system or function, logging active messages directly into your CloudShell window.",
                meaning: "<b>aws logs tail</b>: Commands CLI to poll log groups.<br><b>--follow</b>: Keeps stream open and pipes incoming logging parameters down continuously (similar to standard tail -f).",
                usage: "Used when executing dynamic integrations, watching execution run outputs, or chasing errors live.",
                reason: "<b>Real-time Stream Diagnostics.</b> Eliminates navigation through complex historical Log Streams, providing a centralized unified viewport for system outputs."
            },
            {
                category: "Intermediate",
                command: "aws dynamodb get-item --table-name <name> --key '{\"id\": {\"S\": \"value\"}}'",
                service: "DynamoDB",
                action: "Retrieve Single NoSQL Record",
                purpose: "Fetches properties and metadata for a single item out of a target DynamoDB table.",
                meaning: "<b>get-item</b>: NoSQL specific fetch action.<br><b>--table-name</b>: The target table context.<br><b>--key</b>: Exact partition (and optional sort) key specified in standard DynamoDB JSON format.",
                usage: "Used by back-end developers to check current attribute configurations, debug entry errors, or verify database writing systems.",
                reason: "<b>Direct Record Access.</b> Fetches exact targets with extremely low system utilization compared to highly expensive, general scan commands."
            },
            {
                category: "Intermediate",
                command: "aws sqs send-message --queue-url <url> --message-body \"Hello\"",
                service: "SQS",
                action: "Publish Message",
                purpose: "Publishes a text payload message directly to a specified Amazon SQS queue.",
                meaning: "<b>aws sqs send-message</b>: Pushes payload down the message stream.<br><b>--queue-url</b>: Destination queue address endpoint.<br><b>--message-body</b>: The exact text string or JSON object payload to store.",
                usage: "Commonly utilized during integrations to trigger backend workers or run performance tests.",
                reason: "<b>Asynchronous Verification.</b> Allows administrators to easily fake system events and test pipeline operations programmatically from the CLI."
            },
            {
                category: "Intermediate",
                command: "aws ecr get-login-password --region <region> | docker login --username AWS --password-stdin <url>",
                service: "ECR",
                action: "Authenticate Docker Container Engine",
                purpose: "Authenticates your local Docker installation with your private Amazon Elastic Container Registry (ECR).",
                meaning: "<b>aws ecr get-login-password</b>: Generates temporary authorization token.<br><b>docker login</b>: Pipes password output down directly to log in securely into the private registry domain.",
                usage: "Critical first step before building, tagging, and pushing custom container images to AWS from CloudShell.",
                reason: "<b>Frictionless Container Pipelines.</b> Combines credential acquisition and container daemon login into a single secure pipeline operation."
            },
            {
                category: "Advanced",
                command: "aws ec2 describe-instances --query \"...\" --output table",
                service: "EC2",
                action: "Custom Filtering",
                purpose: "Queries specific attributes of all EC2 instances and organizes the filtered results into a clean, human-readable terminal table.",
                meaning: "<b>--query</b>: Uses JMESPath query language to filter JSON output.<br><b>Reservations[*].Instances[*]...</b>: Selects and renames fields.<br><b>--output table</b>: Formats as ASCII table instead of JSON.",
                usage: "Essential for generating instantaneous status sheets of compute environments to present to managers or for rapid terminal troubleshooting.",
                reason: "<b>Data Reduction and Readability.</b> Running describe commands natively returns hundreds of lines of complex JSON. Applying server-side projection via --query filters out noise, keeping your CloudShell terminal tidy."
            },
            {
                category: "Advanced",
                command: "aws s3api put-bucket-policy --bucket <name> --policy file://policy.json",
                service: "S3",
                action: "Security Rules",
                purpose: "Programmatically applies a complex JSON policy document directly to an S3 bucket to configure access controls, public blocks, or cross-account operations.",
                meaning: "<b>aws s3api</b>: Low-level API commands.<br><b>put-bucket-policy</b>: Replaces/creates policy.<br><b>--policy file://...</b>: Reads policy from local CloudShell file storage.",
                usage: "Typically used by Cloud Architects to quickly restrict access on a bucket, block non-SSL/HTTPS connections, or permit secure cross-account asset sharing.",
                reason: "<b>Repeatability and Infrastructure Security.</b> Writing JSON policies inline on the command line is error-prone. Storing the policy in a local file within CloudShell and executing this command is the industry standard."
            },
            {
                category: "Advanced",
                command: "aws cloudformation deploy --template-file template.yaml ...",
                service: "CloudFormation",
                action: "Infrastructure as Code",
                purpose: "Deploys, updates, or modifies entire cloud architectures using an Infrastructure as Code (IaC) templates defined in CloudFormation.",
                meaning: "<b>aws cloudformation deploy</b>: Handles creation/execution of change sets natively.<br><b>--template-file</b>: Path to blueprint.<br><b>--parameter-overrides</b>: Feeds runtime parameters.",
                usage: "Used to launch, update, or teardown environments deterministically from the command line.",
                reason: "<b>Automated Provisioning and State Management.</b> Instead of manual configuration, CloudShell acts as your lightweight Deployment Server. Ensures consistency and prevents human-error configuration drift."
            },
            {
                category: "Advanced",
                command: "pip install <package> --user",
                service: "CLI Configuration",
                action: "Package Install",
                purpose: "Extends the capabilities of your CloudShell environment by downloading and installing specialized Python development packages directly onto CloudShell's persistent storage.",
                meaning: "<b>pip install</b>: Downloads packages.<br><b>--user</b>: Installs in the local user directory (~/.local), crucial because CloudShell limits sudo permissions.",
                usage: "Run this when you need specialized libraries (such as ansible, boto3) to execute automation code from within your terminal.",
                reason: "<b>Extensibility.</b> AWS CloudShell persists up to 1 GB of files inside your home directory across sessions, so these installations remain available when you log back in."
            },
            {
                category: "Advanced",
                command: "aws iam simulate-principal-policy --policy-source-arn <arn> --action-names <actions>",
                service: "IAM",
                action: "Simulate Permissions Matrix",
                purpose: "Simulates and tests if a specific IAM principal has rights to run specific AWS commands without actually executing them.",
                meaning: "<b>simulate-principal-policy</b>: Performs programmatic dry-runs of permissions evaluations.<br><b>--policy-source-arn</b>: The user or role context ARN.<br><b>--action-names</b>: Array of target actions to dry-run.",
                usage: "Crucial for troubleshooting IAM 'Access Denied' errors in security pipelines.",
                reason: "<b>Safe Security Auditing.</b> Validates custom-crafted JSON permissions schemas against live roles without risking accidental resource generation or state corruption."
            },
            {
                category: "Advanced",
                command: "aws sts assume-role --role-arn <arn> --role-session-name <name>",
                service: "IAM",
                action: "Assume Multi-Account IAM Roles",
                purpose: "Requests temporary security credentials for a role, allowing temporary cross-account or elevated action executions.",
                meaning: "<b>assume-role</b>: STS operation that returns Access Key, Secret Key, and Session Token.<br><b>--role-arn</b>: High privilege ARN target context.",
                usage: "Used to operate securely inside production workloads from a central development context.",
                reason: "<b>Least Privilege Best Practice.</b> Eliminates the need to hold administrative credentials natively, leveraging temporary, rotating credential parameters for isolated administrative procedures."
            },
            {
                category: "Advanced",
                command: "aws cognito-idp admin-initiate-auth --user-pool-id <id> --client-id <id> --auth-flow ADMIN_NO_SRP_AUTH --auth-parameters USERNAME=<user>,PASSWORD=<pass>",
                service: "Cognito",
                action: "Test Authentication Workflows",
                purpose: "Simulates authentication requests directly inside a Cognito User Pool, bypassing user-interface dependencies.",
                meaning: "<b>cognito-idp</b>: Interacts with the Identity Provider service engine.<br><b>admin-initiate-auth</b>: Overpasses standard SRP password structures directly for administrative troubleshooting tests.",
                usage: "Essential for debugging authentication structures, MFA policies, or custom Lambda trigger chains.",
                reason: "<b>Bypass UI Blockers.</b> Allows engineers to accurately measure authentication latencies and test pool configurations directly inside CloudShell."
            },
            {
                category: "Advanced",
                command: "aws stepfunctions start-execution --state-machine-arn <arn> --input '{\"key\": \"val\"}'",
                service: "Step Functions",
                action: "Trigger Orchestration States",
                purpose: "Launches a new programmatic execution execution run within an AWS Step Functions State Machine engine.",
                meaning: "<b>start-execution</b>: Triggers orchestrated workflows.<br><b>--state-machine-arn</b>: Target ARN machine logic map context.<br><b>--input</b>: Initial JSON parameter payload.",
                usage: "Employed during deployment stages to initiate batch computing, machine learning pathways, or environment validations.",
                reason: "<b>Seamless Automation Triggers.</b> Triggers microservices pipelines directly from the terminal, avoiding visual UI consoles entirely."
            },
            {
                category: "Advanced",
                command: "aws eks update-kubeconfig --region <region> --name <cluster-name>",
                service: "EKS",
                action: "Configure Kubernetes Contexts",
                purpose: "Automatically configures kubectl parameters locally inside CloudShell to connect to a target Amazon EKS Kubernetes Cluster.",
                meaning: "<b>update-kubeconfig</b>: Downloads and merges configuration files into local config maps.<br><b>--name</b>: Targets EKS cluster context.",
                usage: "Executed when managing Kubernetes deployments, checking pod health, or applying helm blueprints from CloudShell.",
                reason: "<b>Frictionless Hybrid Clusters.</b> Turns AWS CloudShell into a robust EKS control node with security parameters automatically authorized via active IAM policies."
            },
            {
                category: "Advanced",
                command: "aws rds create-db-snapshot --db-instance-identifier <id> --db-snapshot-identifier <snapshot-name>",
                service: "RDS",
                action: "Provision Hot Databases Backup Snapshots",
                purpose: "Forces an immediate, secure storage-level snapshot backup of an active database system.",
                meaning: "<b>create-db-snapshot</b>: Initiates live hot-backup operations.<br><b>--db-instance-identifier</b>: Selected target instance database stack.",
                usage: "Executed right before critical schema alterations, code migrations, or emergency maintenance procedures to guarantee a safe recovery fallback.",
                reason: "<b>Zero Data Loss Best Practices.</b> Guarantees rapid, restorable database environments without disturbing structural application integrity."
            },
            {
                category: "Beginner",
                command: "aws s3 mb s3://my-unique-bucket-name",
                service: "S3",
                action: "Create Bucket",
                purpose: "Creates a brand-new, globally unique Amazon S3 storage bucket in your default AWS region.",
                meaning: "<b>aws s3</b>: Interacts with S3.<br><b>mb</b>: Stands for 'make bucket'.<br><b>s3://my-unique-bucket-name</b>: The globally unique bucket name to create.",
                usage: "Used when you need to provision new S3 storage resources for application data, backups, website hosting, or logs.",
                reason: "<b>Storage Foundation.</b> S3 buckets are the fundamental storage unit in AWS. Creating them programmatically ensures consistency and automation in infrastructure setup."
            },
            {
                category: "Intermediate",
                command: "aws s3 cp localfile.txt s3://my-bucket/",
                service: "S3",
                action: "Copy Files",
                purpose: "Copies files or directories between your CloudShell local storage and an S3 bucket (or between two S3 buckets).",
                meaning: "<b>aws s3 cp</b>: Copy command for S3.<br><b>localfile.txt</b>: Source file path.<br><b>s3://my-bucket/</b>: Destination S3 bucket path.",
                usage: "Used to upload local files to S3 for backup, deploy application code, or transfer data between CloudShell and cloud storage.",
                reason: "<b>File Transfer Efficiency.</b> Provides a simple, intuitive interface for moving files to cloud storage without complex APIs, supporting recursive copying with wildcards."
            },
            {
                category: "Intermediate",
                command: "aws ec2 stop-instances --instance-ids i-12345",
                service: "EC2",
                action: "Stop Instance",
                purpose: "Safely shuts down a running Amazon EC2 instance without terminating it permanently.",
                meaning: "<b>aws ec2</b>: Interacts with EC2.<br><b>stop-instances</b>: Signals shutdown sequence.<br><b>--instance-ids</b>: Specifies target instance IDs.",
                usage: "Commonly used to pause development environments, staging servers, or non-production workloads to reduce cloud costs when not in use.",
                reason: "<b>Cost Optimization.</b> Stopping instances halts compute charges while preserving attached storage, snapshots, and configurations for later restart."
            },
            {
                category: "Intermediate",
                command: "aws lambda list-functions --max-items 10",
                service: "Lambda",
                action: "List Functions with Limit",
                purpose: "Lists AWS Lambda functions in your active region with a maximum item limit to control output size.",
                meaning: "<b>aws lambda list-functions</b>: Requests all serverless functions.<br><b>--max-items</b>: Limits the number of results returned.",
                usage: "Useful for accounts with large numbers of Lambda functions to paginate results and avoid overwhelming terminal output.",
                reason: "<b>Output Control.</b> Large AWS accounts can have hundreds of Lambda functions. Limiting results improves readability and reduces API response times."
            },
            {
                category: "Advanced",
                command: "aws ec2 run-instances --image-id ami-0c55b159cbfafe1f0 --count 1 --instance-type t2.micro --key-name MyKeyPair",
                service: "EC2",
                action: "Launch New Instance",
                purpose: "Launches a brand-new Amazon EC2 virtual machine from scratch with specified configuration parameters.",
                meaning: "<b>run-instances</b>: Creates and boots a new EC2 instance.<br><b>--image-id</b>: Specifies the AMI (Amazon Machine Image).<br><b>--instance-type</b>: Defines instance size (t2.micro, t3.small, etc.).<br><b>--key-name</b>: SSH key pair for access.",
                usage: "Employed during infrastructure provisioning, auto-scaling events, or when setting up new servers for applications and services.",
                reason: "<b>Infrastructure Automation.</b> Programmatically launching instances ensures consistency, enables Infrastructure-as-Code practices, and eliminates manual console steps."
            },
            {
                category: "Advanced",
                command: "aws dynamodb put-item --table-name Users --item '{\"UserId\": {\"S\": \"123\"}, \"Name\": {\"S\": \"Alice\"}}'",
                service: "DynamoDB",
                action: "Insert NoSQL Record",
                purpose: "Inserts a new data record (item) directly into an Amazon DynamoDB NoSQL table with strict type definitions.",
                meaning: "<b>put-item</b>: Creates or overwrites an item in DynamoDB.<br><b>--table-name</b>: Target DynamoDB table.<br><b>--item</b>: JSON payload with typed attributes (S=String, N=Number, etc.).",
                usage: "Used by applications and scripts to programmatically store user profiles, configuration data, or transactional records in DynamoDB.",
                reason: "<b>Direct Data Ingestion.</b> Allows serverless applications and automation scripts to write data directly without database drivers or connection pooling overhead."
            },
            {
                category: "Beginner",
                command: "aws ec2 describe-vpcs",
                service: "Networking",
                action: "List Virtual Networks",
                purpose: "Lists all Virtual Private Clouds (VPCs) in your region, showing their network boundaries (CIDR blocks) and state.",
                meaning: "<b>aws ec2</b>: Interacts with EC2 service.<br><b>describe-vpcs</b>: Retrieves VPC information.<br>Returns VPC IDs, CIDR blocks, and current states.",
                usage: "Used by network administrators to view available network environments and their configurations before launching resources.",
                reason: "<b>Network Architecture Visibility.</b> Understanding your VPC layout is essential before deploying instances, databases, or security groups to the correct network boundaries."
            },
            {
                category: "Beginner",
                command: "aws s3 rm s3://my-bucket/file.txt",
                service: "S3",
                action: "Remove File",
                purpose: "Permanently removes a specific file or object from an S3 bucket.",
                meaning: "<b>aws s3 rm</b>: Delete command for S3.<br><b>s3://my-bucket/file.txt</b>: Full path to the object to delete.",
                usage: "Used to clean up old files, remove test data, or permanently delete unwanted objects from S3 buckets.",
                reason: "<b>Storage Management.</b> Helps maintain bucket hygiene, reduce storage costs, and ensure sensitive files are permanently removed."
            },
            {
                category: "Beginner",
                command: "aws sns list-topics",
                service: "SNS",
                action: "List Notification Topics",
                purpose: "Displays all Simple Notification Service (SNS) communication channels (topics) created in your AWS account.",
                meaning: "<b>aws sns</b>: Targets the SNS messaging service.<br><b>list-topics</b>: Returns all topic ARNs and metadata.",
                usage: "Used to verify available messaging channels and find topic ARNs for subscribing applications or publishing messages.",
                reason: "<b>Messaging Architecture Discovery.</b> Quickly identifies all SNS topics available for event notifications and system alerts."
            },
            {
                category: "Beginner",
                command: "aws --version",
                service: "CLI Configuration",
                action: "Check CLI Version",
                purpose: "Displays the installed version of the AWS CLI tool, Python interpreter, and OS environment running inside CloudShell.",
                meaning: "<b>aws --version</b>: Queries the CLI tool for version metadata.<br>Returns version numbers and system information.",
                usage: "Commonly run when troubleshooting compatibility issues or confirming that CloudShell has the latest AWS CLI features.",
                reason: "<b>Compatibility Verification.</b> Ensures your CLI version supports specific commands and features needed for your automation scripts."
            },
            {
                category: "Intermediate",
                command: "aws cloudwatch get-metric-statistics --namespace AWS/EC2 --metric-name CPUUtilization --period 3600 --start-time 2026-06-06T00:00:00Z --end-time 2026-06-07T00:00:00Z --statistics Average",
                service: "CloudWatch",
                action: "Retrieve Performance Metrics",
                purpose: "Retrieves historical performance metrics (like average CPU usage) for your resources over a specified timeframe.",
                meaning: "<b>get-metric-statistics</b>: Fetches metric data.<br><b>--namespace</b>: AWS service (AWS/EC2, AWS/RDS, etc.).<br><b>--period</b>: Time interval in seconds.<br><b>--statistics</b>: Aggregation type (Average, Maximum, Sum, etc.).",
                usage: "Used for capacity planning, performance analysis, and billing forecasting by examining historical resource consumption patterns.",
                reason: "<b>Data-Driven Operations.</b> Provides factual performance data to guide infrastructure decisions and identify optimization opportunities."
            },
            {
                category: "Intermediate",
                command: "aws iam attach-user-policy --user-name Alice --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess",
                service: "IAM",
                action: "Grant User Permissions",
                purpose: "Grants a specific user permission to access resources by binding a managed policy (like S3 Read-Only) to their account.",
                meaning: "<b>attach-user-policy</b>: Links a policy to a user.<br><b>--user-name</b>: Target IAM user.<br><b>--policy-arn</b>: Full ARN of the policy to attach.",
                usage: "Executed when onboarding new team members or updating access controls to follow least-privilege principles.",
                reason: "<b>Access Control Management.</b> Enables secure, auditable permission delegation without managing individual inline policies."
            },
            {
                category: "Intermediate",
                command: "aws s3api get-bucket-location --bucket my-bucket",
                service: "S3",
                action: "Determine Bucket Region",
                purpose: "Uses the lower-level S3 API layer to find out exactly which physical geographical region hosts a specific bucket.",
                meaning: "<b>s3api</b>: Low-level S3 API commands.<br><b>get-bucket-location</b>: Retrieves the region constraint.<br><b>--bucket</b>: Target bucket name.",
                usage: "Used when troubleshooting cross-region replication, identifying data residency requirements, or optimizing latency.",
                reason: "<b>Regional Awareness.</b> Helps engineers understand data location for compliance, performance, and disaster recovery planning."
            },
            {
                category: "Intermediate",
                command: "aws ec2 describe-images --owners self",
                service: "EC2",
                action: "List Custom AMIs",
                purpose: "Filters your Amazon Machine Image (AMI) list to show only custom virtual machine templates that you created or own.",
                meaning: "<b>describe-images</b>: Retrieves AMI information.<br><b>--owners self</b>: Filters to only custom AMIs you own.",
                usage: "Used to audit custom machine images before launching instances or when managing infrastructure-as-code deployments.",
                reason: "<b>Image Inventory Management.</b> Helps track custom templates and their versions without cluttering results with AWS-provided base images."
            },
            {
                category: "Advanced",
                command: "aws ecs update-service --cluster MyCluster --service MyService --force-new-deployment",
                service: "ECS",
                action: "Trigger Container Rollout",
                purpose: "Triggers a rolling update for a containerized application inside Elastic Container Service (ECS), pulling the latest image version immediately.",
                meaning: "<b>update-service</b>: Modifies ECS service configuration.<br><b>--cluster</b>: Target cluster name.<br><b>--service</b>: Target service name.<br><b>--force-new-deployment</b>: Forces immediate redeployment.",
                usage: "Executed during deployments to rolling-restart container tasks and pull fresh Docker images from ECR.",
                reason: "<b>Zero-Downtime Deployments.</b> Enables rapid application updates without manually managing task lifecycles or drain policies."
            },
            {
                category: "Advanced",
                command: "aws ssm start-session --target i-12345",
                service: "Systems Manager",
                action: "Interactive EC2 Access",
                purpose: "Uses AWS Systems Manager Session Manager to open an interactive, secure terminal tunnel into an EC2 instance without needing open SSH ports.",
                meaning: "<b>start-session</b>: Initiates remote terminal access.<br><b>--target</b>: EC2 instance ID or Systems Manager resource name.",
                usage: "Used by security teams to access instances securely without managing SSH keys or exposing instances to public internet.",
                reason: "<b>Secure Administration.</b> Eliminates SSH key management overhead and port exposure, providing audited terminal access through IAM permissions."
            },
            {
                category: "Advanced",
                command: "aws route53 list-resource-record-sets --hosted-zone-id Z12345",
                service: "Route 53",
                action: "Query DNS Records",
                purpose: "Retrieves all DNS routing records (like A, AAAA, or CNAME records) mapped inside a specific Route 53 hosted domain zone.",
                meaning: "<b>route53</b>: AWS Domain Name System service.<br><b>list-resource-record-sets</b>: Retrieves all DNS records.<br><b>--hosted-zone-id</b>: Target hosted zone identifier.",
                usage: "Used for DNS troubleshooting, auditing domain configurations, and automating DNS record management.",
                reason: "<b>DNS Automation and Visibility.</b> Provides programmatic access to domain records for infrastructure automation and compliance auditing."
            }
        ];