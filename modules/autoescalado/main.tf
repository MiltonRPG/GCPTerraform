resource "google_compute_instance_group_manager" "default" {
  project            = var.pr_id
  name               = var.nombre_grupo_auto
  base_instance_name = var.nombre_grupo_auto
  zone               = var.zone
  version {
    instance_template = var.nombre_plantilla
  }
  target_size = var.instancias_min

  named_port {
    name = "http"
    port = 80
  }

  target_pools = [var.target_pool]

}



resource "google_compute_autoscaler" "default" {
  project         = var.pr_id
  name            = "${var.nombre_grupo_auto}-autoscaler"
  zone            = var.zone
  target          = google_compute_instance_group_manager.default.id

  autoscaling_policy {
    max_replicas    = var.instancias_max
    min_replicas    = var.instancias_min 
    cooldown_period = var.periodo_enfriado

    cpu_utilization {
      target = 0.15  # 15% CPU utilization to force quick scaling
    }
  }
}
