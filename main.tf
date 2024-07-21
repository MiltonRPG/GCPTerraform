terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "5.37.0"
    }
  }
}

provider "google" {
  project     = var.pr_id
  region      = var.region
  zone        = var.zone
  credentials = file(var.pr_cred)
}

/*resource "google_compute_network" "mired" {
  name = "nueva-red"
}*/

/*resource "google_compute_address" "miip" {
  name = "static-ip"
}*/

# Módulo de base de datos
module "database" {
  source            = "./modules/database"
  db_instance       = var.db_instance
  db_names          = var.db_names
  db_users          = var.db_users
}

# Módulo de Servidor Web
module "servidorwebtemporal" {
  source                 = "./modules/servidorwebtemporal"
  pr_id                  = var.pr_id
  zone                   = var.zone
  nombre_imagen          = var.nombre_imagen
  nombre_instancia_temp  = var.nombre_instancia_temp
  tipo_maquina           = var.tipo_maquina
  apache_startup_script  = var.apache_startup_script
  create_temp_resources  = var.create_temp_resources
  create_temp_image      = var.create_temp_image

}

output "nombre_imagen_self_link" {
  value = module.servidorwebtemporal.nombre_imagen_self_link
}

# Módulo de Plantilla de Instancia
module "plantillas_instancias" {
  source                = "./modules/plantillas_instancias"
  pr_id                 = var.pr_id
  region                = var.region
  zone                  = var.zone
  nombre_imagen_self_link = module.servidorwebtemporal.nombre_imagen_self_link
  nombre_plantilla      = var.nombre_plantilla
  tipo_maquina          = var.tipo_maquina
}

# Módulo de Autoescalado
module "autoescalado" {
  source                  = "./modules/autoescalado"
  pr_id                   = var.pr_id
  zone                    = var.zone
  nombre_plantilla        = module.plantillas_instancias.instance_template_self_link
  nombre_grupo_auto       = var.nombre_grupo_auto
  periodo_enfriado        = var.periodo_enfriado
  instancias_min          = var.instancias_min
  instancias_max          = var.instancias_max
  target_pool              = google_compute_target_pool.default.self_link
}

# Configuración del balanceador de carga
resource "google_compute_http_health_check" "default" {
  name                = "http-basic-check"
  request_path        = "/"
  check_interval_sec  = 5
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 2
}

resource "google_compute_target_pool" "default" {
  name       = "web-pool"
  health_checks = [google_compute_http_health_check.default.self_link]
  project    = var.pr_id
  region     = var.region
}

resource "google_compute_forwarding_rule" "default" {
  name       = "http-rule"
  target     = google_compute_target_pool.default.self_link
  port_range = "80"
  project    = var.pr_id
  region     = var.region
  ip_protocol = "TCP"
}

# Módulo de Máquina Independiente
module "compute_engine" {
  source                = "./modules/compute_engine"
  pr_id                 = var.pr_id
  zone                  = var.zone
  maquina_nombre        = var.maquina_nombre
  lb_ip                 = google_compute_forwarding_rule.default.ip_address
  script_template_content = templatefile("${abspath(path.root)}/startup_script.tpl", { LB_IP = google_compute_forwarding_rule.default.ip_address })
  
}

resource "random_string" "random" {
  length = 9
  special = false
  upper = false
}

# Verificación del contenido del archivo
locals {
  script_content = file("${abspath("${path.root}/startup_script.tpl")}")
}

output "script_content" {
  value = local.script_content
}

/*
# Datos de la instancia de base de datos SQL existente. Esto no crea la instancia, solo la referencia.
data "google_sql_database_instance" "existing_instance" {
  name = var.BBDDInstance
}

# Recurso para crear una base de datos llamada "google" en la instancia existente.
resource "google_sql_database" "database_google" {
  name     = "google"
  instance = data.google_sql_database_instance.existing_instance.name
}

# Recurso para crear una base de datos llamada "cloud" en la instancia existente.
resource "google_sql_database" "database_cloud" {
  name     = "cloud"  # Nombre de la base de datos a crear
  instance = data.google_sql_database_instance.existing_instance.name  # Nombre de la instancia existente
}

# Recurso para crear un usuario en la instancia de MySQL.
resource "google_sql_user" "user" {
  name     = var.dbuser  # Nombre del usuario de la base de datos
  instance = data.google_sql_database_instance.existing_instance.name  # Nombre de la instancia existente
  password = var.dbpassword  # Contraseña del usuario de la base de datos
}


# Salida que muestra el nombre de conexión de la instancia de Cloud SQL.
output "instance_connection_name" {
  value = data.google_sql_database_instance.existing_instance.connection_name  # Valor de la salida
}

*/

# Salida que muestra el nombre de conexión de la instancia de Cloud SQL.
output "instance_connection_name" {
  value = module.database.instance_connection_name  # Valor de la salida
}

/*resource "google_app_engine_application" "app" {
  project     = var.pr_id
  location_id = var.region1
  // Condición para solo crear si no existe
  lifecycle {
    create_before_destroy = true
  }
}*/


# Ejecutar el script para generar la versión
data "external" "generate_version" {
  program = ["python", "${path.module}/generate_version.py", var.service_name]
}

resource "google_app_engine_standard_app_version" "app_version" {
  service     = var.service_name
  version_id  = data.external.generate_version.result["version"]
  project     = var.pr_id
  runtime     = "python310"

  entrypoint {
    shell = "gunicorn -b :$PORT main:app"
  }

  deployment {
    files {
      name = "app.yaml"
      source_url = "https://storage.googleapis.com/bucketbbdd/app-engine-source/app.yaml"
    }
    files {
      name = "main.py"
      source_url = "https://storage.googleapis.com/bucketbbdd/app-engine-source/main.py"
    }
    files {
      name = "requirements.txt"
      source_url = "https://storage.googleapis.com/bucketbbdd/app-engine-source/requirements.txt"
    }
  }

  env_variables = {
    CLOUDSQL_CONNECTION_NAME = var.cloudsql_connection_name
    CLOUDSQL_USER            = var.cloudsql_user
    CLOUDSQL_PASSWORD        = var.cloudsql_password
    CLOUDSQL_DATABASE        = var.cloudsql_database
  }

  lifecycle {
    ignore_changes = [service,version_id]
    create_before_destroy = true
  }

}

output "app_version_url" {
  value = "https://${var.service_name}-dot-${var.pr_id}.appspot.com"
}
