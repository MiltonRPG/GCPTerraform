resource "google_compute_instance" "temp_instance" {
  count                   = var.create_temp_resources ? 1 : 0
  project                 = var.pr_id
  zone                    = var.zone
  name                    = var.nombre_instancia_temp
  machine_type            = var.tipo_maquina
  metadata_startup_script = var.apache_startup_script

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral public IP
    }
  }

  provisioner "local-exec" {
    command = <<-EOT
      ping -n 60 127.0.0.1 > nul
      gcloud compute instances stop ${self.name} --zone ${self.zone} --quiet
    EOT
  }
}

resource "google_compute_image" "custom_image" {
  count       = var.create_temp_image ? 1 : 0
  project     = var.pr_id
  name        = var.nombre_imagen
  source_disk = google_compute_instance.temp_instance[0].boot_disk[0].source

  depends_on = [google_compute_instance.temp_instance]
}

resource "null_resource" "ensure_instance_stopped" {
  count = var.create_temp_resources ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      if [ "$(gcloud compute instances describe ${google_compute_instance.temp_instance[0].name} --zone ${google_compute_instance.temp_instance[0].zone} --format='value(status)')" != "TERMINATED" ]; then
        gcloud compute instances stop ${google_compute_instance.temp_instance[0].name} --zone ${google_compute_instance.temp_instance[0].zone} --quiet
        for /l %i in (1, 1, 30) do (
          gcloud compute instances describe ${google_compute_instance.temp_instance[0].name} --zone ${google_compute_instance.temp_instance[0].zone} --format="value(status)" | findstr /v "TERMINATED" || exit
          echo "Waiting for instance to terminate..."
          ping -n 10 127.0.0.1 > nul
        )
      fi
      echo "Instance is terminated or was already stopped."
    EOT
  }
}

resource "null_resource" "delay_after_stop" {
  count = var.create_temp_resources ? 1 : 0

  provisioner "local-exec" {
    command = "ping -n 60 127.0.0.1 > nul"
  }

  depends_on = [null_resource.ensure_instance_stopped]
}

resource "null_resource" "wait_for_image_availability" {
  count = var.create_temp_image ? 1 : 0

  provisioner "local-exec" {
    command = <<-EOT
      for /l %i in (1,1,30) do (
        gcloud compute images describe ${google_compute_image.custom_image[0].name} --project ${google_compute_image.custom_image[0].project} > nul && exit
        echo "Waiting for image to be available..."
        ping -n 10 127.0.0.1 > nul
      )
      echo "Image is available."
    EOT
  }

  depends_on = [google_compute_image.custom_image]
}

resource "null_resource" "delete_temp_instance" {
  count = var.create_temp_resources ? 1 : 0

  provisioner "local-exec" {
    command = "gcloud compute instances delete ${google_compute_instance.temp_instance[0].name} --zone ${var.zone} --quiet"
  }

  depends_on = [google_compute_image.custom_image]
}

