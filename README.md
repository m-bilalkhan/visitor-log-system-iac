# Visitor Log System Infrastructure as Code (IaC)

Welcome to the infrastructure repository for the **Visitor Log System** portfolio project. This repo provisions and configures all AWS resources required for the application using Terraform.

[Application Repo Link:](https://github.com/m-bilalkhan/visitor-log-system/tree/development_server)

## On going project. Prod Env Will be added Soon

---

## 📦 Structure

```
.
├── environments/         # Environment-specific Terraform configs (dev, prod, etc.)
│   └── dev/
│       └── ap-south-1/
│           └── main.tf
│           └── backend.tf # S# Remote TF State
├── modules/              # Reusable Terraform modules
│   ├── networking/
│   ├── security-groups/
│   ├── s3/
│   ├── load-balancer/
│   ├── rds/
│   ├── iam-role/
│   ├── auto-scaling/
│   └── route53/
└── .github/
    └── workflows/
        └── terraform-deploy-dev.yaml
```

---

## 🚀 Features

- **Modular Terraform**: Clean separation of networking, security, compute, storage, and database resources.
- **Environment Support**: Easily deploy to multiple AWS regions/environments.
- **CI/CD Integration**: Automated deployments via GitHub Actions.
- **Best Practices**: Implements S3 lifecycle policies, secure IAM roles, VPC endpoints, and more.

---

## ⚙️ CI/CD

- Automated deployments are handled via [GitHub Actions](.github/workflows/terraform-deploy-dev.yaml).
- AMI resolution and environment variables are managed in the workflow.

---

## 📚 Modules

- **Networking**: VPC, subnets, routing.
- **Security Groups**: Fine-grained access control.
- **S3**: Buckets with lifecycle and access policies.
- **Load Balancer**: ALB setup and logging.
- **RDS**: PostgreSQL database provisioning.
- **IAM Role**: Secure role creation for services.
- **Auto Scaling**: EC2 scaling groups.
- **Route53**: DNS management.

---

## Workflow Diagram

![Infrastructure Diagram](/diagram.png)

---

## Application Screenshots Attach

![Application SS](/app-ss.png)

---

## 📝 Contributing

Pull requests and issues are welcome! Please follow best practices and ensure all code is properly formatted.

---

## 📄 License

This project is licensed under the MIT License.

---

## 👤 Author

Muhammad Bilal Khan  

---

> **Note:** This repo is for educational and portfolio purposes. Please review and adapt configurations before using in production.