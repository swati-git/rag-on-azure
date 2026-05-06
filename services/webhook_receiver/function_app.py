import logging
import json
import os
import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)
logger = logging.getLogger(__name__)

RELEVANT_EVENTS = {
    "page_created",
    "page_updated",
    "page_removed",
    "page_trashed"
}

@app.route(route="webhook_receiver", methods=["POST"])
def webhook_receiver(req: func.HttpRequest) -> func.HttpResponse:

    from azure.servicebus import ServiceBusClient, ServiceBusMessage

    SERVICE_BUS_CONNECTION_STR = os.environ["SERVICE_BUS_CONNECTION_STR"]
    SERVICE_BUS_QUEUE_NAME     = os.environ["SERVICE_BUS_QUEUE_NAME"]

    try:
        payload = req.get_json()
    except ValueError:
        return func.HttpResponse("Invalid JSON", status_code=400)

    event_type = payload.get("webhookEvent", "")

    if event_type not in RELEVANT_EVENTS:
        logger.info(f"Ignoring event type: {event_type}")
        return func.HttpResponse("Ignored", status_code=200)

    page      = payload.get("page", {})
    page_id   = str(page.get("id", ""))
    title     = page.get("title", "")
    space_key = page.get("spaceKey", "")

    if not page_id:
        return func.HttpResponse("Missing page ID", status_code=400)

    message_body = {
        "page_id":    page_id,
        "event_type": event_type,
        "space_key":  space_key,
        "title":      title,
    }

    try:
        with ServiceBusClient.from_connection_string(SERVICE_BUS_CONNECTION_STR) as client:
            with client.get_queue_sender(SERVICE_BUS_QUEUE_NAME) as sender:
                msg = ServiceBusMessage(
                    json.dumps(message_body),
                    content_type="application/json",
                    subject=page_id
                )
                sender.send_messages(msg)

        logger.info(f"Published {event_type} for '{title}' ({page_id}) to Service Bus")
        return func.HttpResponse("OK", status_code=200)

    except Exception as e:
        logger.error(f"Failed to publish to Service Bus: {e}")
        return func.HttpResponse("Internal error", status_code=500)



        