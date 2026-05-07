variable "resource_group_name"           { type = string }
variable "location"                      { type = string }
variable "project"                       { type = string }
variable "environment"                   { type = string }

# passed from module.functions outputs
variable "service_plan_id"               { type = string }
variable "storage_account_name"          { type = string }
variable "storage_account_key"           { 
    type = string
    sensitive = true 
    }

# passed from module.search outputs
variable "search_endpoint"              { type = string }

variable "service_bus_connection_str"    {type = string}

variable "search_service_id"    {type = string}