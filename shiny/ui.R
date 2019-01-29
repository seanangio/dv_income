library(shiny)
library(shinythemes)

shinyUI(
    navbarPage(
        title = "Median Household Income in the Delaware Valley",
        theme = shinytheme("flatly"),
        tabPanel("Map",
            div(class = "outer",
                tags$head(
                    includeCSS("styles.css")
                ),
                
                leafletOutput("mymap", width = "100%", height = "100%"),
                
                absolutePanel(
                    id = "controls",
                    class = "panel panel-default",
                    fixed = TRUE, draggable = TRUE,
                    top = 48, left = "auto", right = 15,
                    bottom = "auto",
                    width = "25%", height = "auto",
                    uiOutput("rv_scope"),
                    hr(),
                    DT::DTOutput("table")
                )
            ),
            tags$div(id = "cite",
                     'Data downloaded via tidycensus by Sean Angiolillo (2019).'
            )
        ),
        tabPanel("About",
                 includeMarkdown("about.md"),
                 br()
        )
    )
)
