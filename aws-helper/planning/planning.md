# Ansible Playbook Design: AWS KVM Host Deployment

This document outlines the design for an Ansible playbook that automates the deployment of a KVM virtualization host on AWS. The playbook will replicate and enhance the functionality of the original bash script.

## 1. Playbook Structure

The playbook will be organized as follows:

-   `aws-helper/aws-helper.yaml`: The main playbook file containing all the tasks.
-   `aws-helper/vars/main.yml`: A file to store all configurable variables.
-   `aws-helper/README.md`: Instructions on how to use the playbook.

## 2. Variables

All user-configurable parameters from the bash script will be moved to `aws-helper/vars/main.yml`. This includes:

-   `aws_region`
-   `instance_type`
-   `ami_id`
-   `key_name`
-   `instance_name`
-   `vpc_cidr`
-   `subnet_cidr`
-   `host_ip`
-   `kvm_ip_range` (a dictionary containing prefix, start, and end)
-   `disk_config` (a dictionary for total size and number of disks)

## 3. Tasks

The playbook in `aws-helper.yaml` will be divided into the following tasks, mirroring the steps in the original script:

1.  **VPC and Network Setup**:
    *   Create a VPC using `amazon.aws.ec2_vpc_net`.
    *   Create a subnet using `amazon.aws.ec2_vpc_subnet`.
    *   Create an Internet Gateway using `amazon.aws.ec2_vpc_igw`.
    *   Create a route table and associate it with the subnet using `amazon.aws.ec2_vpc_route_table`.
    *   Enable public IP mapping on the subnet.

2.  **Security Group Setup**:
    *   Create a security group using `amazon.aws.ec2_group`.
    *   Add ingress rules for SSH and internal VPC traffic.

3.  **ENI and IP Address Preparation**:
    *   Create the Elastic Network Interface (ENI) using `amazon.aws.ec2_eni`.
    *   Dynamically generate the list of private IP addresses (for the host and KVM guests) and assign them to the ENI.

4.  **EC2 Instance Launch**:
    *   Launch the `c5n.metal` instance using `amazon.aws.ec2_instance`.
    *   Attach the previously created ENI.
    *   Define the block device mappings for the root and data volumes. The logic for generating these mappings will be simplified for clarity and correctness.
    *   Wait for the instance to be in the 'running' state.

## 4. Execution Flow

The playbook will be executed from a single command (`ansible-playbook aws-helper.yaml`). It will be idempotent, meaning it can be run multiple times without causing errors if the resources already exist. The state of the resources will be checked, and tasks will be skipped if the resources are already in the desired state.
