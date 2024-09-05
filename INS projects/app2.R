# Charger les packages
library(shiny)
library(shinydashboard)
library(ggplot2)
library(plotly)
library(dplyr)
library(haven)  # Pour lire les fichiers .dta

# Charger les données
data <- read_dta("C:\\Users\\DELL\\Desktop\\carto.dta", encoding = "latin1")

# Interface utilisateur
ui <- dashboardPage(
  dashboardHeader(title = "INS 2024 Dashboard"),
  dashboardSidebar(
    dateRangeInput("dateRange", "Date range:", start = "2024-07-20", end = Sys.Date()),
    selectInput("region", "Region:", choices = unique(data$fd01))
  ),
  dashboardBody(
    fluidRow(
      valueBoxOutput("completeInterviews"),
      valueBoxOutput("submittedInterviews"),
      valueBoxOutput("daysOfCollection"),
      valueBoxOutput("responseRate"),
      valueBoxOutput("refusalRate")
    ),
    fluidRow(
      box(plotOutput("totalSampleCompletion"), width = 12)
    ),
    fluidRow(
      box(plotOutput("interviewsPerDay"), width = 6),
      box(plotOutput("interviewedHouseholds"), width = 6)
    )
  )
)

# Serveur
server <- function(input, output) {
  
  # Filtrer les données en fonction des sélections utilisateur
  filteredData <- reactive({
    data %>%
      filter(date >= input$dateRange[1], date <= input$dateRange[2]) %>%
      filter(region == input$fd01)
  })
  
  # Calcul des valeurs pour les box
  output$completeInterviews <- renderValueBox({
    valueBox(value = nrow(filteredData()), subtitle = "Complete Interviews", icon = icon("check"), color = "blue")
  })
  
  output$submittedInterviews <- renderValueBox({
    valueBox(value = sum(filteredData()$submitted), subtitle = "Submitted Interviews", icon = icon("upload"), color = "green")
  })
  
  output$daysOfCollection <- renderValueBox({
    valueBox(value = as.numeric(difftime(max(filteredData()$date), min(filteredData()$date), units = "days")), subtitle = "Days since start of data collection", icon = icon("calendar"), color = "yellow")
  })
  
  output$responseRate <- renderValueBox({
    response_rate <- sum(filteredData()$responded) / nrow(filteredData()) * 100
    valueBox(value = paste0(round(response_rate, 1), "%"), subtitle = "Response Rate", icon = icon("thumbs-up"), color = "purple")
  })
  
  output$refusalRate <- renderValueBox({
    refusal_rate <- sum(filteredData()$refused) / nrow(filteredData()) * 100
    valueBox(value = paste0(round(refusal_rate, 1), "%"), subtitle = "Refusal Rate", icon = icon("thumbs-down"), color = "red")
  })
  
  # Graphiques
  output$totalSampleCompletion <- renderPlot({
    ggplot(data = filteredData(), aes(x = total_sample_completion, y = percentage_completion)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      labs(title = "Total sample completion", x = "Count", y = "Percentage")
  })
  
  output$interviewsPerDay <- renderPlot({
    data_by_day <- filteredData() %>% group_by(date) %>% summarise(interviews = n())
    ggplot(data_by_day, aes(x = date, y = interviews)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      labs(title = "Number of interviews per day", x = "Day", y = "Interviews")
  })
  
  output$interviewedHouseholds <- renderPlot({
    data_by_region <- filteredData() %>% group_by(region) %>% summarise(count = n())
    ggplot(data_by_region, aes(x = region, y = count)) +
      geom_bar(stat = "identity", fill = "steelblue") +
      labs(title = "Interviewed households", x = "Region", y = "Households")
  })
}

