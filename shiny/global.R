library(leaflet)
library(leaflet.extras)
library(sf)
library(dplyr)
library(ggplot2)
library(scales)

# Load data ---------------------------------------------------------------

dv_data <- readRDS("dv_data.rds") %>% 
    select(-c("area_m2"))

sum_data <- readRDS("sum_data.rds") %>% 
    mutate(
        med_area_km2 = round(med_area_km2, digits = 2),
        med_area_km2 = prettyNum(med_area_km2, big.mark = ",")
    )

centers <- readRDS("centers.rds")


# Leaflet functions -------------------------------------------------------

pal <- colorNumeric(palette = "viridis", domain = NULL) 

draw_base_map <- function() {
    
    leaflet(
        options = leafletOptions(minZoom = 7, maxZoom = 14)
    ) %>% 
        addProviderTiles("CartoDB.Positron") %>% 
        addResetMapButton()
}

update_shapes <- function(mymap, my_data, view) {
    
    leafletProxy(mymap, data = my_data) %>% 
        clearShapes() %>%
        setView(lng = view$lng, lat = view$lat, zoom = view$zoom) %>% 
        addPolygons(
            stroke = TRUE,
            weight = 1,
            opacity = 1,
            color = "white",
            fillOpacity = 0.6,
            fillColor = ~ pal(hhincome),
            label = ~ lapply(tooltip, HTML),
            layer = ~ leaf_label,
            highlight = highlightOptions(
                weight = 3,
                fillOpacity = 0.8,
                color = "#666",
                bringToFront = FALSE)
        )
}

draw_map_legend <- function(mymap, df) {
    leafletProxy(mymap, data = df) %>%
        clearControls() %>%
        addLegend(
            "bottomleft",
            pal = pal, 
            values = ~ hhincome / 1000,
            title = ~ "Median</br>HHI ($k)",
            opacity = 1
        )
}


# Functions around zoom/view ----------------------------------------------

get_view <- function(x) {
    
    view <- list()
    
    view$zoom <- centers %>% 
        filter(scope == x) %>% 
        pull(zoom)
    
    view$lng <- centers %>% 
        filter(scope == x) %>% 
        pull(lng)
    
    view$lat <- centers %>% 
        filter(scope == x) %>% 
        pull(lat)
    
    view
}

# take existing zoom level; check its range and determine rv$scope
check_zoom <- function(zoom) {

    case_when(
        zoom <= 7 ~ "state",
        zoom <= 9 ~ "county",
        TRUE ~ "tract"
    )

}


# Output table ------------------------------------------------------------

draw_table <- function(df) {
    
    tribble(
        ~colA, ~colB,
        "Num. Observations", df$n,
        "Median HH Income", scales::dollar(df$med_hhi),
        "Median Margin of Error", scales::dollar(df$med_moe),
        "Median Area (sq km)", df$med_area_km2
        
    )    
}