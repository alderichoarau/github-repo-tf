# Terraform GitHub Repository Factory

Terraform module that provisions a GitHub repository with sane defaults and branch protection, triggered via GitHub Actions workflow dispatch.

## What it does

- Creates a public GitHub repository with Issues enabled
- Initializes the repository with a first commit (required for branch protection)
- Applies a `.gitignore` template from GitHub's catalog
- Protects the `main` branch:
  - Requires at least 1 approved pull request review before merging
  - Dismisses stale reviews when new commits are pushed
  - Blocks direct pushes and force pushes to `main`
  - Prevents deletion of the `main` branch
- Injects a starter CI workflow (`.github/workflows/ci.yml`) into the created repository
- Automatically deletes merged feature branches

## Typical workflow

```
1. Run "Create GitHub Repository" → repository is created, no one has access yet
2. Push your content to the new repository
3. Run "Share GitHub Repository" → collaborators receive their invitation
```

This two-step approach ensures collaborators only get access once the repository content is ready.

## Project structure

```
.
├── main.tf                  # GitHub repository, branch protection and collaborator resources
├── variables.tf             # Input variable declarations
├── outputs.tf               # Repository URLs and full name outputs
├── providers.tf             # Terraform and GitHub provider configuration
├── terraform.tfvars.example # Example variables file (copy to terraform.tfvars locally)
├── .terraform.lock.hcl      # Provider version lock file
└── .github/
    ├── dependabot.yml       # Automated dependency updates (Actions + Terraform, weekly)
    └── workflows/
        ├── create-repo.yml         # Create a repository without adding collaborators
        ├── share-repo.yml          # Add collaborators to an existing repository
        └── terraform-pr-checks.yml # PR quality and security checks
```

## GitHub Actions workflows

### Create a repository — `create-repo.yml`

Triggered manually from **Actions > Create GitHub Repository with Terraform > Run workflow**.

Collaborators are never added at this stage (`collaborators = {}`).

| Input | Required | Description |
|-------|----------|-------------|
| `repo_name` | Yes | Name of the repository to create |
| `repo_description` | No | Short description of the repository |

### Share a repository — `share-repo.yml`

Triggered manually from **Actions > Share GitHub Repository > Run workflow** once the repository content is ready.

Uses the GitHub API directly — no Terraform state required.

| Input | Required | Description |
|-------|----------|-------------|
| `repo_name` | Yes | Name of the repository to share |
| `collaborators` | No | `user1:push,user2:admin` — defaults to the `DEFAULT_COLLABORATORS` variable if empty |

### PR checks — `terraform-pr-checks.yml`

Runs automatically on every pull request that modifies `.tf` or workflow files.

| Job | Tools | Blocks merge? |
|-----|-------|---------------|
| Format & Validate | `terraform fmt`, `terraform validate`, tflint | Yes |
| Security | Checkov (SARIF → Security tab) | No (`soft_fail: true`) |
| Plan | `terraform plan` posted as a PR comment | No (runs after Format & Validate) |

## Required secrets and variables

Configure these in **Settings > Secrets and variables > Actions**:

| Name | Type | Description |
|------|------|-------------|
| `GH_TOKEN` | Secret | GitHub Personal Access Token with `repo` and `workflow` scopes |
| `GH_OWNER` | Secret | Your GitHub username or organization name |
| `DEFAULT_COLLABORATORS` | Variable | Default collaborators list: `user1:push,user2:admin` |

> **Note:** `DEFAULT_COLLABORATORS` is a **Variable** (plain text), not a Secret. Store it under the **Variables** tab, not Secrets.

## Local usage

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Fill in your values in `terraform.tfvars` (never commit this file):
   ```hcl
   github_token       = "ghp_xxxxxxxxxxxxxxxxxxxx"
   github_owner       = "your-username"
   repo_name          = "my-new-repo"
   repo_description   = "My project description"
   gitignore_template = "Terraform"
   collaborators      = { "user1" = "push", "user2" = "admin" }
   ```

3. Initialize, plan, and apply:
   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

## Variables

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `github_token` | `string` | — | GitHub Personal Access Token |
| `github_owner` | `string` | — | GitHub username or organization |
| `repo_name` | `string` | — | Name of the repository to create |
| `repo_description` | `string` | `""` | Repository description |
| `gitignore_template` | `string` | `"Terraform"` | GitHub `.gitignore` template name |
| `collaborators` | `map(string)` | `{}` | Collaborators map (local use only — the workflow uses `DEFAULT_COLLABORATORS`) |

## Outputs

| Name | Description |
|------|-------------|
| `repository_url` | GitHub web URL of the created repository |
| `repository_https_clone_url` | HTTPS clone URL |
| `repository_ssh_clone_url` | SSH clone URL |
| `repository_full_name` | Full name in `owner/repo` format |

## Requirements

| Tool | Version |
|------|---------|
| Terraform | `>= 1.3.0` |
| GitHub provider | `~> 6.0` |
