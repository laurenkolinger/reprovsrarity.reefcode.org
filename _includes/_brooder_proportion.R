# Brooder proportion of total coral cover over time, per program.
# Self-contained port of the manuscript's 06_additional_stats (chunks compute-cover / compute-ratio),
# retargeted at this repo's own data. Uses ALL scleractinian taxa (NO baseline-presence filter),
# joins reproductive mode, then per site-year: (1) averages perccover across transects within a
# taxon, (2) sums cover across taxa within each reproductive mode, (3) averages across sites per
# program-year -> `cover_all`. `ratio` adds prop_brooder = Brooder/(Brooder+Broadcaster).
# Species-level data drives TCRMP and VINPS; genus-level data drives CSUN (with the four genera
# 06 hardcodes: Helioseris/Isophyllia/Scolymia = Brooder, Solenastrea = Broadcaster).
#
# Validated to reproduce the manuscript's published numbers exactly:
#   TCRMP baseline (2001) = 25.84 ; VINPS (2001) = 12.50 ; CSUN (1992) = 7.35
#   2021:2023 across programs: min = 29.13 (CSUN 2021), max = 43.12 (TCRMP 2022)

suppressWarnings(suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
}))

compute_brooder_series <- function(repo_root) {
  p <- function(...) file.path(repo_root, ...)

  raw_spp <- utils::read.csv(p("data", "cover", "s2pt5_benthicCoverCoralSpecies_41sites_1999_2024.csv"),
                             stringsAsFactors = FALSE)
  raw_gen <- utils::read.csv(p("data", "cover", "s2pt4_benthicCoverCoralGenera_49sites_1987_2024.csv"),
                             stringsAsFactors = FALSE)
  sitedat <- utils::read.csv(p("data", "site", "00_RRS_siteMaster_allSites_data.csv"),
                             stringsAsFactors = FALSE)

  repro_m <- utils::read.csv(p("data", "collab", "reproMode_coralSpecies_Mahoney_20250108.csv"),
                             stringsAsFactors = FALSE) %>% rename(coralSpecies = Species)
  repro_o <- utils::read.csv(p("data", "collab", "reproMode_coralSpecies_Olinger_20250108.csv"),
                             stringsAsFactors = FALSE) %>% select(coralSpecies, Reproductive_mode)
  repro <- bind_rows(repro_m %>% select(coralSpecies, Reproductive_mode), repro_o) %>%
    filter(Reproductive_mode != "UNK") %>% distinct(coralSpecies, .keep_all = TRUE)

  gen_edmunds <- utils::read.csv(p("data", "collab", "reproMode_coralGenera_commonRare_Edmunds.csv"),
                                 stringsAsFactors = FALSE) %>%
    rename(coralGenera = Genus, Reproductive_mode = LH.Strategy) %>%
    mutate(coralGenera = ifelse(coralGenera == "Montastrea cav", "Montastraea", coralGenera)) %>%
    filter(Reproductive_mode %in% c("Brooder", "Broadcaster")) %>%
    distinct(coralGenera, .keep_all = TRUE)

  make_year_group <- function(df, year_interval) {
    min_yr <- min(df$year, na.rm = TRUE); max_yr <- max(df$year, na.rm = TRUE)
    breaks <- seq(min_yr, max_yr, by = year_interval)
    if (length(breaks) > 1 && utils::tail(breaks, 1) > max_yr - (year_interval / 2))
      breaks <- utils::head(breaks, -1)
    labs <- paste(breaks, pmin(breaks + (year_interval - 1), max_yr), sep = "-")
    ymap <- data.frame(year = seq(min_yr, max_yr, by = 1))
    ymap$year_group <- cut(ymap$year, breaks = c(breaks, max_yr + 1), labels = labs,
                           right = FALSE, include.lowest = TRUE)
    df %>% left_join(ymap, by = "year") %>% mutate(year_group = as.factor(year_group))
  }

  csun_sites_all <- sitedat %>% filter(program == "CSUN", yearadded < 2025) %>%
    mutate(depth_cat = ifelse(depth < 21, "Shallow", "Deep"))
  csun_bl <- raw_gen %>% filter(program == "CSUN", year > 1991) %>%
    mutate(coralGenera = ifelse(coralGenera == "Isopyhyllastrea", "Isophyllastrea", coralGenera))
  csun_bl <- make_year_group(csun_bl, 5)
  earliest_group <- levels(csun_bl$year_group)[1]
  csun_bl <- csun_bl %>% filter(site %in% csun_sites_all$site) %>%
    left_join(select(csun_sites_all, site, depth_cat), by = "site") %>% filter(depth_cat == "Shallow")
  genera_in_early <- csun_bl %>% group_by(coralGenera, year_group) %>%
    summarise(mx = max(perccover, na.rm = TRUE), .groups = "drop") %>%
    filter(mx > 0, year_group == earliest_group) %>% pull(coralGenera) %>% unique()
  genera_baseline <- csun_bl %>% filter(coralGenera %in% genera_in_early) %>%
    group_by(year_group, coralGenera, year, site) %>%
    summarise(perccover = mean(perccover, na.rm = TRUE), .groups = "drop") %>%
    filter(year_group == earliest_group) %>% group_by(coralGenera) %>%
    summarise(meancov = mean(perccover, na.rm = TRUE), .groups = "drop") %>% filter(meancov > 0) %>%
    left_join(gen_edmunds %>% select(coralGenera, Reproductive_mode), by = "coralGenera") %>%
    filter(!is.na(Reproductive_mode), Reproductive_mode %in% c("Brooder", "Broadcaster"))
  gen_repro <- bind_rows(
    genera_baseline %>% select(coralGenera, Reproductive_mode),
    data.frame(coralGenera = c("Helioseris", "Isophyllia", "Scolymia", "Solenastrea"),
               Reproductive_mode = c("Brooder", "Brooder", "Brooder", "Broadcaster"),
               stringsAsFactors = FALSE)
  ) %>% distinct(coralGenera, .keep_all = TRUE)

  agg <- function(bc, taxon_col) {
    bc %>%
      group_by(year, site, .data[[taxon_col]], Reproductive_mode) %>%
      summarise(mean_cover = mean(perccover, na.rm = TRUE), .groups = "drop") %>%
      group_by(year, site, Reproductive_mode) %>%
      summarise(total_cover = sum(mean_cover, na.rm = TRUE), .groups = "drop") %>%
      group_by(year, Reproductive_mode) %>%
      summarise(mean_cover = mean(total_cover, na.rm = TRUE), .groups = "drop")
  }

  drop_species <- c("Millepora alcicornis", "Millepora complanata", "Millepora squarrosa",
                    "Coral spp.", "Branching Porites spp.", "Juvenile coral spp.",
                    "Orbicella species complex")
  results <- list()
  for (prog in c("TCRMP", "VINPS")) {
    sd <- sitedat %>% filter(program == prog, yearadded < 2006, depth < 21)
    bc <- raw_spp %>% filter(program == prog, year > 2000)
    if (prog == "TCRMP") bc <- bc %>% filter(period == "Annual")
    bc <- bc %>%
      mutate(coralSpecies = ifelse(coralSpecies == "Orbicella franksii", "Orbicella franksi", coralSpecies)) %>%
      filter(!coralSpecies %in% drop_species, !grepl(" spp\\.$", coralSpecies), site %in% sd$site) %>%
      inner_join(repro, by = "coralSpecies")
    results[[prog]] <- agg(bc, "coralSpecies") %>% mutate(program = prog)
  }
  sd <- sitedat %>% filter(program == "CSUN", yearadded < 2006, depth < 21)
  bc <- raw_gen %>% filter(program == "CSUN", year > 1991, site %in% sd$site) %>%
    mutate(coralGenera = ifelse(coralGenera == "Isopyhyllastrea", "Isophyllastrea", coralGenera)) %>%
    inner_join(gen_repro, by = "coralGenera")
  results[["CSUN"]] <- agg(bc, "coralGenera") %>% mutate(program = "CSUN")

  cover_all <- bind_rows(results) %>% select(program, year, Reproductive_mode, mean_cover) %>%
    arrange(program, year, Reproductive_mode)
  ratio <- cover_all %>%
    pivot_wider(names_from = Reproductive_mode, values_from = mean_cover) %>%
    mutate(prop_brooder = Brooder / (Brooder + Broadcaster)) %>%
    select(program, year, prop_brooder) %>% arrange(program, year)
  list(cover_all = as.data.frame(cover_all), ratio = as.data.frame(ratio))
}
