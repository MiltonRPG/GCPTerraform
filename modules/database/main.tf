
# Referencia a la instancia de base de datos SQL existente
data "google_sql_database_instance" "existing_instance" {
  name = var.db_instance  # Nombre de la instancia proporcionada por la variable
}

/*resource "google_sql_database_instance" "default" {
  name             = var.db_instance
  database_version = var.db_version
  region           = var.db_region

  
}*/

# Crear bases de datos en la instancia de Cloud SQL
resource "google_sql_database" "default" {
  count    = length(var.db_names)  # Crear tantos recursos como elementos en la lista de nombres de bases de datos
  name     = element(var.db_names, count.index)  # Asignar el nombre de la base de datos de la lista
  instance = data.google_sql_database_instance.existing_instance.name  # Asignar la instancia de base de datos
}

# Crear usuarios en la instancia de Cloud SQL
resource "google_sql_user" "default" {
  count    = length(var.db_users)  # Crear tantos recursos como elementos en la lista de usuarios
  name     = element(var.db_users, count.index).name  # Asignar el nombre del usuario de la lista
  instance = data.google_sql_database_instance.existing_instance.name  # Asignar la instancia de base de datos
  password = element(var.db_users, count.index).password  # Asignar la contraseña del usuario de la lista
}

/*resource "google_storage_bucket" "bucket" {
  name     = var.bck_nombre
  location = var.db_region
}*/

