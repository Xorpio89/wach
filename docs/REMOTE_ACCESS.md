# Remote Access Guide

## Quick Start

### 1. Server starten
```bash
# Flutter App (Port 8080)
cd wach_flutter && flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0

# Webhook Server (Port 8081) - proxied die App + Webhook
python webhook_server.py

# ngrok Tunnel
ngrok http 8081
```

### 2. URLs
- **App:** `https://<ngrok-url>/`
- **Webhook:** `https://<ngrok-url>/webhook`

---

## Webhook Commands

Alle Befehle per POST an `/webhook`:

| Command | Beschreibung |
|---------|-------------|
| `restart` | Flutter App neustarten |
| `status` | Server Status prüfen |
| `git-status` | Git Status anzeigen |
| `git-log` | Letzte 5 Commits |
| `commit` | Auto-Commit aller Änderungen |
| `push` | Git Push zu GitHub |
| `deploy` | Auto-Commit + Push (triggert GitHub Pages) |
| `feature` | Feature Request speichern (siehe unten) |

### Feature Request

Speichere Feature-Wünsche für die nächste Claude Session:

```bash
curl -X POST https://<ngrok-url>/webhook \
  -H "Content-Type: application/json" \
  -d '{"command": "feature", "text": "Add dark mode toggle"}'
```

Die Requests werden in `feature_requests.txt` gespeichert.

### Beispiel (curl)
```bash
curl -X POST https://<ngrok-url>/webhook \
  -H "Content-Type: application/json" \
  -d '{"command": "restart"}'
```

### Beispiel (JavaScript/Fetch)
```javascript
fetch('https://<ngrok-url>/webhook', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ command: 'status' })
}).then(r => r.json()).then(console.log);
```

---

## ngrok Setup

```bash
# Auth Token setzen (einmalig)
ngrok config add-authtoken <YOUR_TOKEN>

# Tunnel starten
ngrok http 8081
```

Free Tier: 1 Tunnel, URL ändert sich bei jedem Neustart.
