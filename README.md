# Terraform AWS High Availability Web Platform

A production-style AWS infrastructure project built with **Terraform**, featuring a highly available web architecture across multiple Availability Zones, Application Load Balancing, Auto Scaling, CloudWatch monitoring, SNS alerting, and a complete **GitHub Actions CI/CD pipeline with AWS OIDC authentication and manual Production approval**.

## Project Overview

This project demonstrates how Infrastructure as Code (IaC) can be used to deploy and manage a highly available AWS web platform.

The infrastructure is fully managed through Terraform and includes:

- Custom VPC
- Two public subnets across two Availability Zones
- Internet Gateway and routing
- Application Load Balancer (ALB)
- Target Group and health checks
- Auto Scaling Group (ASG)
- EC2 Launch Template
- Apache web servers
- Security Groups
- CloudWatch monitoring and alarms
- SNS email notifications
- IAM role and instance profile for AWS Systems Manager
- S3 remote Terraform state
- GitHub Actions CI/CD
- AWS OIDC authentication
- Manual Production deployment approval

---

## Architecture

Internet User
      |
      v
Internet Gateway
      |
      v
Application Load Balancer
      |
      +-------------------+
      |                   |
      v                   v
Public Subnet 1      Public Subnet 2
AZ ap-southeast-2a   AZ ap-southeast-2b
      |                   |
      v                   v
    EC2                  EC2
      \                   /
       \                 /
        Auto Scaling Group
               |
               v
       CloudWatch Monitoring
               |
               v
          SNS Alerts

Terraform manages the infrastructure and stores its remote state in Amazon S3.

---

## High Availability

The application is deployed across two Availability Zones in the Sydney AWS Region (`ap-southeast-2`).

The Application Load Balancer distributes HTTP traffic between healthy EC2 instances.

The Auto Scaling Group maintains the required number of healthy instances and can replace unhealthy instances automatically.

Target Group health checks ensure that the ALB only sends traffic to healthy web servers.

---

## Auto Scaling

The Auto Scaling Group uses:

- Minimum capacity: `2`
- Desired capacity: `2`
- Maximum capacity: `3`

A Target Tracking Scaling Policy monitors average ASG CPU utilization with a target of **70%**.

When CPU demand increases, the Auto Scaling Group can launch additional EC2 capacity.

> Capacity values may be temporarily changed during CI/CD and scaling demonstrations.

---

## Monitoring and Alerting

Amazon CloudWatch monitors the infrastructure.

The project includes:

- EC2/ASG CPU monitoring
- CloudWatch CPU alarm
- Target Tracking scaling policy
- SNS notification topic
- Email alert subscription

This allows infrastructure events and high CPU conditions to be detected and reported.

---

# CI/CD Pipeline

GitHub Actions is used to automate Terraform validation, planning, and deployment.

The pipeline is divided into two stages:

## Continuous Integration (CI)

Every push to the `main` branch triggers Terraform checks.

The CI job performs:

1. Checkout repository
2. Install Terraform
3. Authenticate to AWS using OIDC
4. `terraform fmt -check -recursive`
5. `terraform init`
6. `terraform validate`
7. `terraform plan -input=false`

The CI stage validates the Terraform configuration and shows the proposed infrastructure changes before deployment.

## Continuous Deployment (CD)

The deployment job runs only after the Terraform Checks job succeeds.

The CD process is:

CI succeeds
     |
     v
Production Environment
     |
     v
Manual Approval
     |
     v
Terraform Deploy
     |
     v
terraform apply
     |
     v
AWS Infrastructure

The GitHub `Production` environment requires manual approval before Terraform can modify AWS infrastructure.

After approval, GitHub Actions runs:

`terraform apply -auto-approve -input=false`

---

## AWS Authentication with OIDC

GitHub Actions authenticates to AWS using **OpenID Connect (OIDC)**.

No permanent AWS access key or secret access key is stored in GitHub.

Authentication flow:

GitHub Actions
      |
      | OIDC Token
      v
AWS STS
      |
      v
IAM Role
      |
      | Temporary Credentials
      v
Terraform
      |
      v
AWS

The GitHub Actions workflow assumes:

`GitHubActions-Terraform-Role`

AWS validates the GitHub OIDC token against the IAM role trust policy before temporary credentials are issued.

---

## Remote Terraform State

Terraform state is stored remotely in Amazon S3 instead of only on the local development machine.

Backend configuration:

- S3 remote backend
- Server-side encryption
- S3 versioning
- Public access blocked
- Terraform state locking

State location:

`project2/terraform.tfstate`

This allows both the local development environment and GitHub Actions to work with the same Terraform state.

---

## IAM Security

The GitHub Actions IAM role uses separate policies for different responsibilities:

- `GitHubActions-Terraform-State`
- `GitHubActions-Terraform-ReadOnly`
- `GitHubActions-Terraform-Deploy`

OIDC is used instead of long-lived AWS credentials.

IAM policy and trust-policy configuration examples are included in this repository.

---

## CI/CD Troubleshooting

Several real CI/CD issues were identified and resolved while building the pipeline.

### OIDC Authentication Failure

GitHub Actions initially failed to assume the AWS IAM role.

Troubleshooting included validating:

- OIDC provider
- Audience (`sts.amazonaws.com`)
- GitHub OIDC subject
- IAM trust policy
- GitHub `id-token: write` permission
- OIDC signing key
- AWS STS authentication

A direct AWS STS OIDC test was also performed successfully.

### Missing Terraform Variable

GitHub Actions initially returned:

`No value for required variable "alert_email"`

The local `terraform.tfvars` file was intentionally excluded from Git.

The value was securely supplied through a GitHub Secret and mapped to:

`TF_VAR_alert_email`

### Production OIDC Authentication Failure

The CI job could authenticate to AWS, but the Production deployment initially failed.

The reason was that GitHub Environment jobs use an environment-based OIDC subject.

The IAM trust policy was updated to allow the `Production` environment subject.

After the change, the deployment successfully authenticated to AWS.

---

## Infrastructure Resilience Testing

The infrastructure was also tested under failure and scaling scenarios.

### Web Server Failure

Apache was deliberately stopped on an EC2 instance.

Observed behavior:

1. Target Group health check detected the unhealthy server.
2. ALB stopped routing normal traffic to the unhealthy target.
3. Auto Scaling detected the unhealthy instance.
4. A replacement EC2 instance was launched.
5. The new instance passed health checks.
6. Target Group returned to a healthy state.

### CPU Auto Scaling

CPU load was increased above the configured scaling target.

The Auto Scaling Group scaled out and later scaled back in after CPU utilization returned to normal.

CloudWatch and SNS were used to observe the event.

---

## Technologies Used

| Technology | Purpose |
|---|---|
| Terraform | Infrastructure as Code |
| AWS VPC | Network isolation |
| EC2 | Web servers |
| Apache HTTP Server | Web application |
| Application Load Balancer | Traffic distribution |
| Auto Scaling Group | Scaling and self-healing |
| CloudWatch | Monitoring and alarms |
| SNS | Email notifications |
| IAM | AWS access control |
| Systems Manager | EC2 management |
| Amazon S3 | Remote Terraform state |
| GitHub | Source control |
| GitHub Actions | CI/CD automation |
| GitHub OIDC | Passwordless AWS authentication |

---

## Repository Structure

.
├── .github/
│   └── workflows/
│       └── terraform.yml
├── incidents/
├── backend.tf
├── main.tf
├── variables.tf
├── outputs.tf
├── github-actions-deploy-policy.json
├── github-actions-trust-policy.json
├── .gitignore
└── README.md

---

## Key Skills Demonstrated

- Infrastructure as Code
- Terraform
- AWS networking
- High Availability architecture
- Load balancing
- Auto Scaling
- Infrastructure monitoring
- IAM
- AWS OIDC federation
- Remote Terraform state management
- Git/GitHub
- GitHub Actions
- CI/CD
- Infrastructure troubleshooting
- Production approval workflows

---

## Project Outcome

This project demonstrates an end-to-end infrastructure lifecycle:

Design → Terraform → AWS → Monitoring → Failure Testing → Git → CI → Plan → Production Approval → CD → Deployment

The final environment can be managed from Terraform while GitHub Actions provides automated validation and controlled infrastructure deployment.
