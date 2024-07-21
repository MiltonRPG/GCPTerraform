
# Salida del nombre de la imagen personalizada
locals {
  imagen_self_link = var.create_temp_image ? google_compute_image.custom_image[0].self_link : null
}

output "nombre_imagen_self_link" {
  value = local.imagen_self_link
}