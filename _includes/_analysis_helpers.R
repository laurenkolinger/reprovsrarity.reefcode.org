# Shared helpers for the analysis includes and the manuscript-values page.
# Sourced by each _analysis_*.qmd (from a page directory) and by qmd/07_manuscript_values.qmd.
# Two jobs: (1) the per-taxon descriptive change-metrics table (occupancy / extent / cover /
# rank, start vs end), mirroring the manuscript's all_species_change_metrics; (2) timestamped
# RData saving/loading per program and version, mirroring the manuscript's helpers.R.

# ---------------------------------------------------------------------------------------------
# Repo-root resolution: works whether the working directory is a page dir (qmd/aspublished,
# qmd/updated) or the qmd/ dir (the values page) or the repo root. Walks up to the _quarto.yml.
find_repo_root <- function(start = getwd()) {
  d <- normalizePath(start, mustWork = FALSE)
  while (!file.exists(file.path(d, "_quarto.yml")) && dirname(d) != d) d <- dirname(d)
  d
}
rdata_dir <- function() file.path(find_repo_root(), "data", "rdata")

# ---------------------------------------------------------------------------------------------
# compute_change_metrics(): per-taxon start/end descriptive stats from objects already in scope
# after the model is built. PURELY additive: reads the site-level `benthiccover` (post transect
# averaging, before the group averaging), the `baseline` classification, the scoped `sitedat`,
# and `earliest_year_group`. Returns one row per baseline taxon.
#
#   - Start period = the baseline five-year group (earliest_year_group), e.g. 2001-2005.
#   - End period   = the last three program years, derived as max(year)-2 : max(year).
#   - Occupancy(taxon, year) = proportion of ACTIVE sites (yearadded <= year) where the taxon was
#     present (cover > 0); years with no active site are dropped (matches the manuscript's
#     year >= yearadded filter over the zero-filled site grid). Start/End = mean over the period.
#   - Extent(taxon) = mean cover across present (cover > 0) site-years within the period.
#   - Start cover = baseline mean cover (meancov). End cover = zero-filled mean cover across
#     active sites over the end years. Ranks: start = baseline rank; end = rank of end cover.
compute_change_metrics <- function(benthiccover, baseline, sitedat, earliest_year_group, taxon_col) {
  bc   <- benthiccover
  base <- baseline
  eyg  <- earliest_year_group
  start_years <- as.integer(sub("-.*", "", eyg)):as.integer(sub(".*-", "", eyg))
  maxyr <- max(bc$year, na.rm = TRUE)
  end_years <- (maxyr - 2):maxyr
  data_years <- sort(unique(bc$year))
  taxa <- base[[taxon_col]]
  scoped_sites <- sort(unique(bc$site))
  ya <- stats::setNames(sitedat$yearadded, sitedat$site)

  occ_period <- function(years) {
    yrs <- intersect(years, data_years)
    vapply(taxa, function(tx) {
      props <- vapply(yrs, function(y) {
        active <- scoped_sites[!is.na(ya[scoped_sites]) & ya[scoped_sites] <= y]
        if (length(active) == 0) return(NA_real_)
        present <- unique(bc$site[bc[[taxon_col]] == tx & bc$year == y & bc$perccover > 0 &
                                  !is.na(ya[bc$site]) & ya[bc$site] <= y])
        length(intersect(present, active)) / length(active)
      }, numeric(1))
      mean(props, na.rm = TRUE)
    }, numeric(1))
  }
  ext_period <- function(years) {
    d <- bc[bc$year %in% years & bc$perccover > 0, ]
    v <- tapply(d$perccover, d[[taxon_col]], mean)
    as.numeric(v[taxa])
  }
  cover_end_period <- function(years) {
    yrs <- intersect(years, data_years)
    vapply(taxa, function(tx) {
      vals <- vapply(yrs, function(y) {
        active <- scoped_sites[!is.na(ya[scoped_sites]) & ya[scoped_sites] <= y]
        if (length(active) == 0) return(NA_real_)
        d <- bc[bc[[taxon_col]] == tx & bc$year == y & bc$perccover > 0 &
                !is.na(ya[bc$site]) & ya[bc$site] <= y, ]
        sum(d$perccover) / length(active)   # zero-filled mean cover across active sites
      }, numeric(1))
      mean(vals, na.rm = TRUE)
    }, numeric(1))
  }

  occ_s <- occ_period(start_years) * 100
  occ_e <- occ_period(end_years) * 100
  ext_s <- ext_period(start_years)
  ext_e <- ext_period(end_years)
  cover_end <- cover_end_period(end_years)
  end_rank <- rep(NA_integer_, length(taxa))
  ok <- !is.na(cover_end) & cover_end > 0
  end_rank[ok] <- rank(-cover_end[ok], ties.method = "first")

  data.frame(
    taxon       = taxa,
    mode        = as.character(base$Reproductive_mode),
    commonness  = as.character(base$commonness),
    rank_start  = base$rank,
    rank_end    = end_rank,
    cover_start = base$meancov,
    cover_end   = cover_end,
    occ_start   = occ_s,
    occ_end     = occ_e,
    ext_start   = ext_s,
    ext_end     = ext_e,
    stringsAsFactors = FALSE
  )
}

# ---------------------------------------------------------------------------------------------
# Timestamped RData saving/loading (mirrors the manuscript's make_timestamp/save_timestamped/
# load_latest). Files: data/rdata/<program>_<version>_<YYYY-MM-DD_HHMMSS>.RData. The program and
# version live in the filename so the aspublished and updated runs never overwrite each other.
make_timestamp <- function() format(Sys.time(), "%Y-%m-%d_%H%M%S")

rdata_prefix <- function(program, version) paste(tolower(program), version, sep = "_")

# Save a NAMED LIST of objects (deterministic: names come from the list, not from `...`).
save_program_rdata <- function(program, version, objects,
                               dir = rdata_dir(), timestamp = make_timestamp()) {
  if (!dir.exists(dir)) dir.create(dir, recursive = TRUE)
  f <- file.path(dir, sprintf("%s_%s.RData", rdata_prefix(program, version), timestamp))
  e <- list2env(objects, parent = emptyenv())
  save(list = names(objects), envir = e, file = f)
  invisible(f)
}

# Newest <prefix>_<timestamp>.RData (lexicographic == chronological for this stamp format).
latest_rdata <- function(prefix, dir = rdata_dir()) {
  pat <- sprintf("^%s_\\d{4}-\\d{2}-\\d{2}_\\d{6}\\.RData$", prefix)
  files <- list.files(dir, pattern = pat, full.names = TRUE)
  if (length(files) == 0L)
    stop("no RData for prefix '", prefix, "' in ", dir, call. = FALSE)
  tail(sort(files), 1L)
}

# Load the newest RData for a program+version into a fresh environment and return it.
load_latest_program <- function(program, version, dir = rdata_dir()) {
  e <- new.env(parent = emptyenv())
  load(latest_rdata(rdata_prefix(program, version), dir), envir = e)
  e
}
