# reprovsrarity.reefcode.org

Companion website for the manuscript on how reproductive mode and rarity relate
to long-term coral population trajectories in the U.S. Virgin Islands. The site
reruns every analysis from raw monitoring data and publishes the code, inputs,
and figures alongside the results.

**Live site:** https://reprovsrarity.reefcode.org

> Olinger LK, Edmunds PJ, Levitan D, Smith TB, Lasker H, Feeley M, Mahoney L,
> Dahl A. Reproductive mode, but not rarity, influences population trajectories
> in corals. In Review 2026.

This repo is one publication in the **Reef Code** family: the main analyses site
[reefcode.org](https://reefcode.org), each publication on its own subdomain, and
a shared publication template. They are built to look like one website and share
a common navigation menu.

## What the site contains

- **Overview** (`qmd/00_overview.qmd`): the study, the three coral-cover
  monitoring programs (TCRMP, VINPS, CSUN) and the octocoral program, the site
  map, and the reproductive-mode and rarity methods.
- **Four analyses, two versions each.** Each program has an *as-submitted*
  version that reruns the analysis exactly as it appears in the manuscript, and
  an *updated* version that reruns the identical code over a longer year range.
  Sources live in `qmd/aspublished/` and `qmd/updated/`
  (`02_tcrmp`, `03_vinps`, `04_csun`, `05_octocoral`).
- **Conclusions / interactive** (`qmd/06_interactive.qmd`): results and an
  interactive shinylive tool.
- **Manuscript values** (`qmd/07_manuscript_values.qmd`): the exact numbers
  cited in the paper, regenerated from the data.

## Repository layout

```text
qmd/                 Page sources (.qmd) rendered into the site
  aspublished/       As-submitted version of each program analysis
  updated/           Updated (extended year range) version of each analysis
  figures/           Static figures (e.g. the site map)
_includes/           Shared analysis modules and R helpers (_analysis_*.qmd, *.R)
_extensions/         The shared reefcode Quarto theme
_nav.html            The two-row Reef Code menu (identical across all repos)
data/
  downloads/         Original input datasets + metadata, served for download
  rdata/             Cached per-program baseline classifications (.RData)
  site/              Site master table
references.bib        Shared bibliography
science.csl           Science citation style
_quarto.yml           Project + render config
_variables.yml        Cross-site links (reefcode home, data sources, sibling pubs)
docs/                 Rendered site (GitHub Pages serves this folder)
DEPLOY.md             Publish + subdomain steps and their current status
```

## Build locally

Requirements: [Quarto](https://quarto.org) (built with 1.8.24) and R with the
`tidyverse` and `kableExtra` packages (plus whatever the modules in `_includes/`
load).

```bash
quarto render                 # render the whole site into docs/
quarto preview                # render + serve with live reload
```

Or serve the already-built output:

```bash
python3 -m http.server 8080 --directory docs
# then open http://127.0.0.1:8080
```

Renders are warning-free by design: `_quarto.yml` sets
`execute: { warning: false, message: false }`. Keep it that way.

## Data

The coral-cover data behind the TCRMP, VINPS, and CSUN analyses comes from the
Reef Code benthic cover section:

- Coral species cover (backs TCRMP and VINPS):
  https://reefcode.org/qmd/2_benthiccover/05_coral_species.html
- Coral genera cover (backs CSUN):
  https://reefcode.org/qmd/2_benthiccover/04_coral_genera.html

The exact input files used here, clipped to each analysis year range, plus their
metadata sidecars, are in `data/downloads/` and are downloadable from the site.

## Deploy

The site is hosted on **GitHub Pages** from the `main` branch, `/docs` folder,
at the custom domain `reprovsrarity.reefcode.org` (set via `docs/CNAME`). See
[DEPLOY.md](DEPLOY.md) for the full publish, DNS, and HTTPS steps and their
current status.

## License and attribution

This site accompanies a manuscript in review and bundles co-author data
(reproductive-mode classifications and octocoral surveys). Please cite the
manuscript above and contact the authors before reusing the data.
