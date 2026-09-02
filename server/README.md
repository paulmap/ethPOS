# ethPOS AI Assistant Backend

A small self-hosted backend that answers natural-language questions about
product availability, location, and price for the ethPOS app — including
recommending interchangeable/compatible accessories — backed by a local
[Ollama](https://ollama.com) instance. Built as a proof of concept for a
single Contabo VPS with 8GB RAM.

No database, no vector search/embeddings — the catalog is held in memory
(backed by a single JSON file for durability) and retrieval is deterministic
keyword/tag scoring. See `lib/src/retrieval.dart` for the exact logic and
`test/retrieval_test.dart` for its test coverage.

## API

- `GET /health` — no auth. `{"status":"ok","model":"...","catalogSize":N}`
- `POST /v1/sync` — Bearer auth. Full catalog replace. Body:
  `{"products":[{...}]}` (see `lib/src/models/product_dto.dart` for the shape).
- `POST /v1/query` — Bearer auth. Body: `{"question":"..."}` → answer +
  the specific products the answer was based on.

## Local development

```bash
cd server
dart pub get
dart test                 # unit tests, no Ollama/network needed
dart run bin/server.dart  # requires API_KEY env var set, Ollama running locally
```

## Deployment to your Contabo VPS

This is a proof of concept — kept as simple as possible while still being
real and functional. You're doing all VPS-side steps yourself.

### 0. Prerequisite: a domain/subdomain

Caddy's automatic HTTPS needs a DNS A record pointing at your VPS's public
IP *before* it first starts, e.g. `assistant.yourdomain.example -> <VPS IP>`.
Set this up first — it's the one thing Caddy can't do for you.

### 1. Install Ollama and pull the model

```bash
curl -fsSL https://ollama.com/install.sh | sh
ollama pull qwen2.5:3b-instruct
```

`qwen2.5:3b-instruct` (~2.3GB, q4_K_M quantization) is the recommended
default for an 8GB VPS — comfortable headroom after OS + backend overhead
(~1-1.5GB). A 7B-class model is tempting for quality but leaves too thin a
margin to be a safe default here; only consider it if you've confirmed free
memory under load (`free -h` while querying) on the real box.

Sanity check Ollama is working:
```bash
curl http://localhost:11434/api/generate -d '{"model":"qwen2.5:3b-instruct","prompt":"Say hello.","stream":false}'
```

**Security-critical**: Ollama has no authentication of its own. Never expose
port 11434 outside `localhost` — only this backend should ever talk to it.

### 2. Build the backend binary (off the VPS)

Build on a Linux x86_64 machine (matching the VPS architecture) — your own
Linux dev machine, a `dart:stable` Docker container, or a CI runner:

```bash
cd server
dart pub get
dart compile exe bin/server.dart -o ethpos-assistant
```

This produces a single native executable — no Dart SDK, no `pip`, no venv
needs to be installed on the VPS at all.

```bash
scp ethpos-assistant youruser@your-vps-ip:/opt/ethpos-assistant/ethpos-assistant
```

### 3. Configure and run as a systemd service

On the VPS:

```bash
sudo useradd --system --home /var/lib/ethpos-assistant --create-home ethpos-assistant
sudo mkdir -p /opt/ethpos-assistant
# (copy the binary here per step 2)
sudo chmod +x /opt/ethpos-assistant/ethpos-assistant

sudo cp server/.env.example /etc/ethpos-assistant.env
sudo nano /etc/ethpos-assistant.env   # fill in a real API_KEY (generate one in the app's Settings screen)

sudo cp server/systemd/ethpos-assistant.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now ethpos-assistant
sudo systemctl status ethpos-assistant
```

### 4. Caddy for automatic HTTPS

```bash
sudo apt install -y debian-keyring debian-archive-keyring apt-transport-https
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/gpg.key' | sudo gpg --dearmor -o /usr/share/keyrings/caddy-stable-archive-keyring.gpg
curl -1sLf 'https://dl.cloudsmith.io/public/caddy/stable/debian.deb.txt' | sudo tee /etc/apt/sources.list.d/caddy-stable.list
sudo apt update && sudo apt install -y caddy

sudo cp server/Caddyfile /etc/caddy/Caddyfile
sudo nano /etc/caddy/Caddyfile   # replace with your real domain
sudo systemctl reload caddy
```

### 5. Firewall

```bash
sudo ufw allow 22
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
# Do NOT open 11434 (Ollama) or the backend's own port (8080) — only Caddy
# should be reachable from outside; it proxies to the backend over localhost.
```

### 6. Smoke test from your own machine

```bash
curl https://assistant.yourdomain.example/health

curl https://assistant.yourdomain.example/v1/query \
  -H "Authorization: Bearer <your API key>" \
  -H "Content-Type: application/json" \
  -d '{"question":"do you have a case for iphone 12"}'
```

Then in the ethPOS app: Settings → AI Assistant → enter the backend URL and
API key, enable the assistant, tap **Sync Now**, and ask a question.

## Known limitations (accepted at POC scope)

- Single shared API key — no per-staff identity, no rotation beyond manually
  regenerating one in Settings, no rate limiting.
- Chat history in the app is in-memory only and resets on app restart.
- Sync is manual ("Sync Now"), not automatic on every inventory change.
- Retrieval is keyword/tag-based, not semantic search — if this proves
  insufficient in real use, an embeddings-based upgrade is the natural next
  step, without needing to change the HTTP contract with the Flutter app.
