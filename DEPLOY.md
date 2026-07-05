# Deploy: reprovsrarity.reefcode.org (run these yourself)

This file stages the GitHub and DNS steps for the
`reprovsrarity.reefcode.org` repo. Nothing in this repo has been pushed, no
remote has been added, and no GitHub setting has been changed. Run the
commands below yourself, in order, when ready.

## PRECONDITION (must be confirmed before this repo goes public)

**Confirm co-author data clearance before flipping this repository public.**
This site bundles reproductive-mode tables (Mahoney/Olinger) and Lasker
octocoral data. Do not run the `--public` repo-creation step below, and do not
make this repository or its Pages site public, until that clearance is
confirmed with the co-authors.

## 1. Create the GitHub repo (public, after clearance above) and push

```bash
gh repo create "laurenkolinger/reprovsrarity.reefcode.org" --public --source=. --remote=origin
git push -u origin main
```

## 2. GitHub Pages settings

In the repo on GitHub: **Settings > Pages > Build and deployment > Source:
Deploy from a branch**, then set **Branch: `main`, folder: `/docs`**.

## 3. DNS at the reefcode.org registrar

Add a `CNAME` record for the `reprovsrarity` host pointing at
`laurenkolinger.github.io`:

```
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
