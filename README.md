# vpc-deploy-terraform
Create and manage a Virtual Private Cloud (VPC) on AWS using Terraform.
VPC with one public subnet, a route table, and an Internet Gateway (IGW) that allows outbound connectivity.

## Steps:
- Set Up the Terraform Environment
- Configure AWS as the cloud provider in your desired region
- Define the VPC Configuration
- Add a public subnet resource
- Add an Internet Gateway (IGW)
- Define a route table that directs outbound traffic to the IGW
- Associate the Public Subnet with the Route Table
- Initialize Terraform, preview changes and apply the Configuration
  - terraform init
  - terraform plan
  - terraform apply
- Verify the Deployment in your AWS Management Console
- Clean Up Resources
  - terraform destroy

## Enhancements:
Update Terraform configuration to:
- Add a Security Group that allows SSH (port 22)
- Create an EC2 instance that uses this Security Group
- Create one or more private subnets for internal resources and configure a NAT Gateway for outbound Internet access
- Create a route table to send internet-bound traffic from the private subnet to the NAT Gateway
- Deploy subnets in multiple availability zones to improve redundancy and fault tolerance
- Configure internet gateway and Nat-gateway for the added subnets
- Add an EC2 instance to serve as a bastion host for securely accessing instances in private subnets
- Optional: Define output variables to display key information (e.g., VPC ID, subnet IDs) after deployment

## Store Terraform State in Remote S3 with DynamoDB
Using S3 for state storage provides a centralized, durable location for your Terraform state. DynamoDB is used to lock the state file, ensuring that multiple users or processes do not update it simultaneously.
### Steps:
- Create S3 Bucket and DynamoDB Table
- Configure the Backend in providers.tf (Terraform will connect to your S3 bucket and DynamoDB table as defined in your backend configuration).
- Check in AWS that the state file is written to S3 and properly locked with DynamoDB






