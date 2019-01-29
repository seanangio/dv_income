### Objectives

This simple app was designed to demonstrate how to manipulate a `leaflet` map via the zoom control. I achieved this affect through a combination of observers, a reactive values list, and `renderUI()`. 

* Observers on both the scope input and the map id's zoom level allow you to trigger events when either event happens.

* Re-establish `input$scope` as a variable within a reactive values list (`rv$scope`). Assign `rv$scope` to a new value whether that change comes from the user directly changing the input through the radio buttons or by adjusting the zoom level to a particular range.

* Lastly, use `renderUI()` to dynamically render the radio group button with `rv$scope` as the selected option. Without this, in cases where the scope has changed due to the zoom control, the scope level and the value displayed in the radio button will not match.

### The Data

The data comes from the American Community Survey (ACS) via the `tidycensus` package. It represents 2012-2016 Median Household Income. As the data come from a survey, do note that the data represent estimates that have an associated margin of error. If we were interested in the data itself, the level of uncertainty is not satisfactorily visualized.

### Further Information

The R scripts wrangling the data and creating the visualisation can be found on <a href="https://github.com/seanangio/dv_income/" target="_blank">Github</a>.

Other data projects by the author can be found at his <a href="https://sean.rbind.io/" target="_blank">web site.</a>

