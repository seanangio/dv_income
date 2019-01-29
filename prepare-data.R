library(tigris)
library(sf)
library(tidycensus)
library(tidyverse)
library(rvest)
library(units)
options(tigris_class = "sf")
options(tigris_use_cache = TRUE)

api_key <- "YOUR_API_KEY"
census_api_key(api_key)
# Check your API key
Sys.getenv("CENSUS_API_KEY")

# Get state-level sf’s from tidycensus ------------------------------------

dv <- c("PA", "NJ", "DE", "MD")
dv_states <- map(dv, function(x) {
    get_acs(geography = "state", state = x, 
            variables = c(hhincome = "B19013_001"), 
            geometry = TRUE)
}) %>% 
    do.call(rbind, .)

# confirm correct
ggplot(dv_states) + 
    geom_sf(aes(fill = estimate)) +
    coord_sf(datum = NA) +
    scale_fill_viridis_c(labels = scales::dollar) +
    theme_void()

# Get county-level sf's ---------------------------------------------------

url <- "https://en.wikipedia.org/wiki/Delaware_Valley"
counties <- read_html(url) %>%
    html_nodes("td") %>%
    html_text %>%
    str_trim %>% 
    .[17:160] %>% 
    matrix(ncol = 9, byrow = TRUE) %>%
    as_tibble() %>% 
    select(1:2) %>%
    rename(county = "V1", state = "V2")
saveRDS(counties, "counties.rds")

my_counties <- readRDS("counties.rds")

dv_counties <- map2(my_counties$state, my_counties$county, function(x, y) {
    get_acs(geography = "county", state = x, county = y,
            variables = c(hhincome = "B19013_001"), 
            geometry = TRUE)
}) %>% 
    do.call(rbind, .)

# confirm correct
ggplot(dv_counties) + 
    geom_sf(aes(fill = estimate)) +
    coord_sf(datum = NA) +
    scale_fill_viridis_c(labels = scales::dollar) +
    theme_void()


# Get census-tract level sf's ---------------------------------------------

phl_tracts <- get_acs(geography = "tract", 
                      state = "PA", 
                      county = "Philadelphia",
                      variables = c(hhincome = "B19013_001"), 
                      geometry = TRUE)

# confirm correct
ggplot(phl_tracts) + 
    geom_sf(aes(fill = estimate)) +
    coord_sf(datum = NA) +
    scale_fill_viridis_c(labels = scales::dollar) +
    theme_void()


# Combine state, county, tract level sf's ---------------------------------

my_data <- rbind(dv_states, dv_counties, phl_tracts) %>% 
    mutate(
        scope = case_when(
        str_length(GEOID) == 2 ~ "state",
        str_length(GEOID) == 5 ~ "county",
        TRUE ~ "tract"
        ),
        leaf_label = word(NAME, sep = ","),
        tooltip = str_c("<b>", leaf_label, "</b>",
                        "<br> Median Household Income: ", scales::dollar(estimate),
                        "<br> Margin of Error: ", scales::dollar(moe),
                        "</span></div>"),
        axis_label = case_when(
            NAME == "Pennsylvania" ~ "PA",
            NAME == "New Jersey" ~ "NJ",
            NAME == "Delaware" ~ "DE",
            NAME == "Maryland" ~ "MD",
            scope == "county" ~ word(NAME, sep = " County"),
            TRUE ~ word(leaf_label, start = -1, sep = "Census Tract ")
        ),
        area_m2 = st_area(.),
        area_km2 = set_units(area_m2, km^2)
    ) %>%
    rename(hhincome = estimate) %>% 
    select(-variable) %>% 
    st_transform(crs = 4326) #https://github.com/r-spatial/mapview/issues/72

saveRDS(my_data, "shiny/dv_data.rds")


# Calculate summary stats per scope ---------------------------------------

my_data <- readRDS("shiny/dv_data.rds")

sum_data <- my_data %>% 
    st_set_geometry(NULL) %>% 
    group_by(scope) %>% 
    summarise(
        n = n(),
        med_hhi = median(hhincome, na.rm = TRUE),
        med_moe = median(moe, na.rm = TRUE),
        med_area_km2 = median(area_km2, na.rm = TRUE)
    )

saveRDS(sum_data, "shiny/sum_data.rds")


# Calculate centroids for each scope --------------------------------------

get_center <- function(sf) {
    sf %>% 
        st_union() %>% 
        st_transform(crs = 2272) %>%
        st_centroid() %>% 
        st_transform(crs = 4326) %>% 
        st_coordinates() %>% 
        as_tibble() %>% 
        rename(lng = X, lat = Y)
}

centers <- purrr::map_dfr(
    list(dv_states, dv_counties, phl_tracts), 
    get_center) %>%
    mutate(
        scope = c("state", "county", "tract"),
        lng = case_when(
            scope == "state" ~ lng + 1,
            scope == "county" ~ lng + 0.5,
            TRUE ~ lng + 0.1
        ),
        zoom = c(7, 8, 11)
    )

saveRDS(centers, "shiny/centers.rds")

