# MindSprouts

MindSprouts is a Flask-based quiz platform for students and admins.

## Tech Stack

- Flask
- PostgreSQL
- Gunicorn
- Render (Web Service + Postgres)

## Required Environment Variables

Set these in your Render Web Service:

- `SECRET_KEY`
- `DATABASE_URL` (use Render Postgres Internal Database URL)

Optional:

- `LOG_LEVEL` (default: `INFO`)

## Health Endpoints

- `GET /live` -> process liveness check (no database call)
- `GET /health` -> application + database readiness check

Examples:

- `https://mindsprouts.onrender.com/live`
- `https://mindsprouts.onrender.com/health`

## Deploy on Render

1. Push changes to GitHub `main`.
2. In Render Web Service, verify env vars:
   - `SECRET_KEY`
   - `DATABASE_URL`
3. Deploy latest build.
4. Validate:
   - `/live` returns `{"status":"alive"}`
   - `/health` returns `{"status":"ok","database":"up"}`

## One-time Migration (Railway MySQL -> Render Postgres)

Run with Docker + pgloader from your machine:

```powershell
docker run --rm -it ghcr.io/dimitri/pgloader:latest pgloader "mysql://<user>:<password>@<railway-public-host>:<port>/<db>" "postgresql://<user>:<password>@<render-external-host>:5432/<db>?sslmode=require"
```

Use Railway public proxy host/port (not `mysql.railway.internal`) when running from local machine.

