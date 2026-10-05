# Terraform AWS High Availability Platform

A highly available and scalable web infrastructure built on AWS using Terraform, with automated deployment through a GitHub Actions CI/CD pipeline.

This project demonstrates Infrastructure as Code (IaC), AWS networking, load balancing, Auto Scaling, monitoring, alerting, secure OIDC authentication, CI/CD automation, and infrastructure troubleshooting.

---

## 1. Project Overview

This project provisions a highly available web platform on AWS using Terraform.

The infrastructure is deployed across two Availability Zones and uses an Application Load Balancer (ALB) to distribute HTTP traffic between Apache web servers running on EC2 instances.

The EC2 instances are managed by an Auto Scaling Group (ASG) to maintain availability and automatically adjust capacity based on CPU utilization. Amazon CloudWatch provides monitoring, while Amazon SNS sends email notifications for configured alarms.

The entire infrastructure is managed as code using Terraform. Changes are stored in GitHub and deployed through a GitHub Actions CI/CD pipeline, using OIDC and AWS IAM for secure authentication without storing long-term AWS access keys.

---

## 2. Architecture

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/d997732503dc3a476a371ae54048e58e9cbea693/screenshots/Architecture.png)

The architecture is designed across two Availability Zones to improve availability and fault tolerance.

---

## 3. Architecture Flow

### Application Request Flow

When a user accesses the application, the HTTP request follows this path:

```text
User
  ↓
Internet
  ↓
Internet Gateway
  ↓
Application Load Balancer (HTTP :80)
  ↓
Target Group
  ↓
Healthy EC2 Instance
  ↓
Apache Web Server
```

The **Application Load Balancer** receives HTTP traffic on port 80 and forwards the request through the **Target Group** to a healthy EC2 instance.

Apache running on the EC2 instance processes the request and serves the web page.

### Application Response Flow

The response travels back to the user:

```text
EC2 / Apache
     ↓
Application Load Balancer
     ↓
Internet Gateway
     ↓
Internet
     ↓
User
```

### Infrastructure Deployment Flow

Infrastructure changes follow this process:

```text
Terraform Code
      ↓
GitHub Repository
      ↓
GitHub Actions
      ↓
CI Checks
      ↓
OIDC Authentication
      ↓
AWS IAM Role
      ↓
Temporary AWS Credentials
      ↓
terraform plan
      ↓
terraform apply
      ↓
AWS Infrastructure
```

Terraform defines the desired AWS infrastructure.

After changes are pushed to GitHub, **GitHub Actions** runs the CI/CD workflow. GitHub Actions uses **OIDC** to authenticate with AWS and assume an IAM role.

Terraform then runs plan and apply to create or update the AWS infrastructure.

---

## 4. Technologies Used

| Technology | Purpose |
|---|---|
| AWS | Cloud platform |
| Terraform | Infrastructure as Code |
| Amazon VPC | Network environment |
| Public Subnets | Multi-AZ infrastructure |
| Internet Gateway | Internet connectivity |
| Route Table | Network routing |
| Application Load Balancer | Traffic distribution |
| Target Group | Routes traffic to healthy EC2 instances |
| Amazon EC2 | Apache web servers |
| Launch Template | Defines EC2 configuration |
| Auto Scaling Group | Scaling and instance management |
| Amazon CloudWatch | Monitoring and alarms |
| Amazon SNS | Email notifications |
| AWS IAM | Access control |
| OIDC | Secure GitHub-to-AWS authentication |
| AWS Systems Manager | EC2 management |
| Git | Version control |
| GitHub | Source code repository |
| GitHub Actions | CI/CD automation |
| Apache | Web server |

---

## 5. AWS Infrastructure

The AWS infrastructure was designed to provide a highly available and scalable environment for hosting the web application. The environment includes a custom VPC, two public subnets across separate Availability Zones, internet connectivity, an Application Load Balancer, a Target Group, EC2 web servers, and an Auto Scaling Launch Template.

### *VPC:

A custom Amazon Virtual Private Cloud (VPC) was created to provide an isolated network environment for the project.

```text
VPC CIDR: 10.0.0.0/16
```

The `10.0.0.0/16` CIDR block defines the private IP address range available within the VPC. Smaller subnet networks were created from this address space to organize the infrastructure across multiple Availability Zones.

The VPC acts as the main network boundary that contains the project's networking and compute resources, including:

- Public Subnets
- Route Table
- Internet Gateway
- Application Load Balancer
- EC2 instances
- Security Groups

The VPC was created and managed through Terraform rather than being manually configured in the AWS Console.

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/62d2ef7576052d83055917a8d0610d3b93f8d135/screenshots/vpc-resource-map.png)

The VPC resource map shows the custom VPC and the relationship between the two public subnets, public route table, and Internet Gateway.

---

### Public Subnets:

Two public subnets were created inside the VPC and distributed across two different Availability Zones.

```text
Public Subnet 1
CIDR: 10.0.1.0/24
Availability Zone: ap-southeast-2a

Public Subnet 2
CIDR: 10.0.2.0/24
Availability Zone: ap-southeast-2b
```

Both subnet CIDR ranges are smaller networks taken from the main `10.0.0.0/16` VPC address space.

The two subnets were intentionally placed in separate Availability Zones to support high availability. This allows the infrastructure to run EC2 instances across different AWS data-center locations instead of depending on a single Availability Zone.

The Application Load Balancer also spans both public subnets, allowing it to receive traffic across the multi-AZ environment.

The Auto Scaling Group uses both subnets when launching EC2 instances, allowing instances to be distributed across the two Availability Zones.

This design helps reduce the impact of an Availability Zone failure because application capacity can remain available in another AZ.

---

### Internet Gateway:

An Internet Gateway was created and attached to the custom VPC.

The Internet Gateway provides a connection point between the VPC and the public internet.

```text
Internet
    ↓
Internet Gateway
    ↓
VPC
```

Attaching an Internet Gateway alone does not automatically make a subnet public. A route to the Internet Gateway must also exist in the route table associated with the subnet.

For this project, the public route table contains a default route that directs internet-bound traffic to the Internet Gateway.

---

### Public Route Table:

A dedicated public route table was created to control how network traffic from the public subnets is routed.

The route table contains the following routes:

```text
Destination        Target

10.0.0.0/16   →    local
0.0.0.0/0     →    Internet Gateway
```

The `10.0.0.0/16 → local` route is automatically used for communication between resources inside the VPC.

The `0.0.0.0/0 → Internet Gateway` route means that traffic destined for addresses outside the VPC can be routed through the Internet Gateway.

Both public subnets were explicitly associated with this public route table:

```text
Public Subnet 1 ──┐
                  ├── Public Route Table ── Internet Gateway
Public Subnet 2 ──┘
```

This combination of the Internet Gateway, public route table, and subnet associations provides the networking path required for the public-facing components of the architecture.

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/cd79ac4ae1f8bb4dc003ec3bc83ba7693a0da7d3/screenshots/public-route-table.png)

The public route table contains the local VPC route and the default `0.0.0.0/0` route through the Internet Gateway.

#### Subnet Associations:

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/055735d32363a9de5c2e13865850e9292b9fd66b/screenshots/VPC-subnet-associations.png)

Both public subnets are explicitly associated with the same public route table, ensuring that they use the configured route to the Internet Gateway.

---

### Application Load Balancer:

An internet-facing Application Load Balancer (ALB) was deployed across both public subnets.

The ALB acts as the public entry point for the web application.

It listens for incoming HTTP requests using:

```text
Protocol: HTTP
Port: 80
```

The basic request flow is:

```text
User
 ↓
Internet
 ↓
Application Load Balancer
 ↓
Target Group
 ↓
Healthy EC2 Instance
```

When a user accesses the ALB DNS name, the request reaches the Application Load Balancer. The ALB listener on port `80` evaluates the request and forwards it to the configured Target Group.

The ALB does not simply send traffic to any EC2 instance. It forwards application traffic to instances that are registered with the Target Group and considered healthy.

Because the ALB spans both Availability Zones, it can distribute incoming requests across healthy application instances running in the multi-AZ environment.

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/fc4d88b7016c1508cf6a400a3abd50f619e1eda9/screenshots/alb-configuration.png)

The Application Load Balancer is internet-facing, spans both Availability Zones, and uses an HTTP listener on port 80 to forward requests to the web Target Group.

---

### Target Group:

A Target Group was created to connect the Application Load Balancer with the EC2 web servers.

The Target Group uses:

```text
Protocol: HTTP
Port: 80
Target Type: Instance
```

The EC2 instances launched by the Auto Scaling Group are registered with this Target Group.

A health check was configured using:

```text
Protocol: HTTP
Path: /
```

The `/` path represents the root page of the Apache web application.

The Target Group periodically sends HTTP health-check requests to the registered EC2 instances. If an instance successfully responds to the health check, it is marked as healthy.

The Application Load Balancer sends normal application traffic only to healthy registered targets.

This provides an important availability mechanism because an unhealthy application instance can be removed from normal load-balanced traffic until it becomes healthy again or is replaced.

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/cf453f924b1b68177cea29b0197f4ef9c6558636/screenshots/target-group-healthy.png)

Both EC2 web servers are registered with the Target Group and reported as healthy, confirming that they are available to receive traffic from the Application Load Balancer.

---

### EC2 Web Servers:

Amazon EC2 instances are used as the compute layer for the web application.

The instances run:

```text
Operating System: Amazon Linux 2023
Instance Type: t3.micro
Web Server: Apache HTTP Server
```

Instead of manually configuring Apache after every instance is launched, EC2 User Data is included in the Launch Template.

The User Data automatically:

- Installs Apache
- Starts the Apache service
- Enables Apache to start automatically
- Creates the application's `index.html` page
- Displays the EC2 instance ID on the web page

Displaying the instance ID makes it possible to observe which backend EC2 instance served a request when testing the Application Load Balancer.

The application request flow is therefore:

```text
User Request
     ↓
Application Load Balancer
     ↓
Target Group
     ↓
EC2 Instance
     ↓
Apache
     ↓
index.html
```

The response is then returned through the load balancer to the user.

The EC2 instances are distributed across separate Availability Zones and managed by the Auto Scaling Group rather than being manually created as standalone servers.

The instances also use an IAM Instance Profile with AWS Systems Manager permissions, allowing administrative access through Systems Manager without relying on direct SSH access for management tasks.

---

### Launch Template:

An EC2 Launch Template was created to define the standard configuration that the Auto Scaling Group uses whenever a new EC2 instance needs to be launched.

The Launch Template includes:

- Amazon Linux 2023 AMI
- `t3.micro` instance type
- EC2 Security Group
- Apache installation through User Data
- IAM Instance Profile
- AWS Systems Manager access
- IMDSv2 required

The Launch Template ensures that newly launched instances use a consistent configuration.

Instead of manually creating and configuring every replacement or scaling instance, the Auto Scaling Group can use the Launch Template automatically.

The relationship is:

```text
Launch Template
      ↓
Defines EC2 Configuration
      ↓
Auto Scaling Group
      ↓
Launches EC2 Instances
      ↓
Instances Register with Target Group
      ↓
ALB Sends Traffic to Healthy Instances
```

This becomes particularly important during scaling and self-healing events.

For example, if the Auto Scaling Group determines that another EC2 instance is required, it uses the Launch Template to launch a new instance with the same operating system, instance type, Security Group, IAM permissions, and Apache configuration.

This provides consistent and repeatable EC2 provisioning without requiring manual server configuration.

---

### Infrastructure Traffic Flow:

Combining these AWS components creates the following application traffic path:

```text
User
 ↓
Internet
 ↓
Application Load Balancer
 ↓
Target Group
 ↓
Healthy EC2 Instance
 ↓
Apache Web Server
 ↓
Application Response
 ↓
Application Load Balancer
 ↓
User
```

The VPC provides the network boundary, the two public subnets provide multi-AZ network placement, the Internet Gateway and route table provide internet routing, the Application Load Balancer handles incoming application requests, the Target Group performs health-based routing, and the EC2 instances run the Apache web application.

The Launch Template and Auto Scaling Group then provide automated and consistent management of the EC2 compute layer.

## 6. High Availability & Auto Scaling

The EC2 instances are managed by an **Auto Scaling Group**.

The configured capacity is:

```text
Minimum Capacity: 2
Desired Capacity: 2
Maximum Capacity: 3
```

The Auto Scaling Group distributes EC2 instances across both Availability Zones.

If an instance becomes unhealthy, the Auto Scaling Group can replace it to maintain the desired capacity.

At the same time, the Application Load Balancer sends application traffic only to healthy targets.

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/858e55fd92ccbe1f621f29f444214773c5c20e4a/screenshots/asg-multi-az-instances.png)

The Auto Scaling Group maintains healthy EC2 instances across two Availability Zones, improving application availability and reducing dependency on a single Availability Zone.

### CPU-Based Auto Scaling

A Target Tracking Scaling Policy is configured using average CPU utilization.

```text
Target CPU Utilization: 70%
```

When CPU demand increases, the Auto Scaling Group can launch additional EC2 capacity up to the configured maximum.

When CPU utilization decreases, the Auto Scaling Group can scale in while maintaining the minimum required capacity.

---

## 7. Monitoring & Alerting

Amazon CloudWatch is used to monitor CPU utilization.

The monitoring flow is:

```text
EC2 CPU Metrics
      ↓
CloudWatch
   ↙       ↘
Target     CloudWatch
Tracking     Alarm
   ↓           ↓
Auto          SNS
Scaling        ↓
Group        Email
```

CloudWatch metrics are used by the Target Tracking Scaling Policy to control Auto Scaling.

A separate CloudWatch Alarm monitors the configured CPU threshold.

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/f1acf6bf3a8441fa6f085172eb59f715a036c824/screenshots/cloudwatch-cpu-alarm.png)

Amazon CloudWatch monitors CPU utilization and evaluates the configured high-CPU alarm condition. The alarm is configured to trigger when CPU utilization exceeds 70% for 2 datapoints within 10 minutes.

When the alarm is triggered:

```text
CloudWatch Alarm
       ↓
      SNS
       ↓
Email Notification
```

This provides notification when the configured alarm condition occurs.

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/388b04e84fca28f212a7fab46ca431b914e2e710/screenshots/sns-email-subscription.png)

The Amazon SNS email subscription is confirmed and connected to the CPU alert topic. When the configured CloudWatch alarm is triggered, SNS can send an email notification to the subscribed endpoint.

---

## 8. Infrastructure as Code — Terraform

The complete AWS infrastructure is defined using **Terraform** instead of manually creating resources through the AWS Console.

Terraform manages resources including:

- VPC
- Public Subnets
- Internet Gateway
- Route Table
- Security Groups
- Application Load Balancer
- ALB Listener
- Target Group
- Launch Template
- Auto Scaling Group
- Auto Scaling Policy
- CloudWatch Alarm
- SNS Topic
- SNS Subscription
- IAM Role
- IAM Instance Profile

The standard Terraform workflow is:

```bash
terraform fmt
terraform validate
terraform plan
terraform apply
```

### Terraform Commands

**`terraform fmt`**

Formats the Terraform configuration consistently.

**`terraform validate`**

Checks whether the Terraform configuration is structurally valid.

**`terraform plan`**

Shows the infrastructure changes Terraform intends to make before applying them.

**`terraform apply`**

Creates, updates, or removes AWS resources so the actual AWS infrastructure matches the Terraform configuration.

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/336c6323500785d4e8d389b47ee737257e6189de/screenshots/terraform-apply-success.png)

Terraform successfully provisioned the AWS infrastructure, with the initial deployment completing with 22 resources added and no resources changed or destroyed. This confirms that the infrastructure was created through Infrastructure as Code rather than manual AWS Console configuration.

---

## Remote Terraform State with Amazon S3

Terraform state is stored remotely in an Amazon S3 bucket instead of relying only on a local `terraform.tfstate` file.

The S3 backend is configured in `backend.tf`:

```hcl
terraform {
  backend "s3" {
    bucket       = "farabi-project2-terraform-state-641332413499"
    key          = "project2/terraform.tfstate"
    region       = "ap-southeast-2"
    encrypt      = true
    use_lockfile = true
  }
}
```

---

## 9. CI/CD Pipeline

The project uses **GitHub Actions** to automate Terraform validation and infrastructure deployment.

### CI/CD Flow

```text
Terraform Code in VS Code
          ↓
git add
          ↓
git commit
          ↓
git push
          ↓
GitHub Repository
          ↓
GitHub Actions
          ↓
Terraform Checks
          ↓
OIDC Authentication
          ↓
AWS IAM Role
          ↓
terraform init
          ↓
terraform plan
          ↓
terraform apply
          ↓
AWS Infrastructure
```

### Continuous Integration (CI)

The CI stage checks the Terraform configuration before deployment.

The pipeline performs checks including:

```text
terraform fmt
terraform validate
```

This helps identify formatting or Terraform configuration problems before deployment.

### Continuous Deployment (CD)

The deployment stage authenticates GitHub Actions with AWS and then performs the Terraform deployment.

```text
OIDC Authentication
        ↓
AWS IAM Role
        ↓
terraform init
        ↓
terraform plan
        ↓
terraform apply
        ↓
AWS Infrastructure
```

![image alt](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/f928e52019f7ea53fac9fa3ed37f7f88ea78408f/screenshots/github-actions-terraform-deploy.png)

The GitHub Actions CI/CD pipeline successfully completed both the Terraform validation checks and the deployment workflow. After deployment approval, the pipeline authenticated securely to AWS using OIDC and an IAM role, initialized Terraform using the configured remote backend, and executed terraform apply to deploy the infrastructure changes to AWS.

### OIDC Authentication

GitHub Actions uses **OpenID Connect (OIDC)** to authenticate with AWS.

Instead of storing permanent AWS access keys in GitHub:

```text
GitHub Actions
      ↓
Requests OIDC Token
      ↓
AWS verifies the token
      ↓
GitHub Actions assumes IAM Role
      ↓
Temporary AWS Credentials
      ↓
Terraform accesses AWS
```

This provides secure authentication between GitHub Actions and AWS without storing long-term AWS credentials in the repository.

---

## 10. Security

Several security controls are implemented in this project.

### ALB Security Group

The ALB accepts HTTP traffic from the internet:

```text
Inbound:
HTTP
Port 80
Source: 0.0.0.0/0
```

### EC2 Security Group

The EC2 instances do not accept normal HTTP traffic directly from the internet.

HTTP traffic is allowed from the **ALB Security Group**:

```text
Inbound:
HTTP
Port 80
Source: ALB Security Group
```

This ensures application traffic passes through the Application Load Balancer.

### AWS Systems Manager

EC2 instances use an IAM role with:

```text
AmazonSSMManagedInstanceCore
```

This allows the instances to be managed through AWS Systems Manager.

### IMDSv2

The Launch Template requires **Instance Metadata Service Version 2 (IMDSv2)**.

### GitHub Actions Security

GitHub Actions uses:

```text
OIDC
  ↓
AWS IAM Role
  ↓
Temporary Credentials
```

Long-term AWS access keys are not stored in the GitHub repository.

---

## 11. Testing & Incident Scenarios

The infrastructure was tested using controlled failure and scaling scenarios.

These tests were performed to understand how the infrastructure behaves when application or infrastructure problems occur.

### INC-001 — Apache Service Failure / Self-Healing

Apache was deliberately stopped on one EC2 instance.

The expected flow was:

```text
Apache Stops
     ↓
Target Group Health Check Fails
     ↓
Target Becomes Unhealthy
     ↓
ALB Stops Routing Traffic to Unhealthy Target
     ↓
Auto Scaling Environment Recovers Capacity
     ↓
Healthy Capacity Restored
```

This test demonstrated load balancer health checks and infrastructure recovery.

[View Full Incident Report](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/9b2b82495ae2304fcff132b111b644df17cbd9b9/INC-001/INC-001_Report.pdf)

### INC-002 — CPU-Based Auto Scaling

CPU utilization was deliberately increased on the EC2 instances.

```text
CPU Utilization Increases
        ↓
CloudWatch Detects High CPU
        ↓
Target Tracking Policy Responds
        ↓
Auto Scaling Group Scales Out
        ↓
Additional EC2 Capacity
```

After CPU utilization returned to normal, the Auto Scaling Group later scaled in.

This demonstrated dynamic scaling based on application demand.

[View Full Incident Report](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/51169bb95ccfdef170bccdca06e0c1ed7c1f8e04/INC-002/INC-002_Report.pdf)

### Incident 03 — GitHub Actions AWS OIDC Authentication Failure

**Issue:**  
GitHub Actions failed to assume the AWS IAM role using OIDC.

```text
Could not assume role with OIDC:
The web identity token provided could not be validated.
```

**Troubleshooting:**
- Verified the AWS IAM OIDC provider and role trust policy
- Checked the OIDC token issuer, audience and subject claims
- Verified the GitHub signing key and AWS OIDC thumbprint
- Tested `AssumeRoleWithWebIdentity` directly with AWS STS
- Confirmed the GitHub token could successfully assume the IAM role

**Resolution:**  
GitHub Actions successfully authenticated to AWS using OIDC, allowing the Terraform pipeline to access AWS without storing long-lived AWS access keys.

[View Full Incident Report](https://github.com/abdullahalfarabi150-a11y/Terraform-aws-high-availability-platform/blob/cecfbb08198b0dc0103bcd45c61f6c73b796a962/INC-003/GitHub_Actions_AWS_OIDC_Incident_Report.pdf)

---

## 14. Key Learnings

Through this project, I gained hands-on experience with:

- Designing AWS networking using VPCs and subnets
- Deploying infrastructure across multiple Availability Zones
- Configuring Internet Gateway and routing
- Understanding Application Load Balancers and listeners
- Configuring Target Groups and health checks
- Deploying Apache web servers on EC2
- Creating reusable EC2 configurations with Launch Templates
- Managing EC2 capacity using Auto Scaling Groups
- Implementing CPU-based Target Tracking Scaling
- Monitoring AWS resources with CloudWatch
- Configuring CloudWatch alarms
- Sending notifications using SNS
- Building AWS infrastructure using Terraform
- Understanding Terraform resource dependencies
- Working with Terraform state
- Using Git and GitHub for version control
- Building CI/CD pipelines using GitHub Actions
- Authenticating GitHub Actions with AWS using OIDC
- Working with AWS IAM roles and temporary credentials
- Testing infrastructure failures and recovery
- Troubleshooting Auto Scaling and load balancing behaviour

---

## Project Summary

- Built a highly available AWS web infrastructure using Terraform Infrastructure as Code (IaC).
- Designed a custom VPC with two public subnets across two Availability Zones for high availability.
- Implemented an Application Load Balancer (ALB) to distribute HTTP traffic across healthy EC2 instances.
- Configured Target Group health checks to ensure traffic is routed only to healthy application instances.
- Used a Launch Template and Auto Scaling Group to maintain EC2 capacity and automatically replace unhealthy instances.
- Implemented CPU-based Target Tracking Auto Scaling with a 70% utilization target for automatic scale-out and scale-in.
- Configured Amazon CloudWatch for infrastructure monitoring and CPU utilization tracking.
- Integrated CloudWatch Alarms with Amazon SNS to provide email notifications for infrastructure events.
- Used an Amazon S3 backend to remotely store and manage Terraform state for consistent infrastructure deployments.
- Built a CI/CD pipeline with GitHub Actions to automatically validate, plan, and deploy Terraform infrastructure changes.
- Implemented GitHub OIDC authentication with AWS IAM to provide secure temporary AWS credentials without storing long-term access keys.
- Applied security controls including ALB-to-EC2 security group restrictions, IMDSv2, IAM roles, and AWS Systems Manager access.
- Performed controlled failure and recovery testing to validate ALB health checks, Auto Scaling self-healing, and infrastructure resilience.
- Performed CPU load testing to verify automatic scale-out and scale-in behaviour under changing workloads.
- Used Git and GitHub for version control, infrastructure change tracking, CI/CD automation, and project documentation.

---

## Future Improvements

- Move EC2 instances to private subnets to improve application security and reduce direct internet exposure.
- Add a NAT Gateway to provide controlled outbound internet access for EC2 instances in private subnets.
- Configure HTTPS using AWS Certificate Manager (ACM) and an ALB HTTPS listener on port 443.
- Integrate Amazon Route 53 for custom domain and DNS management.
- Add AWS WAF to protect the web application from common web attacks and malicious traffic.
- Improve monitoring by creating CloudWatch dashboards, additional alarms, and centralized application logs.
- Add automated security scanning to the GitHub Actions CI/CD pipeline using tools such as Checkov or Trivy.
- Create separate development, staging, and production environments using reusable Terraform modules.
- Implement stronger production deployment controls, such as GitHub Environment protection and manual approval before production changes.
- Integrate Amazon Bedrock to introduce Generative AI capabilities, such as an AI-powered assistant, application support features, or intelligent infrastructure-related interactions.
