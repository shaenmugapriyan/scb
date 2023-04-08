# Terraform AWS EC2 Instance with S3 Sync

This Terraform configuration creates an AWS EC2 instance with the following features:

- Custom VPC with public and private subnets
- Ubuntu 20.04 LTS base image
- SSH key pair for access
- IAM role with S3 full access policy
- Security group allowing SSH access
- Periodically syncs user home directories to an S3 bucket
- Creates and deletes users with unique SSH keys

## Prerequisites

- Terraform 1.0.0 or newer
- AWS account and credentials

## Usage

1. Clone this repository:

    `git clone https://github.com/your-repo-url/terraform-aws-ec2-s3-sync.git

    cd terraform-aws-ec2-s3-sync``


2. Initialize Terraform:

    `terraform init`

3. Create a `terraform.tfvars` file with the following content:

`create_usernames = ["user1", "user2"]
delete_usernames = ["user3", "user4"]
`
Note: there is a variables.tf file already.

4. Check the output for the private SSH keys of the created users:



    terraform output user_private_keys


## Components

- **VPC**: Custom VPC with public and private subnets across two availability zones.
- **EC2 Instance**: Ubuntu 20.04 LTS instance with SSH key pair, IAM role for S3 access, and security group allowing SSH.
- **S3 Bucket**: Bucket for syncing user home directories.
- **IAM Role**: Role with full access to Amazon S3, attached to the EC2 instance.
- **User Management**: Creates and deletes specified users and their unique SSH keys.
- **S3 Sync**: Periodically syncs user home directories to the S3 bucket.

## Notes

This configuration is for demonstration purposes only and is not recommended for production use. Please review and adjust the security settings to meet your specific requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_tls"></a> [tls](#provider\_tls) | n/a |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_vpc"></a> [vpc](#module\_vpc) | terraform-aws-modules/vpc/aws | ~> 3.0 |

## Resources

| Name | Type |
|------|------|
| [aws_iam_instance_profile.s3_access_profile](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.s3_access_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.s3_access_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.example](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_key_pair.generated_key](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/key_pair) | resource |
| [aws_s3_bucket.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.user_home_directories](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_security_group.allow_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [null_resource.create_user](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.delete_user](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.sync_home_directories](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [tls_private_key.example](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [tls_private_key.user_key](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/resources/private_key) | resource |
| [aws_ami.ubuntu_20](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_usernames"></a> [create\_usernames](#input\_create\_usernames) | A list of usernames to create on the instance | `list(string)` | <pre>[<br>  "sp",<br>  "sp1",<br>  "sp2",<br>  "sp3",<br>  "sp4"<br>]</pre> | no |
| <a name="input_delete_usernames"></a> [delete\_usernames](#input\_delete\_usernames) | A list of usernames to delete from the instance | `list(string)` | <pre>[<br>  "sp2"<br>]</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_private_key"></a> [private\_key](#output\_private\_key) | n/a |
| <a name="output_user_private_keys"></a> [user\_private\_keys](#output\_user\_private\_keys) | n/a |
