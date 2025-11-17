# Alertmanager Configuration

## Overview
The `alertmanager-config.yaml` file defines a ConfigMap that contains the Alertmanager configuration. Alertmanager handles alerts from Prometheus and routes them to notification channels like Slack or email.

## Key Components

### ConfigMap Resource
- **Name**: `alertmanager-config`
- **Namespace**: `observability`
- **Label**: `app: alertmanager`

### Configuration Sections

#### Global Settings
- `resolve_timeout`: 5 minutes
  - Time to wait before marking an alert as resolved if it stops firing

#### Routing Configuration
- `receiver`: Default receiver (`slack-or-email`)
- `group_by`: Groups alerts by `alertname` and `job`
- `group_wait`: 30 seconds
  - Wait time before sending first notification for a group
- `group_interval`: 5 minutes
  - Wait time before sending another notification for the same group
- `repeat_interval`: 12 hours
  - Wait time before repeating a notification

#### Route Rules
- **Default Route**: Sends to `slack-or-email` receiver
- **Critical Route**: Alerts with `severity: critical` label go to `email` receiver

#### Receivers

##### Slack Receiver (`slack-or-email`)
- **Type**: Slack webhook
- **API URL**: `https://hooks.slack.com/services/YOUR/HOOK` (needs to be configured)
- **Channel**: `#alerts`
- **Title**: Uses alert annotations summary

##### Email Receiver (`email`)
- **Type**: SMTP email
- **To**: `you@example.com` (needs to be configured)
- **From**: `alertmanager@example.com`
- **SMTP Host**: `smtp.example.com:587`
- **Authentication**: Username and password (needs to be configured)

## How It Works
1. Prometheus evaluates alert rules and fires alerts
2. Prometheus sends alerts to Alertmanager
3. Alertmanager groups alerts based on `group_by` settings
4. Alertmanager routes alerts to receivers based on labels and routes
5. Receivers send notifications via configured channels (Slack/Email)

## Configuration Requirements
⚠️ **Important**: This is a template configuration. You need to update:
- Slack webhook URL in `slack_configs.api_url`
- Email configuration (to, from, smarthost, credentials)
- Adjust routing rules based on your alert labels

## Alert Routing Flow
```
Prometheus Alert → Alertmanager → Route Matching → Receiver → Notification
```

## Integration
- Alertmanager reads this ConfigMap when mounted as a volume
- The ConfigMap must be referenced in the Alertmanager deployment
- Changes to ConfigMap require Alertmanager pod restart

## Best Practices
- Use different receivers for different severity levels
- Configure proper grouping to avoid alert fatigue
- Set appropriate intervals to balance responsiveness and noise
- Test notification channels before production use

