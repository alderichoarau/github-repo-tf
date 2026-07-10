# -------------------------------------------------------
# GitHub Repository
# -------------------------------------------------------
resource "github_repository" "repo" {
  name        = var.repo_name
  description = var.repo_description
  visibility  = "public"

  # Initialize with an empty commit (required for README and branch protection)
  auto_init = true

  # Automatically add a .gitignore file from GitHub templates
  gitignore_template = var.gitignore_template

  has_issues   = true
  has_projects = true
  has_wiki     = true

  # Automatically delete merged branches after a PR is merged
  delete_branch_on_merge = true
}

# -------------------------------------------------------
# Main branch protection
# -------------------------------------------------------
resource "github_branch_protection" "main" {
  repository_id = github_repository.repo.node_id
  pattern       = "main"

  # Require at least one approved review before merging
  required_pull_request_reviews {
    required_approving_review_count = 1
    dismiss_stale_reviews           = true
    require_code_owner_reviews      = true
  }

  # Require the CI "validate" job to pass before merging
  required_status_checks {
    strict   = true
    contexts = ["validate"]
  }

  # Block direct pushes to main (even for admins)
  enforce_admins = false

  # Prevent force pushes to main
  allows_force_pushes = false

  # Prevent deletion of the main branch
  allows_deletions = false

  depends_on = [github_repository_file.ci_workflow]
}

# -------------------------------------------------------
# Dependabot alerts
# -------------------------------------------------------
resource "github_repository_vulnerability_alerts" "main" {
  repository = github_repository.repo.name
}

# -------------------------------------------------------
# Dependabot security updates
# -------------------------------------------------------
resource "github_repository_dependabot_security_updates" "main" {
  repository = github_repository.repo.name
  enabled    = true

  depends_on = [github_repository_vulnerability_alerts.main]
}

# -------------------------------------------------------
# Repository collaborators
# -------------------------------------------------------
resource "github_repository_collaborator" "collaborators" {
  for_each   = var.collaborators
  repository = github_repository.repo.name
  username   = each.key
  permission = each.value
}

# -------------------------------------------------------
# Example GitHub Actions CI workflow
# -------------------------------------------------------
resource "github_repository_file" "ci_workflow" {
  repository          = github_repository.repo.name
  branch              = "main"
  file                = ".github/workflows/ci.yml"
  commit_message      = "ci: add GitHub Actions CI workflow"
  overwrite_on_create = true

  content = <<-EOT
    name: CI

    on:
      push:
        branches: [ "main" ]
      pull_request:
        branches: [ "main" ]

    jobs:
      validate:
        runs-on: ubuntu-latest

        steps:
          - name: Checkout code
            uses: actions/checkout@v7

          - name: Example step
            run: echo "Add your build/test steps here!"
  EOT
}

# -------------------------------------------------------
# CODEOWNERS
# -------------------------------------------------------
resource "github_repository_file" "codeowners" {
  repository          = github_repository.repo.name
  branch              = "main"
  file                = ".github/CODEOWNERS"
  commit_message      = "chore: add CODEOWNERS"
  overwrite_on_create = true

  content = <<-EOT
    * @alderichoarau
  EOT
}

# -------------------------------------------------------
# Dependabot configuration
# -------------------------------------------------------
resource "github_repository_file" "dependabot" {
  repository          = github_repository.repo.name
  branch              = "main"
  file                = ".github/dependabot.yml"
  commit_message      = "chore: add Dependabot configuration"
  overwrite_on_create = true

  content = <<-EOT
    version: 2

    updates:
      - package-ecosystem: "github-actions"
        directory: "/"
        schedule:
          interval: "weekly"
  EOT
}
