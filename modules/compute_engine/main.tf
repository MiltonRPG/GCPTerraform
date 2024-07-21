resource "google_compute_instance" "independent_vm" {
  project      = var.pr_id
  zone         = var.zone
  name         = var.maquina_nombre
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // IP pública efímera
    }
  }

  metadata_startup_script = var.script_template_content
}
