# vpc-pering-across-two-aws-accounts

AWS VPC Peering with Terraform
This Terraform script sets up a Virtual Private Cloud (VPC) peering connection between two AWS accounts in the same region. The script creates VPCs, subnets, and sets up the necessary routing tables for communication between the VPCs.

Prerequisites
AWS Credentials:

You need valid AWS credentials for two AWS accounts.
Replace sensitive data such as account IDs, role names, and peer account ID with actual values in the Terraform script.
Terraform:

Make sure Terraform is installed on your machine.
Usage
Update Variables:

Open the main.tf file and update the placeholder values with your actual AWS account information.
Run Terraform:

Execute the following commands:

terraform init
terraform apply
Destroy Resources (Optional):

To clean up created resources, run:

terraform destroy


Terraform Modules
VPC (Account 1):

Creates a VPC, public subnets, and a route table.

VPC (Account 2):

Uses an assumed role in the second AWS account to reference the existing VPC and create public subnets and a route table.
Peering Connection:

Establishes a VPC peering connection between the two VPCs.

Routing:

Configures route tables to enable communication between the peered VPCs.

Important Notes
This script assumes that the AWS CLI is configured with the necessary credentials for both AWS accounts.

Review and customize the script according to your specific networking requirements.
