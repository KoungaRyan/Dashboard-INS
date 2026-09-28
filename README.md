# Dashboard INS — Suivi d'enquête terrain

Tableau de bord interactif en **R / Shiny** pour suivre en temps réel l'avancement d'une opération de collecte de l'**Institut National de la Statistique (INS)** : cartographie et dénombrement des ménages, par région, département, arrondissement et grappe (zone de dénombrement).

Le projet comprend aussi un **parseur de fichiers CSPro** (dictionnaire `.dcf` + données `.dat`) qui permet d'alimenter le tableau de bord directement à partir des données brutes remontées du terrain.

---

## Aperçu des fonctionnalités

| Élément | Description |
|---|---|
| **Indicateurs clés** | Nombre total d'enquêtes, taux d'enquêtes complétées, taux d'enquêtes en cours |
| **Carte interactive** (Leaflet) | Chaque structure recensée est positionnée par ses coordonnées GPS et colorée selon son statut : 🟢 complètement / 🟠 partiellement / 🔴 non recensée |
| **Distribution par région** | Diagramme en barres des réponses par région |
| **Statut des ménages par région** | Barres empilées *Terminés / En cours / Non touchés* pour la région sélectionnée |
| **Progression dans le temps** | Courbe du nombre cumulé de ménages recensés par région |
| **Distribution par grappe** | Nombre d'enquêtes par zone de dénombrement (ZD) |
| **Filtres** | Sélection de la région et de la période dans la barre latérale |

Tous les graphiques sont rendus interactifs avec **plotly** (zoom, survol, export).

---

## Structure du projet

```
Dashboard-INS-main/
├── README.md
└── INS projects/
    ├── INS projects.Rproj          # Projet RStudio
    ├── app_dashboard1.R            # ✅ Application Shiny principale (données Stata)
    ├── app2.R                      # 🧪 Prototype d'une variante (KPIs de collecte)
    ├── brouillons_propre.R         # Scripts exploratoires : carte, statuts, évolution
    ├── project data/
    │   └── carto.dta               # Données de cartographie (format Stata)
    └── Madame Diane/
        ├── RCSPro.R                # Parseur CSPro (.dcf + .dat → data frames R)
        ├── app_dashboard2.R        # Version du dashboard alimentée par les données CSPro
        ├── Download.R              # Récupération des fichiers .dat depuis le serveur FTP
        ├── CARTO.dcf               # Dictionnaire CSPro du questionnaire CARTO
        └── ETEFCCC2003.dat         # Exemple de fichier de données CSPro
```

---

## Données

Les données proviennent du questionnaire **CARTO** (CSPro 7.7). Principales variables utilisées :

| Variable | Libellé |
|---|---|
| `fd01` | Région (Adamaoua, Centre, Douala, Est, Extrême-Nord, Littoral, Nord, Nord-Ouest, Ouest, Sud, Sud-Ouest, Yaoundé) |
| `fd02` | Département |
| `fd03` | Arrondissement |
| `fd07` | Numéro séquentiel de la ZD (grappe) |
| `fd09` | Statut du recensement : *Oui, complètement* / *Oui, partiellement* / *Non* |
| `s07a`, `s07b` | Coordonnées GPS de la structure |

> ⚠️ **Dates simulées** — le fichier source ne contient pas encore de date de collecte. Pour construire les courbes d'évolution, les applications génèrent des dates aléatoires entre le 1er mai et le 30 août 2024 (`set.seed(42)`). Ces graphiques sont donc **illustratifs** tant qu'une vraie variable de date n'est pas branchée.

---

## Installation

### Prérequis

- R ≥ 4.1 (RStudio recommandé)

### Packages

```r
install.packages(c(
  "shiny", "shinydashboard", "ggplot2", "dplyr", "haven",
  "plotly", "leaflet", "lubridate"
))

# Uniquement pour la version CSPro (Madame Diane/)
install.packages(c("sf", "sp", "raster", "curl"))
```

---

## Utilisation

### 1. Dashboard à partir des données Stata

1. Ouvrir `INS projects/INS projects.Rproj` dans RStudio.
2. Dans `app_dashboard1.R`, remplacer le chemin absolu du fichier de données par un chemin relatif :

   ```r
   # Avant
   data <- read_dta("C:\\Users\\DELL\\Desktop\\carto.dta")
   # Après
   data <- read_dta("project data/carto.dta")
   ```

3. Lancer l'application :

   ```r
   shiny::runApp("app_dashboard1.R")
   ```

### 2. Dashboard à partir des fichiers CSPro

```r
source("../RCSPro.R")   # définit parse_dictionary()

parse_dictionary(
  dico    = "../CARTO.dcf",
  donnees = "../ETEFCCC2003.dat"
)
# → crée record1, record2, … : un data frame par type d'enregistrement
```

`app_dashboard2.R` fusionne ensuite ces enregistrements et affiche le tableau de bord (avec un filtre supplémentaire par grappe et un diagramme circulaire des types de réponse).

### Fonctionnement du parseur CSPro

`parse_dictionary()` lit le dictionnaire `.dcf` ligne par ligne pour en extraire :

- la longueur du type d'enregistrement (`RecordTypeLen`) ;
- les **variables d'identification** (`[IdItems]`) ;
- les **enregistrements** (`[Record]`) et leurs variables (`[Item]` : nom, position de départ, longueur, type).

Il découpe ensuite chaque ligne du fichier `.dat` (format à largeur fixe) selon ces positions et range les valeurs dans le data frame du record correspondant.

**Limites actuelles** : les *value sets* (libellés des modalités), le séparateur décimal et les dictionnaires multi-niveaux ne sont pas encore gérés.

---

## État du projet

| Fichier | État |
|---|---|
| `app_dashboard1.R` | Fonctionnel |
| `brouillons_propre.R` | Scripts d'exploration |
| `app2.R` | Prototype — fait référence à des colonnes (`date`, `submitted`, `responded`, `refused`…) absentes des données actuelles |
| `app_dashboard2.R` | En cours — dépend des objets produits par `RCSPro.R` ; contient un `install.packages()` à retirer |
| `RCSPro.R` | Fonctionnel pour les dictionnaires à un niveau |

### Pistes d'amélioration

- Remplacer les chemins absolus Windows par des chemins relatifs
- Brancher une vraie date de collecte à la place des dates simulées
- Faire réagir tous les graphiques aux filtres (région, période) — aujourd'hui seuls la carte et le graphique de statut utilisent le filtre région
- Corriger la coquille `"Oui, partielelment"` dans le calcul du taux d'enquêtes en cours
- Gérer les *value sets* CSPro pour obtenir directement les libellés
- Déplacer les identifiants FTP de `Download.R` dans des variables d'environnement (`.Renviron`)

---

## Technologies

R · Shiny · shinydashboard · ggplot2 · plotly · leaflet · dplyr · haven · CSPro

## Auteur

**Ryan Kounga** — [@KoungaRyan](https://github.com/KoungaRyan)
