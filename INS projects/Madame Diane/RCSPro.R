## ce qu'il faut mettre à jour après,
# considérer les valuesets
# considérer les decimalchar ?
# considérer les cas multilevel

#' Title
#'
#' @return
#' @export
#'
#' @examples
parse_dictionary <- function(dico, donnees){
  lignes <- readLines(dico)

  record_item=0
  idtrouve=0

  les_records <- data.frame(gpe_Label0 = character(), gpe_Name0 = character(), gpe_Initial0 = character(), gpe_MaxRecords0 = numeric(), gpe_Len0 = numeric())
  my_records <- data.frame(gpe_Label0 = character(), gpe_Name0 = character(), gpe_Initial0 = character(), gpe_MaxRecords0 = numeric(), gpe_Len0 = numeric(), var_Label0 = character(), var_Name0 = character(), var_Start0 = numeric(), var_Len0 = numeric(), var_DataType0 = character(), var_ZeroFill0 = character())
  les_id <- data.frame(var_Label0 = character(), var_Name0 = character(), var_Start0 = numeric(), var_Len0 = numeric(), var_DataType0 = character(), var_ZeroFill0 = character())
  #on lit le dictionnaire ligne par ligne pour extraire la structure
  for (ligne in lignes) {
    if (idtrouve==0) {
      #on détermine la taille des records type
      rubrique <- substr(ligne, 1, 13)
      if (rubrique == "RecordTypeLen") {
        Initials_length = as.numeric(substr(ligne, 15, nchar(ligne)))
      }
      #on détermine le debut des variables d'identification
      rubrique <- substr(ligne, 1, 9)
      if (rubrique == "[IdItems]") {
        idtrouve=1
        gpe_Label="Identifiant"
        gpe_Name="Identifiant"
        gpe_Initial="None"
        gpe_MaxRecords=0
        gpe_Len=0
      }
      next
    }
    #on détermine le debut des records
    rubrique <- substr(ligne, 1, 8)
    if (rubrique == "[Record]") {
      gpe_MaxRecords=1
      record_item=1
      next
    }
    rubrique <- substr(ligne, 1, 5)
    if (rubrique == "Label" & record_item==1) {
      gpe_Label <- substr(ligne, 7, nchar(ligne))
      next
    }
    rubrique <- substr(ligne, 1, 4)
    if (rubrique == "Name" & record_item==1) {
      gpe_Name <- substr(ligne, 6, nchar(ligne))
      next
    }
    rubrique <- substr(ligne, 1, 15)
    if (rubrique == "RecordTypeValue" & record_item==1) {
      gpe_Initial <- substr(ligne, 18, nchar(ligne)-1)
      next
    }
    rubrique <- substr(ligne, 1, 10)
    if (rubrique == "MaxRecords" & record_item==1) {
      gpe_MaxRecords <- as.numeric(substr(ligne, 12, nchar(ligne)))
      next
    }
    rubrique <- substr(ligne, 1, 9)
    if (rubrique == "RecordLen" & record_item==1) {
      gpe_Len <- as.numeric(substr(ligne, 11, nchar(ligne)))

      new_row <- c(gpe_Label, gpe_Name, gpe_Initial, gpe_MaxRecords, gpe_Len)
      #new_row <- c(var_Label, var_Name, var_Start, var_Len, var_Type, var_Zero)
      les_records <- rbind(les_records, new_row)

      next
    }
    #on détermine le debut de la définition d'une variable
    rubrique <- substr(ligne, 1, 6)
    if (rubrique == "[Item]") {
      record_item=0
    }

    rubrique <- substr(ligne, 1, 5)
    if (rubrique == "Label" & record_item==0) {
      var_Label <- substr(ligne, 7, nchar(ligne))
      next
    }
    rubrique <- substr(ligne, 1, 4)
    if (rubrique == "Name" & record_item==0) {
      var_Name <- substr(ligne, 6, nchar(ligne))
      next
    }

    rubrique <- substr(ligne, 1, 5)
    if (rubrique == "Start" & record_item==0) {
      var_Start <- as.numeric(substr(ligne, 7, nchar(ligne)))
      next
    }
    rubrique <- substr(ligne, 1, 3)
    if (rubrique == "Len" & record_item==0) {
      var_Len <- as.numeric(substr(ligne, 5, nchar(ligne)))
      next
    }
    rubrique <- substr(ligne, 1, 8)
    if (rubrique == "DataType" & record_item==0) {
      var_Type <- substr(ligne, 10, nchar(ligne))
      if(var_Type =="Alpha"){
        if (0 < gpe_Len) {
          new_row <- c(gpe_Label, gpe_Name, gpe_Initial, gpe_MaxRecords, gpe_Len, var_Label, var_Name, var_Start, var_Len, var_Type, var_Zero)
          #new_row <- c(var_Label, var_Name, var_Start, var_Len, var_Type, var_Zero)
          my_records <- rbind(my_records, new_row)
        } else if (gpe_Len == 0){
          new_row2 <- c(var_Label, var_Name, var_Start, var_Len, var_Type, var_Zero)
          les_id <- rbind(les_id, new_row2)
        }
      }
      next
    }
    rubrique <- substr(ligne, 1, 8)
    if (rubrique == "ZeroFill" & record_item==0) {
      var_Zero <- substr(ligne, 10, nchar(ligne))
      if (0 < gpe_Len) {
        new_row <- c(gpe_Label, gpe_Name, gpe_Initial, gpe_MaxRecords, gpe_Len, var_Label, var_Name, var_Start, var_Len, var_Type, var_Zero)
        #new_row <- c(var_Label, var_Name, var_Start, var_Len, var_Type, var_Zero)
        my_records <- rbind(my_records, new_row)
      } else if (gpe_Len == 0){
        new_row2 <- c(var_Label, var_Name, var_Start, var_Len, var_Type, var_Zero)
        les_id <- rbind(les_id, new_row2)
      }
      next
    }
    rubrique <- substr(ligne, 1, 10)
    if (rubrique == "[ValueSet]") {
      record_item==3
      next
    }
  }
  colnames(my_records) <- c("Gpe", "GpeN", "Initial", "MaxRecord", "GpeTaille", "Var", "VarN", "VarStart", "VarLen", "VarType", "Zerofill")
  colnames(les_id) <- c("Var", "VarN", "VarStart", "VarLen", "VarType", "Zerofill")
  colnames(les_records) <- c("Gpe", "GpeN", "Initial", "MaxRecord", "GpeTaille")

  my_group_records = split(my_records, my_records$Initial)
  les_var_id = les_id$VarN

  # les résultats sont :
  #les_id : les variables d'identification
  # my_records : la liste de toutes les variables hors identification
  #les_records : la liste des records
  #my_group_records : les variables groupées par record

  #On commence à casser les données
  lignes <- readLines(donnees, skipNul = TRUE)

  nb_id <- nrow(les_id)

  #on initialise les records pour que même si on n'a pas les données d'un record, son data frame soit là et vide
  for (i in 1:nrow(les_records)){
    df_name <- data.frame()
    assign(paste0("record", i), df_name)
  }

  for (ligne in lignes) {
    #les_fin <- substr(lignes, Initials_length+1, nchar(ligne))
    la_position=Initials_length
    laliste = c()
    #on détermine le record auquel appartient la ligne
    l_initiale <- substr(ligne, 1, Initials_length)
    index <- which(les_records$Initial == l_initiale)[1]

    #on extraie les valeurs des identifiants
    for (i in 1:nb_id) {
      #assign(les_ids$VarN[i], substr(ligne, la_position + 1, la_position + as.numeric(les_id$VarLen[i])))
      laliste = c(laliste, substr(ligne, la_position + 1, la_position + as.numeric(les_id$VarLen[i])))
      la_position = la_position + as.numeric(les_id$VarLen[i])
    }
    for (i in 1:nrow(my_group_records[[index]])) {
      #assign(my_group_records[[index]]$VarN[i], substr(ligne, la_position + 1, la_position + as.numeric(my_group_records[[index]]$VarLen[i])))
      laliste = c(laliste, substr(ligne, la_position + 1, la_position + as.numeric(my_group_records[[index]]$VarLen[i])))
      la_position = la_position + as.numeric(my_group_records[[index]]$VarLen[i])
    }
    # Ajouter une ligne de laliste au data frame recordi (par exemple, record1, record2, etc.)
    assign(paste0("record", index), rbind(get(paste0("record",index)),laliste))
  }

  for (i in 1:nrow(les_records)){
    df_name <- get(paste0("record", i))
    colnames(df_name) <- c(les_id$VarN, my_group_records[[i]]$VarN)
    assign(paste0("record", i), df_name)
  }
  # résultats :
  # record`i', autant de dataframe que de record retrouvés dans les données
}
donnees <- file.choose()
dico <- file.choose()
parse_dictionary(dico, donnees)

parse_dictionary(dico, donnees)
record1
