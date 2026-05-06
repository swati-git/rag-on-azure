variable "resource_group_name"        { type = string }
variable "location"                   { type = string }
variable "project"                    { type = string }
variable "environment"                { type = string }

variable "service_bus_connection_str" { 
    type = string  
    sensitive = true 
    }
