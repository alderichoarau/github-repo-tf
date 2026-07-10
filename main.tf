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
  has_projects = false
  has_wiki     = false

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
  }

  # Block direct pushes to main (even for admins)
  enforce_admins = false

  # Prevent force pushes to main
  allows_force_pushes = false

  # Prevent deletion of the main branch
  allows_deletions = false
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
      build:
        runs-on: ubuntu-latest

        steps:
          - name: Checkout code
            uses: actions/checkout@v4

          - name: Example step
            run: echo "Add your build/test steps here!"
  EOT
}
