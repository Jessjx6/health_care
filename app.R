library(shiny)
library(shinythemes)
library(ggplot2)

data <- read.csv("data/drug_induced_deaths_1999-2015.csv", stringsAsFactors = FALSE)

source("overdose_map.R")
source("death_mapcode.R")

homepage <- tabPanel(
    "Overview",
    mainPanel(
        h3(class = "title", "Overview"),
        p("Our Shiny application was built in R Studio and contains 
        the major components used to create the variety of visualizations 
        used to help us answer our research questions."),
        p("To begin, we used a heat map to show the extent of heroin overdoses 
        in different states, with color to show the amount of people, frequency, 
        and age. This is particularly useful because it gives a visual aid as 
        to where and what groups of people are in most need of help."),
        p("Secondly, the next visualization we used was a bar chart. 
        This varied from the heat map because it highlights the various ages 
        of heroin users across the nation. Being able to change the view based 
        on specific age groups allows the user to see the true and unobscured data,
        whereas the heat map shows the depth and severity of the problem. "),
        p("Lastly, the other map that we used highlights the change in deaths from 
          2016 until now. This is useful because it highlights the severity and 
          growing issue that needs attention and changes to legislation. ")
        )
)

page_one <- tabPanel(
    "Numbers of Deaths",
    titlePanel("Deaths by Drugs in 1999-2015"),
    sidebarLayout(
        sidebarPanel(
            selectizeInput("?..State", 
                           label = "State:", 
                           choices = data$State)),
        
        mainPanel(
            plotOutput("trendPlot"))
    )
)

page_two <- tabPanel(
    "Opiod Overdoses by Age Group",
    titlePanel("Overdose Map"),
    sidebarLayout(
        sidebarPanel(
            radioButtons(inputId = "age", label = h3("Age Range"),
                         choices = list("Ages 0-24",
                                        "Ages 25-34",
                                        "Ages 35-44",
                                        "Ages 45-54",
                                        "Ages 55+",
                                        "Total"), 
                         selected = "Total")
        ),
        mainPanel(
            plotlyOutput("overdose_map")
        )
    )
)

page_three <- tabPanel(
    "Death Change Rate Map",
    titlePanel("Heroin-Related Overdose Deaths 2016-2017"),
    sidebarLayout(
        sidebarPanel(
        selectInput("category", "Category:",
                c("stable - not significant" = "stable - not significant",
                  "increase" = "increase",
                  "did not meet inclusion criteria" = "did not meet inclusion criteria",
                  "decrease" = "decrease")
                ),
        hr(),
        h5("This is a static text")
        ),
    mainPanel(
    leafletOutput("mymap"))
    )
)

page_four <- navbarMenu("More",
                        tabPanel("Q&A"),
                        tabPanel("Contact Us",
                        br(),
                        p("INFO 201 | Autumn 2019"),
                        hr(),
                        p("Adriane Phi, 
                          Christian Diangco, 
                          Jasmine Kennedy, 
                          Jiaxian Xiang", 
                          align = "center"),
                        p("Link to ", a(strong(code("INFO201-Final-Project")), 
                                        href = "https://github.com/Jessjx6/health_care"), 
                          align = "center")
                        )
)

ui <- navbarPage(
    theme = shinytheme("yeti"),
    "Drug Usage",
    homepage,
    page_two,
    page_one,
    page_three,
    page_four
)

server <- function(input, output) {
    output$trendPlot <- renderPlot({
        df <- data[data$ï..State == input$state, ]
        ggplot(data = data) +
            geom_point(mapping = aes(x = Year, y = Deaths))
    })
    
    
    output$overdose_map <- renderPlotly({
        plot_geo(data = overdose_age_groups) %>%
            add_trace(
                z = ~overdose_age_groups[[input$age]],
                locations = ~Location,
                locationmode = "USA-states",
                color = ~Total
            ) %>%
            colorbar(title = "Overdoses") %>%
            layout(
                geo = list(scope = "usa"),
                title = paste0("Opiod Overdoses in 2017 by State (", input$age, ")"),
                annotations = list(
                    text = "*White states do not have sufficient data for this age group",
                    x = 1.1,
                    y = -0.1,
                    showarrow = FALSE
                )
            )
    })
    
    output$mymap <- renderLeaflet({my_map <- leaflet(states) %>%
        setView(-100, 40, 4) %>%
        addProviderTiles("MapBox", options = providerTileOptions(
            id = "mapbox.light",
            accessToken = Sys.getenv('MAPBOX_ACCESS_TOKEN'))) %>%
        addPolygons(
            fillColor = ~pal(category), 
            weight = 2,
            opacity = 1,
            color = "white",
            dashArray = "3",
            fillOpacity = 0.7,
            highlight = highlightOptions(
                weight = 5,
                color = "#666",
                dashArray = "",
                fillOpacity = 0.7,
                bringToFront = TRUE),
            label = labels,
            labelOptions = labelOptions(
                style = list("font-weight" = "normal", padding = "3px 8px"),
                textsize = "15px",
                direction = "auto")) %>%
        addLegend(
            pal = pal,
            values = ~category, opacity = 0.7, title = NULL,
            position = "bottomright")})
    
    proxy <- leafletProxy("mymap")
    
    observe({
        if(input$category != ""){
            selected_polygon <- subset(states, states$category==input$category)
            proxy %>% clearGroup("highlighted_polygon")
            proxy %>% addPolylines(stroke=TRUE, weight = 4, color="red",
                                   data=selected_polygon, group="highlighted_polygon")
        }
    })
}


# Run the application 
shinyApp(ui = ui, server = server)