

---

# Terraform Load-Balanced WordPress Servers

**Created by: Stephen Oloo**

This repository contains Terraform configurations to deploy a scalable and highly available WordPress environment on AWS. It includes multiple EC2 instances behind an Application Load Balancer (ALB), managed with Auto Scaling, and integrates S3 for static file storage and RDS for managed database services.

## Table of Contents

- [Introduction](#introduction)
- [Components](#components)
  - [EC2 Instances](#ec2-instances)
  - [Application Load Balancer (ALB)](#application-load-balancer-alb)
  - [Auto Scaling](#auto-scaling)
  - [S3 Bucket](#s3-bucket)
  - [RDS](#rds)
- [Prerequisites](#prerequisites)
- [Deployment Steps](#deployment-steps)
- [Configuration](#configuration)
- [Outputs](#outputs)
- [License](#license)

## Introduction

This project sets up a WordPress environment using Terraform and AWS services. It ensures high availability and scalability through the following components:

- **EC2 Instances**: Hosts the WordPress application.
- **Application Load Balancer (ALB)**: Distributes traffic across EC2 instances.
- **Auto Scaling**: Adjusts the number of EC2 instances based on traffic demand.
- **S3 Bucket**: Stores static files such as images and backups.
- **RDS**: Provides a managed database service for WordPress.

## Components

### EC2 Instances

The EC2 instances run the WordPress application. Multiple instances are deployed to ensure availability and load balancing.

### Application Load Balancer (ALB)

The ALB distributes incoming HTTP/HTTPS traffic to the EC2 instances based on configured rules and health checks. This helps in maintaining high availability and reliability of the application.

### Auto Scaling

Auto Scaling ensures that the number of EC2 instances adjusts according to the traffic load. It scales up when traffic increases and scales down during low traffic periods.

### S3 Bucket

The S3 bucket is used to store static content such as images and other files that do not change frequently. It helps in offloading the static content delivery from the EC2 instances. It is the main storage used in this case.

**Resource Configuration**:
```hcl
resource "aws_s3_bucket" "webs3_static_website" {
  bucket = "webs3-${var.domain_name}-website" //the bucket name is fetched automatically
  tags = {
    Name = "webs3-static-website"
  }
}
```
- **`aws_s3_bucket`**: Defines the S3 bucket with a name prefixed by `webs3-` and the domain name. This bucket is used for static website hosting.

### RDS

RDS provides a managed database service for WordPress. It ensures database scalability, availability, and automated backups.

**Resource Configuration**:
```hcl
# Example (not included in the provided code)
resource "aws_db_instance" "wordpress_db" {
  identifier = "wordpress-db"
  engine     = "mysql"
  instance_class = "db.t3.micro"
  allocated_storage = 20
  username   = "admin"
  password   = "password"
  db_name    = "wordpress"
}
```
- **`aws_db_instance`**: Defines an RDS instance for WordPress. Replace the placeholder values with actual configurations.

## Prerequisites

- **Terraform**: Version 1.0 or later.
- **AWS CLI**: Configured with appropriate access permissions.
- **AWS Account**: Ensure you have the necessary permissions to create and manage AWS resources.
- **Git**: For cloning the repository.

## Deployment Steps

1. **Clone the Repository**:
   ```bash
   git clone https://github.com/StephenLegacy/Terraform-Load-Balanced-WordPress-Servers.git
   cd Terraform-Load-Balanced-WordPress-Servers
   ```

2. **Initialize Terraform**:
   ```bash
   terraform init
   ```

3. **Configure Variables**:
   Update `variables.tf` or create a `terraform.tfvars` file to specify your configuration details such as AWS region, instance types, and WordPress settings.

4. **Plan the Deployment**:
   ```bash
   terraform plan
   ```

5. **Apply the Configuration**:
   ```bash
   terraform apply
   ```

6. **Access Your WordPress Site**:
   Once the deployment is complete, you can access the WordPress site via the Load Balancer’s DNS name, which will be displayed in the output.

## Configuration

The configuration files are organized as follows:

- **`main.tf`**: Main Terraform configuration for setting up resources.
- **`variables.tf`**: Variable definitions for the deployment.
- **`outputs.tf`**: Output values to retrieve information about the deployment.
- **`terraform.tfvars`**: Optional file for providing variable values.

## Outputs

After applying the Terraform configuration, the following outputs will be available:

- **Load Balancer DNS**: The DNS name of the Application Load Balancer.
- **EC2 Instance IDs**: The IDs of the created EC2 instances.
- **S3 Bucket URL**: The URL of the created S3 bucket.
- **RDS Endpoint**: The endpoint URL of the RDS instance.

**Example Output Configuration**:
```hcl
output "website_url" {
  value = "http://${aws_s3_bucket.webs3_static_website.bucket}.s3-website-${var.region}.amazonaws.com"
}

output "certificate_arn" {
  value = aws_acm_certificate.webs3_main.arn
}
```
- **`website_url`**: Provides the URL where the static website is hosted.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

---

**End of README**

STEPHEN OLOO
