# Cloudflare Pages

This directory configures Cloudflare Pages deployment of the standalone tester app in `example/`.

## Project layout

- `cloudflare-pages/wrangler.toml` — Wrangler config pointing at `example/build/web`.
- `cloudflare-pages/.gitignore` — keeps Wrangler caches and the Pages build out of git.

## One-time setup

1. Install Wrangler:
   ```bash
   npm install -g wrangler
   ```

2. Authenticate:
   ```bash
   wrangler login
   ```

3. Create the Pages project (one time):
   ```bash
   wrangler pages project create tgc-maker-web
   ```
   When asked for production branch, pick `main`.

## Build the Flutter web output

From the repository root:

```bash
cd example
flutter pub get
flutter build web --release --base-href "/"
```

The output goes to `example/build/web/`, which is the `pages_build_output_dir` referenced by `wrangler.toml`.

## Deploy

From the repository root:

```bash
wrangler pages deploy example/build/web --project-name tgc-maker-web
```

That publishes the demo to your Cloudflare Pages URL.

## CI note

This repo no longer ships a GitHub Actions deploy workflow for the web demo. If you later want CI-driven deploys, add a job that runs the two commands above with a `CLOUDFLARE_API_TOKEN` secret.
