
resource "google_compute_instance_template" "default" {
  name         = var.nombre_plantilla
  project      = var.pr_id
  machine_type = var.tipo_maquina

  disk {
    auto_delete = true
    boot        = true
    source_image = var.nombre_imagen_self_link
  }

  network_interface {
    network = "default"

    access_config {
      # IP pública efímera (you can configure here)
    }
  }

  service_account {
    scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }

  lifecycle {
    ignore_changes = [name, project, machine_type, disk, network_interface, service_account]
  }

}






