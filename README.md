# lambda_selenium_container

### You will need

- [AWS Account](https://aws.amazon.com/free)
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-welcome.html)
- Verify two email addresses in [AWS SES](https://docs.aws.amazon.com/ses/latest/dg/creating-identities.html#verify-email-addresses-procedure)
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Docker](https://docs.docker.com/engine/install/)

### Create AWS ECR Repository
```
cd terraform 
terraform init
terraform apply -target=aws_ecr_repository.lambda_selenium_container
```
The ECR Repository url will be output to the shell. Use that output to push the docker container 
```
export ECR_URL=< aws_ecr_repository_url from above >
cd ..
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin "$ECR_URL"
docker build --platform linux/amd64 --push -t  "$ECR_URL":latest .
```

### Create the lambda and configure the Lambda function
```
cp terraform.tfvars.tmpl terraform.tfvars
```
fill in the verified to and from emails in the tfvars file
```
cd terraform
terraform apply
```

### TODO
- add email alert for lambda errors
