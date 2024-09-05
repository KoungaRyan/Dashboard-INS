
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(haven)
library(plotly)
library(leaflet)
library(sf)
library(sp)
library(raster)

# Charger les données
#data <- read_dta("..\\data\\carto.dta")
#data$FD09[is.na(data$FD09)] <- 2
#data <- as_factor(data)

data <- merge(record1, record2, by = les_id$VarN, all.record1 = TRUE)

# Définir la plage de dates
install.packages("lubridate")
library(lubridate)
date_debut <- ymd("2024-05-01")
date_fin <- ymd("2024-08-30")
dates_seq <- seq(date_debut, date_fin, by = "day")

# Générer des dates aléatoires et les ajouter au data frame
indices_aleatoires <- sample(1:length(dates_seq), nrow(data), replace = TRUE)
data$date <- dates_seq[indices_aleatoires]


data_evolution <- data %>%
  group_by(FD01, date) %>%
  summarise(nombre_menages = n()) %>%
  arrange(FD01, date) %>%
  mutate(Cumul = cumsum(nombre_menages))


# Interface utilisateur
ui <- dashboardPage(
  dashboardHeader(title = "Tableau de bord des enquêtes 2024"),
  dashboardSidebar(
    dateRangeInput("dateRange", "Date range:", start = "2024-07-20", end = Sys.Date()),
    selectInput("region", "Région:", choices = unique(data$FD01)),
    selectInput("Grappe", "Grappe:", choices = unique(data$FD07))
  ),
  dashboardBody(
    fluidRow(
      valueBoxOutput("totalEnquetes"),
      valueBoxOutput("enquetesCompletes"),
      valueBoxOutput("tauxRefus")
    ),
    fluidRow(
      box(leafletOutput("carteRecensement"), width = 12)
    ),
    fluidRow(
      box(plotlyOutput("distributionRegions"), width = 6),
      box(plotlyOutput("distributionEquipes"), width = 6)
    ),
    fluidRow(
      box(plotlyOutput("progressionEnquetes"), width = 6),
      box(plotOutput("pieChartReponses"), width = 6)
    )
  )
)

# Serveur
server <- function(input, output) {

  # Filtrer les données selon les choix de l'utilisateur
  filteredData <- reactive({
    data %>%
      filter(FD01 == input$region, FD07 == input$Grappe)
  })

  # Calcul des statistiques pour les ValueBoxes
  output$totalEnquetes <- renderValueBox({
    valueBox(value = nrow(data), subtitle = "Total des enquêtes", icon = icon("list"), color = "blue")
  })

  output$enquetesCompletes <- renderValueBox({
    enquetes_completes <- sum(data$FD09 == "Oui, complètement")/ nrow(data) * 100
    valueBox(value = paste0(round(enquetes_completes, 2), "%"), subtitle = "Taux Enquêtes complètées", icon = icon("check"), color = "green")
  })

  output$tauxRefus <- renderValueBox({
    taux_refus <- sum(data$FD09 == "Oui, partielelment") / nrow(data) * 100
    valueBox(value = paste0(round(taux_refus, 2), "%"), subtitle = "Taux Enquêtes en cours", icon = icon("hourglass-half"), color = "yellow")
  })

  # Carte interactive de recensement
  output$carteRecensement <- renderLeaflet({
    data_unique <- data %>%
      distinct(S07a, S07b, .keep_all = TRUE)

    # Remplacer les NaN dans FD09 par 2 sans affecter les labels
    data_unique$FD09[is.na(data_unique$FD09)] <- 2

    pal <- colorFactor(
      palette = c("green", "orange", "red"),   # Ajoutez des couleurs pour tous les labels
      levels = c("Oui, complètement", "Oui, partiellement", "Non")  # Assurez-vous que les niveaux couvrent tous les labels dans FD09
    )

    # Créer la carte interactive
    leaflet(data_unique) %>%
      addTiles() %>%
      addCircleMarkers(
        ~S07a, ~S07b,
        color = ~pal(as_factor(FD09)), # Utilisation des niveaux numériques pour la couleur
        radius = 5,
        stroke = FALSE, fillOpacity = 0.8,
        label = ~paste0("Région: ", FD01, "<br>",
                        "Département: ", FD02, "<br>",
                        "Arrondissement: ", FD03, "<br>",
                        "Statut du recensement: ", as_factor(FD09)) # Les labels seront affichés correctement
      ) %>%
      addLegend(
        "bottomright",
        pal = pal,
        values = ~as_factor(FD09),
        title = "Statut du Recensement",
        opacity = 1
      )
  })

  # Distribution des réponses par région
  output$distributionRegions <- renderPlotly({
    ggplot(data, aes(x = FD01, fill = FD09)) +
      geom_bar() +
      scale_fill_manual(values = c("green", "orange")) +
      labs(title = "Distribution des réponses par région", x = "Région", y = "Nombre d'enquêtes") +
      theme_minimal()
  })

  # Distribution des réponses par équipe
  output$distributionEquipes <- renderPlotly({
    ggplot(data, aes(x = FD07, fill = FD09)) +
      geom_bar() +
      scale_fill_manual(values = c("green", "orange")) +  # Remplacez par les couleurs de votre choix
      labs(title = "Distribution des réponses par Grappe", x = "Grappe", y = "Nombre d'enquêtes") +
      theme_minimal()
  })


  # Progression des enquêtes au fil du temps
  output$progressionEnquetes <- renderPlotly({
    ggplot(data_evolution, aes(x = date, y = Cumul, color = FD01, group = FD01)) +
      geom_line(size = 1) +
      labs(title = "Évolution du nombre total de ménages recensés par région",
           x = "Date",
           y = "Nombre cumulé de ménages",color = "Région") +
      theme_minimal()
  }
  )

  # Répartition des types de réponse (pie chart)
  output$pieChartReponses <- renderPlot({
    reponse_data <- data %>%
      count(FD09) %>%
      mutate(percentage = n / sum(n) * 100)

    ggplot(reponse_data, aes(x = "", y = percentage, fill = FD09)) +
      geom_bar(stat = "identity", width = 1) +
      scale_fill_manual(values = c("green", "yellow")) +
      coord_polar("y") +
      labs(title = "Répartition des typesde réponse", x = "", y = "") +
      theme_minimal()
  })

}

# Lancer l'application Shiny
shinyApp(ui = ui, server = server)
