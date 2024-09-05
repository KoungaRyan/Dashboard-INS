
library(shiny)
library(shinydashboard)
library(ggplot2)
library(dplyr)
library(haven)
library(plotly)
library(leaflet)
library(lubridate)
options(warn = -1)

# Charger le fichier Stata
data <- read_dta("C:\\Users\\DELL\\Desktop\\carto.dta")

# Générer des dates aléatoires
set.seed(42)
start_date <- as.Date("2024-05-01")
end_date <- as.Date("2024-08-30")
random_dates <- as.Date(runif(nrow(data), min=as.numeric(start_date), max=as.numeric(end_date)), origin="1970-01-01")

# Ajouter la colonne des dates générées
data$dates <- random_dates

data$fd09[is.na(data$fd09)] <- 2
data <- as_factor(data)

data_evolution <- data %>%
  group_by(fd01, dates) %>%
  summarise(nombre_menages = n()) %>%
  arrange(fd01, dates) %>%
  mutate(Cumul = cumsum(nombre_menages))


# Interface utilisateur
ui <- dashboardPage(
  dashboardHeader(title = "Tableau de bord des enquêtes 2024"),
  dashboardSidebar(
    dateRangeInput("dateRange", "Date range:", start = "2024-05-01", end = "2024-08-30"),
    selectInput("region", "Région:", choices = unique(data$fd01))
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
      box(plotlyOutput("EvolutionTravail"), width = 6)
     
    ),
    fluidRow(
      box(plotlyOutput("progressionEnquetes"), width = 6),
      box(plotlyOutput("distributionEquipes"), width = 6)
    )
  )
)

# Serveur
server <- function(input, output) {
  
  # Filtrer les données selon les choix de l'utilisateur
  filteredData <- reactive({
    data %>%
      filter(fd01 == input$region)
  })
  
  # Calcul des statistiques pour les ValueBoxes
  output$totalEnquetes <- renderValueBox({
    valueBox(value = nrow(data), subtitle = "Total des enquêtes", icon = icon("list"), color = "blue")
  })
  
  output$enquetesCompletes <- renderValueBox({
    enquetes_completes <- sum(data$fd09 == "Oui, complètement")/ nrow(data) * 100
    valueBox(value = paste0(round(enquetes_completes, 2), "%"), subtitle = "Taux Enquêtes complètées", icon = icon("check"), color = "green")
  })
  
  output$tauxRefus <- renderValueBox({
    taux_refus <- sum(data$fd09 == "Oui, partielelment") / nrow(data) * 100
    valueBox(value = paste0(round(taux_refus, 2), "%"), subtitle = "Taux Enquêtes en cours", icon = icon("hourglass-half"), color = "yellow")
  })
  
  # Carte interactive de recensement
  output$carteRecensement <- renderLeaflet({
    data_unique <- filteredData() %>%
      distinct(s07a, s07b, .keep_all = TRUE)
    
    # Remplacer les NaN dans fd09 par 2 sans affecter les labels
    data_unique$fd09[is.na(data_unique$fd09)] <- 2
    
    pal <- colorFactor(
      palette = c("green", "orange", "red"),   # Ajoutez des couleurs pour tous les labels
      levels = c("Oui, complètement", "Oui, partiellement", "Non")  # Assurez-vous que les niveaux couvrent tous les labels dans fd09
    )
    
    # Créer la carte interactive
    leaflet(data_unique) %>%
      addTiles() %>%
      addCircleMarkers(
        ~s07a, ~s07b,
        color = ~pal(as_factor(fd09)), # Utilisation des niveaux numériques pour la couleur
        radius = 5,
        stroke = FALSE, fillOpacity = 0.8,
        label = ~paste0("Région: ", fd01, "<br>",
                        "Département: ", fd02, "<br>",
                        "Arrondissement: ", fd03, "<br>",
                        "Statut du recensement: ", as_factor(fd09)) # Les labels seront affichés correctement
      ) %>%
      addLegend(
        "bottomright",
        pal = pal,
        values = ~as_factor(fd09),
        title = "Statut du Recensement",
        opacity = 1
      )
  })
  
  # Distribution des réponses par région
  output$distributionRegions <- renderPlotly({
    ggplot(data, aes(x = fd01, fill = fd09)) +
      geom_bar() +
      scale_fill_manual(values = c("green", "orange")) +
      labs(title = "Distribution des réponses par région", x = "Région", y = "Nombre d'enquêtes") +
      theme_minimal()
  })
  
  #Evolution du travail par région
  output$EvolutionTravail <- renderPlotly({
    data$fd01 <- as_factor(data$fd01)
    # Filtrer les données pour la région x
    data_region <- filteredData()
    
    # Nombre total de ménages
    total_ménages <- nrow(data_region)
    
    # Nombre de ménages complètement terminés
    ménages_terminés <- sum(data_region$fd09 == "Oui, complètement", na.rm = TRUE)
    
    # Nombre de ménages non touchés
    ménages_non_touches <- sum(data_region$fd09 == "Non", na.rm = TRUE)
    
    # Nombre de ménages en cours
    ménages_en_cours <- sum(data_region$fd09 == "Oui, partielelment", na.rm = TRUE)
    
    
    # Créer un tableau des fréquences
    fréquences <- c(ménages_terminés, ménages_en_cours, ménages_non_touches)
    
    # Créer un DataFrame pour le graphique
    df <- data.frame(
      Statut = c("Terminés", "En Cours", "Non Touchés"),
      Fréquence = fréquences
    )
    
    # Filtrer les catégories avec une fréquence non nulle
    df_filtered <- df[df$Fréquence > 0, ]
    
    # Créer le diagramme en barres empilées
    ggplot(df_filtered, aes(input$region, y = Fréquence, fill = Statut)) +
      geom_bar(stat = "identity", width = 0.5) +
      coord_flip() +
      theme_minimal() +
      labs(title = paste("Statut des Ménages dans la Région suivante:",input$region ), 
           y = "Nombre de Ménages", 
           x = "") +
      scale_fill_manual(values = c("Terminés" = "green", "En Cours" = "yellow", "Non Touchés" = "red")) +
      geom_text(aes(label = Fréquence), position = position_stack(vjust = 0.5)) +
      theme(legend.title = element_blank())
  })
  
  # Progression des enquêtes au fil du temps
  output$progressionEnquetes <- renderPlotly({
    ggplot(data_evolution, aes(x = dates, y = Cumul, color = fd01, group = fd01)) +
      geom_line(size = 1) +
      labs(title = "Évolution du nombre total de ménages recensés par région",
           x = "Date",
           y = "Nombre cumulé de ménages",color = "Région") +
      theme_minimal()
    }
  )
  
  # Distribution des réponses par Grappe
  output$distributionEquipes <- renderPlotly({
    ggplot(data, aes(x = fd07, fill = fd09)) +
      geom_bar() +
      scale_fill_manual(values = c("green", "orange")) +  # Remplacez par les couleurs de votre choix
      labs(title = "Distribution des réponses par Grappe", x = "Grappe", y = "Nombre d'enquêtes") +
      theme_minimal()
  })
  
}

# Lancer l'application Shiny
shinyApp(ui = ui, server = server)
