# vpc-deploy-terraform
Create and manage a Virtual Private Cloud (VPC) on AWS using Terraform.
VPC with one public subnet, a route table, and an Internet Gateway (IGW) that allows outbound connectivity.

## Steps:
- Set Up the Terraform Environment
- Configures AWS as the cloud provider in your desired region
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




