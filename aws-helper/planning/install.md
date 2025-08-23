# env prepare

```bash
ansible-galaxy collection install amazon.aws

pip install botocore boto3

ansible-playbook aws-helper.yaml --check --diff -vvv

```