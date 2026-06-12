import json
import os
import urllib.error
import urllib.request

import boto3


_secrets_client = boto3.client("secretsmanager")
_webhook_url = None


def handler(event, context):
    for record in event.get("Records", []):
        alert = _extract_alert(record.get("body", ""))
        _post_to_teams(_format_message(alert))

    return {"processed": len(event.get("Records", []))}


def _extract_alert(body):
    try:
        payload = json.loads(body)
    except json.JSONDecodeError:
        return {"Message": body}

    message = payload.get("Message")
    if isinstance(message, str):
        try:
            return json.loads(message)
        except json.JSONDecodeError:
            payload["Message"] = message

    return payload


def _format_message(alert):
    alarm_name = alert.get("AlarmName", "Gen3 alert")
    state = alert.get("NewStateValue", "ALARM")
    reason = alert.get("NewStateReason") or alert.get("Message") or "No reason provided."
    timestamp = alert.get("StateChangeTime", "Unknown")
    region = alert.get("Region", os.environ.get("AWS_REGION", "Unknown"))
    domain = os.environ.get("GEN3_DOMAIN", "Unknown")

    return "\n".join(
        [
            f"**{alarm_name}**",
            f"State: {state}",
            f"Domain: {domain}",
            f"Region: {region}",
            f"Time: {timestamp}",
            f"Reason: {reason}",
        ]
    )


def _post_to_teams(message):
    webhook_url = _get_webhook_url()
    data = json.dumps({"text": message}).encode("utf-8")
    request = urllib.request.Request(
        webhook_url,
        data=data,
        headers={"Content-Type": "application/json"},
        method="POST",
    )

    try:
        with urllib.request.urlopen(request, timeout=8) as response:
            if response.status >= 300:
                body = response.read().decode("utf-8", errors="replace")
                raise RuntimeError(f"Teams webhook returned HTTP {response.status}: {body}")
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        raise RuntimeError(f"Teams webhook returned HTTP {exc.code}: {body}") from exc
    except urllib.error.URLError as exc:
        raise RuntimeError(f"Teams webhook request failed: {exc}") from exc


def _get_webhook_url():
    global _webhook_url

    if _webhook_url:
        return _webhook_url

    secret_arn = os.environ["TEAMS_WEBHOOK_SECRET_ARN"]
    response = _secrets_client.get_secret_value(SecretId=secret_arn)
    _webhook_url = response["SecretString"]
    return _webhook_url
