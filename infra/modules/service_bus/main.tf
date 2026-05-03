resource "azurerm_servicebus_namespace" "main" {
  name                = "${var.project}-sb-${var.environment}"
  location            = var.location
  resource_group_name = var.resource_group_name
  sku                 = "Standard"   # Standard required for queues with dead letter
}

resource "azurerm_servicebus_queue" "page_events" {
  name         = "confluence-page-events"
  namespace_id = azurerm_servicebus_namespace.main.id

  # how long an unprocessed message lives before going to dead letter queue
  message_time_to_live                  = "PT1H"

  # how long the indexing worker has to process a message before it reappears
  lock_duration                         = "PT5M"

  # retry up to 5 times before sending to dead letter
  max_delivery_count                    = 5

  # enable dead letter queue automatically (it's a sub-queue, not a resource)
  dead_lettering_on_message_expiration  = true
}

#resource "azurerm_servicebus_queue" "page_events_deadletter_monitor" {
  # we don't create the DLQ — Azure creates it automatically
  # this is just a note: access it at:
  # confluence-page-events/$deadletterqueue
#}