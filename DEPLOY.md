# Deploy: reprovsrarity.reefcode.org (run these yourself)

This file stages the GitHub and DNS steps for the
`reprovsrarity.reefcode.org` repo.

## STATUS (updated 2026-07-06)

Co-author data clearance was confirmed, so the repo was published. State:

- **Step 1 — repo + push: DONE.** `laurenkolinger/reprovsrarity.reefcode.org`
  was created **public**, `origin` added, and `main` pushed.
- **Step 2 — Pages: DONE.** Pages is enabled from `main` / `/docs` with the
  custom domain `reprovsrarity.reefcode.org` (read from `docs/CNAME`).
- **Step 3 — DNS: PENDING (do this at the reefcode.org registrar).** See below.
- **Step 4 — HTTPS: after DNS.** Once the `reprovsrarity` host resolves,
  GitHub issues the TLS cert; then turn on **Enforce HTTPS** in Settings > Pages.

## PRECONDITION (was required before going public)

Co-author data clearance for the reproductive-mode tables (Mahoney/Olinger)
and octocoral data was confirmed on 2026-07-06, before the repo was made public.

## 1. Create the GitHub repo (public) and push — DONE

```bash
gh repo create "laurenkolinger/reprovsrarity.reefcode.org" --public --source=. --remote=origin
git push -u origin main
```

## 2. GitHub Pages settings — DONE

Pages source is **Deploy from a branch**, **Branch: `main`, folder: `/docs`**
(set via the API; visible under **Settings > Pages**).

## 3. DNS at the reefcode.org registrar

Add a `CNAME` record for the `reprovsrarity` host pointing at
`laurenkolinger.github.io`:

```text
reprovsrarity.reefcode.org.   CNAME   laurenkolinger.github.io.
```

The `CNAME` file in this repo (contents: `reprovsrarity.reefcode.org`) is
already staged at both the repo root and `docs/CNAME` (the served Pages root,
which is the plain `output-dir: docs`, no hashed folder here), and is listed
under `_quarto.yml`'s `resources:` so a future `quarto render` re-copies it
into `docs/` automatically. GitHub Pages reads `docs/CNAME` to know the custom
domain to serve and to request the TLS certificate for.

## 4. Verify

- `git -C "reprovsrarity.reefcode.org" remote -v` should show `origin`
  pointing at `laurenkolinger/reprovsrarity.reefcode.org` only after step 1
  above.
- After DNS propagates and Pages picks up the custom domain, check
  `https://reprovsrarity.reefcode.org` loads and GitHub shows "DNS check
  successful" plus an issued HTTPS certificate under Settings > Pages.
