library(shiny)
library(shinyWidgets)
library(DT)

# Define server logic required to draw a histogram
shinyServer(function(input, output, session) {
    session$onSessionEnded(stopApp)
    
    output$mymap <- renderLeaflet({
        draw_base_map()
    })
    
    # can't overwrite input$scope with zoom
    # so place scope in a reactiveValues list
    rv <- reactiveValues(scope = "state")
    
    # scope variable changes in 2 possible ways
    # 1. rv$scope changes from user change
    observeEvent(input$scope, {
        rv$scope <- input$scope
    })
    
    # 2. rv$scope changes from zoom out of range
    observeEvent(input$mymap_zoom, {
        rv$scope <- check_zoom(input$mymap_zoom)
    })
    
    my_sf <- reactive({
        dv_data %>% 
            filter(scope == rv$scope)
    })
    
    my_df <- reactive({
        my_sf() %>% 
            st_set_geometry(NULL)
    })
    
    sum_df <- reactive({
        sum_data %>% 
            filter(scope == rv$scope)
    })
    
    view <- reactive({
        get_view(rv$scope)
    })
    
    # shapes should update only when scope changes; 
    # not my_sf() or view() to avoid double render
    observeEvent(rv$scope, { 
        update_shapes("mymap", my_sf(), view())
    })
    
    observeEvent(my_df(), {
        draw_map_legend("mymap", my_df())
    })
    
    # zoom can change rv$scope, which no longer matches input$scope
    # use renderUI() to display rv$scope as selected input
    output$rv_scope <- renderUI({
        radioGroupButtons("scope", em(h4(HTML("Set geographic scope manually or</br> zoom to see change automatically"))),
                          choices = list("State" = "state",
                                         "County" = "county",
                                         "Census Tract" = "tract"),
                          selected = rv$scope)
    })
    
    output$table <- renderDT({
        DT::datatable(
            draw_table(sum_df()),
            rownames = FALSE, colnames = c("",""), filter = "none",
            style = "bootstrap",
            options = list(
               dom = 'b', ordering = FALSE
            )
        )
    })
  
})
