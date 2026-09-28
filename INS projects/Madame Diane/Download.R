#les paramètres d'entrée sont
#ftp_server, username, password
#remote_file (normalement remote_folder)
#local_file (normalement local_folder)

library(curl)
# Set the FTP server details
ftp_server <- "srever"
username <- "user_name"
password <- "user_password"

#cette syntaxe ne télécharge que le fichier FDSID401.dat
# les fichiers ont le format "FDSID" + un code de 3 chiffres + ".dat"

remote_file <- "/FDS/IDENTIF/DATA/FDSID401.dat"
#402 403 501 502 503
local_file <- "D:\\SAUVEGARDE\\INS\\DDS\\FDS\\IDENTIF2\\IDENTIFICATION\\FDSID401.dat"

# Create a curl handle
h <- new_handle(
  userpwd = paste0(username, ":", password)
)
# Download the file
curl_download(paste0("ftp://", ftp_server, remote_file), local_file, handle = h)

# Close the curl handle
# ne marche pas handle_close(h)
