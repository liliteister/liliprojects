
# This is a Shiny App I built to learn how to build Shiny Apps.
# It uses the USArrests dataset

library(shiny)
library(ggplot2)
library(reshape2)
library(dplyr)
library(shinythemes)

# grab and shape the data for analysis
data("USArrests")

states <- as.list(row.names(USArrests))
names(states) <- row.names(USArrests)
states <- append(states, list(`All States`="All States"), after = 0)

USArrests$State <- row.names(USArrests)
USArrests_long <- melt(USArrests) %>%
  mutate(variable = as.character(variable))

#
ui <- fluidPage(theme = shinytheme("yeti"),
  
  titlePanel("Arrests data by US State"),
  hr(),
  br(),
  
  sidebarLayout(
    
    sidebarPanel(
      selectInput("stateselect", label = h5("Select a state, or choose to compare all states:"), 
                  choices = states, 
                  selected = 1),
      
      conditionalPanel(
        condition = "input.stateselect == 'All States'",
        selectInput("measureselect", label = h5("Select a measure to compare all states on:"),
                    choices = list("Murder", "Assault", "UrbanPop", "Rape"))
      )
    ),
    
    mainPanel(
      tabsetPanel(
        tabPanel("Charts",
                 plotOutput("stateplot")),
        tabPanel("Table",
                 DT::dataTableOutput("statetable")),
        tabPanel("Dataset Info",
                 tags$blockquote(paste("This data set contains statistics, in arrests per 100,000 residents for assault, murder, and rape in each of the 50 US states in 1973. Also given is the percent of the population living in urban areas.",
                       "World Almanac and Book of facts 1975. (Crime rates).")
                 )
        )
      )
      
    )
  )
)
  

#
server <- function(input, output, session){
  
  output$stateplot <- renderPlot({
    
    if(input$stateselect != "All States"){
      ggplot(data = USArrests_long[USArrests_long$State == input$stateselect,],
             aes(x=variable, y=value, fill=variable)) +
        geom_bar(stat="identity") +
        labs(title = paste("Violent Crime Rates in", input$stateselect),
             x = "Crime Type", y= "Rate per 100,000 residents") +
        theme(plot.title = element_text(size=14, face="bold"),
              legend.position = "none")
      
    } else if(input$stateselect == "All States"){
      ggplot(data = USArrests_long[USArrests_long$variable == input$measureselect,],
             aes(x=State, y=value, fill = "blue")) +
        geom_bar(stat="identity") +
        labs(title = paste(input$measureselect, "Rates by State"),
             x = "State", y="Rate per 100,000 residents") +
        theme(plot.title = element_text(size=14, face="bold"),
              legend.position = "none",
              axis.text.x = element_text(angle=90)
              )
    }
  
  })
  
  output$statetable <- DT::renderDataTable(USArrests,
                                           filter = "top")
  
}

#
shinyApp(ui = ui, server = server)