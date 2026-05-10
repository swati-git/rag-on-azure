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

variable "azure_openai_embedding_model"  {type = string}

variable "azure_openai_endpoint"         { type = string }

variable "azure_openai_id"         { type = string }


variable "confluence_base_url"           { type = string }
variable "confluence_email"              { type = string }
variable "confluence_api_token"          { 
    type = string  
    sensitive = true 
    } 
