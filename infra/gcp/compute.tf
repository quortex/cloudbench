# The image used for cloudperf VM.
data "google_compute_image" "cos" {
  family  = "debian-10"
  project = "debian-cloud"
}

# A static external address for cloudperf.
resource "google_compute_address" "cloudperf" {
  name   = var.instance_name
  region = var.region
}

# The chart-museum VM
resource "google_compute_instance" "cloudperf" {
  name         = var.instance_name
  machine_type = var.instance_type
  zone         = var.zone

  description               = "A VM used to test cloud performances."
  allow_stopping_for_update = false
  deletion_protection       = false


  boot_disk {
    initialize_params {
      size = 10
      type = "pd-standard"
      image = data.google_compute_image.cos.self_link
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Ephemeral IP
    }
  }

  labels = {
    stop = "25"
  }

  metadata = {
    ssh-keys = "${var.ssh_user}:${file(var.ssh_pub_key_file)}"
  }
}

