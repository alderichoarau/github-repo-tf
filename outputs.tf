output "repository_url" {
  description = "GitHub web URL of the repository"
  value       = github_repository.repo.html_url
}

output "repository_https_clone_url" {
  description = "HTTPS URL to clone the repository"
  value       = github_repository.repo.http_clone_url
}

output "repository_ssh_clone_url" {
  description = "SSH URL to clone the repository"
  value       = github_repository.repo.ssh_clone_url
}

output "repository_full_name" {
  description = "Full name of the repository (owner/repo)"
  value       = github_repository.repo.full_name
}
