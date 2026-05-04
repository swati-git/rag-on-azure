output "webhook_url" {
  value = module.functions.webhook_function_url
}

output "service_bus_queue" {
  value = module.service_bus.queue_name
}