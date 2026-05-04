variable "project" {
  description = "Project name prefix for all resources"
  type        = string
  default     = "confluencerag"
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "confluence_webhook_secret" {
  description = "Secret token to validate Confluence webhooks"
  type        = string
  sensitive   = true
}