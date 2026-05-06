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

