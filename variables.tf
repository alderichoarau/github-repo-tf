variable "github_token" {
  description = "GitHub Personal Access Token (classic) with repo and workflow scopes"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "Your GitHub username or organization name"
  type        = string
}

variable "repo_name" {
  description = "Name of the GitHub repository to create"
  type        = string
}

variable "repo_description" {
  description = "Repository description"
  type        = string
  default     = ""
}

variable "gitignore_template" {
  description = ".gitignore template to use (e.g. Terraform, Python, Node, Go...)"
  type        = string
  default     = "Terraform"
}

variable "collaborators" {
  description = "Map of GitHub collaborators: username => permission (pull, push, maintain, triage, admin)"
  type        = map(string)
  default     = {}
}
