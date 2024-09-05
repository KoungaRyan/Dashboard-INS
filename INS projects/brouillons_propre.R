
library(haven)
library(dplyr)
library(ggplot2)
library(plotly)
library(leaflet) 
options(warn = -1)


data=read_dta("C:\\Users\\DELL\\Desktop\\carto.dta")



#### Carte de la répresentation des structures qui ont déjà été ou non totalemen récensés



# Supprimer les doublons
data_unique <- data %>%
  distinct(s07a, s07b, .keep_all = TRUE)


# Créer une palette de couleurs pour les statuts de recensement
pal <- colorFactor(
  palette = c("green", "orange", "red"),  # Vert, orange, rouge
  levels = c("Oui, complètement", "Oui, partiellement", "Non")
)

# Créer la carte interactive
map <- leaflet(data_unique) %>%
  addTiles() %>%
  addCircleMarkers(
    ~s07a, ~s07b,
    color = ~pal(as_factor(fd09)),  # Utilisation directe de la colonne fd09
    radius = 5,  # Taille des marqueurs
    stroke = FALSE, fillOpacity = 0.8,
    label = ~paste0("Région: ", fd01, "<br>",
                    "Département: ", fd02, "<br>",
                    "Arrondissement: ", fd03, "<br>",
                    "Statut du recensement: ", as_factor(fd09))
  ) %>%
  addLegend(
    "bottomright",
    pal = pal,
    values = ~as_factor(fd09),
    title = "Statut du Recensement",
    opacity = 1
  )

# Afficher la carte
map





#### Evolution du travail par région

data$fd01 <- as_factor(data$fd01)
# Filtrer les données pour la région x
data_region <- subset(data, fd01 == "Est")


# Nombre total de ménages
total_ménages <- nrow(data_region)

# Nombre de ménages complètement terminés
ménages_terminés <- sum(data_region$fd09 == "Oui, complètement", na.rm = TRUE)

# Nombre de ménages non touchés
ménages_non_touches <- sum(is.na(data_region$fd09))

# Nombre de ménages en cours
ménages_en_cours <- total_ménages - (ménages_terminés + ménages_non_touches)


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


ggplot(df_filtered, aes(x = "", y = Fréquence, fill = Statut)) +
  geom_bar(stat = "identity", width = 0.5) +
  coord_flip() +
  theme_minimal() +
  labs(title = "Statut des Ménages dans la Région X", 
       y = "Nombre de Ménages", 
       x = "") +
  scale_fill_manual(values = c("Terminés" = "green", "En Cours" = "orange", "Non Touchés" = "red")) +
  geom_text(aes(label = Fréquence), position = position_stack(vjust = 0.5)) +
  theme(legend.title = element_blank())




#### Evolution du travail par jour et par région (cumul et non cumul)

data_filtered2 <- data[!is.na(data$fd09), ]

# Définir la plage de dates (par exemple, du 1er janvier 2024 au 31 décembre 2024)
date_debut <- as.Date("2024-01-01")
date_fin <- as.Date("2024-01-31")
#date_fin <- as.Date("2024-03-31")

# Générer des dates aléatoires dans la plage spécifiée pour chaque ligne filtrée
set.seed(123) # Fixer une graine pour la reproductibilité

data_filtered2$dates <- sample(seq(date_debut, date_fin, by = "day"), size = nrow(data_filtered2), replace = TRUE)

# Réintégrer la colonne 'dates' dans le dataset original
data$dates <- NA # Initialiser la colonne 'dates' avec des NA
data$dates[!is.na(data$fd09)] <- data_filtered2$dates
data$dates <- as.Date(data$dates, origin = "1970-01-01")


# Supposons que votre dataframe 'data' ait une colonne 'region' qui identifie les régions.
data$fd01 <- as_factor(data$fd01)
# Créer un dataframe avec le nombre cumulé de ménages recensés par date et par région
data_evolution <- data %>%
  group_by(fd01, dates) %>%
  summarise(nombre_menages = n()) %>%
  arrange(fd01, dates) %>%
  mutate(Cumul = cumsum(nombre_menages))

# Créer le graphique de l'évolution du cumul de ménages recensés au fil du temps par région
p <- ggplot(data_evolution, aes(x = dates, y = Cumul, color = fd01, group = fd01)) +
  geom_line(size = 1) +
  labs(title = "Évolution du cumul de ménages recensés par région et par jour",
       x = "Date",
       y = "Nombre cumulé de ménages",
       color = "Région") +
  theme_minimal()

# Rendre le graphique interactif
ggplotly(p)




# Créer le graphique de l'évolution du nombre total de ménages recensés au fil du temps par région
p <- ggplot(data_evolution, aes(x = dates, y = nombre_menages, color = fd01, group = fd01)) +
  geom_line(size = 1) +
  labs(title = "Évolution du cumul de ménages recensés par région et par jour",
       x = "Date",
       y = "Nombre de ménages",
       color = "Région") +
  theme_minimal()

# Rendre le graphique interactif
ggplotly(p)



str(data)
