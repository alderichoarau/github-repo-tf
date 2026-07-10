# Terraform GitHub Repository Factory

Terraform module that provisions a GitHub repository with sane defaults and branch protection, triggered via GitHub Actions workflow dispatch.

## What it does

- Creates a public GitHub repository with Issues, Projects, and Wiki enabled
- Initializes the repository with a first commit (required for README and branch protection)
- Applies a `.gitignore` template from GitHub's catalog
- Protects the `main` branch:
  - Requires at least 1 approved pull request review before merging
  - Requires review from Code Owners
  - Requires the CI status check (`validate`) to pass before merging
  - Dismisses stale reviews when new commits are pushed
  - Blocks direct pushes and force pushes to `main`
  - Prevents deletion of the `main` branch
- Injects starter files into the created repository:
  - `.github/workflows/ci.yml` — starter CI workflow
  - `.github/CODEOWNERS` — assigns `@alderichoarau` as owner of the whole repository
  - `.github/dependabot.yml` — weekly GitHub Actions dependency updates
- Enables repository security features:
  - Dependabot alerts
  - Dependabot security updates
  - Dependency graph (automatic on public repositories)
- Automatically deletes merged feature branches

> **Note:** Private vulnerability reporting is not yet supported by the `integrations/github` Terraform provider and must be enabled manually from **Settings > Code security** if desired.

## Typical workflow

```
1. Run "Create GitHub Repository with Terraform" → repository is created with branch protection and starter files
2. Push your content to the new repository
3. Add collaborators locally (see "Local usage") or manually from the GitHub UI
```

## Project structure

```
.
├── main.tf                  # GitHub repository, branch protection, security, collaborator and repository file resources
├── variables.tf             # Input variable declarations
├── outputs.tf               # Repository URLs and full name outputs
├── providers.tf             # Terraform and GitHub provider configuration
├── .terraform.lock.hcl      # Provider version lock file
└── .github/
    ├── dependabot.yml       # Automated dependency updates for this repo (Actions + Terraform, weekly)
    └── workflows/
        ├── create-repository.yml   # Create a repository via Terraform (workflow_dispatch)
        └── terraform-pr-checks.yml # PR quality and security checks
```

## GitHub Actions workflows

### Create a repository — `create-repository.yml`

Triggered manually from **Actions > Create GitHub Repository with Terraform > Run workflow**.

Collaborators are never added at this stage (`collaborators = {}`).

| Input | Required | Description |
|-------|----------|-------------|
| `repo_name` | Yes | Name of the repository to create |
| `repo_description` | No | Short description of the repository |

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

## Local usage

1. Create a `terraform.tfvars` file (never commit this file):
   ```hcl
   github_token       = "ghp_xxxxxxxxxxxxxxxxxxxx"
   github_owner       = "your-username"
   repo_name          = "my-new-repo"
   repo_description   = "My project description"
   gitignore_template = "Terraform"
   collaborators      = { "user1" = "push", "user2" = "admin" }
   ```

2. Initialize, plan, and apply:
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
| `collaborators` | `map(string)` | `{}` | Collaborators map: username => permission (local use only — the GitHub Actions workflow always passes `{}`) |

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
