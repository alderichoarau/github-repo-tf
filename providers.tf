terraform {
  required_version = ">= 1.4.0"

  cloud {
    organization = "alderic-hoarau"

    # Each repo created by this configuration gets its own workspace
    # (selected/created dynamically in CI via `terraform workspace select -or-create`),
    # so that creating repo B never touches repo A's state.
    # Workspaces must carry this tag (new ones get it automatically).
    workspaces {
      tags = ["github-repo-factory"]
    }
  }

  required_providers {
    github = {
      source  = "integrations/github"
      version = "~> 6.0"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}
