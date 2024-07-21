# Salida del nombre de la conexión de la instancia de base de datos
output "instance_connection_name" {
  value = data.google_sql_database_instance.existing_instance.connection_name
}