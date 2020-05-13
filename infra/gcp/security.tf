# A firewall rule allowing ssh into the VPC.
resource "google_compute_firewall" "ssh" {
  name        = "${var.instance_name}-ssh"
  description = "Firewall rule allowing ssh to cloudperf."
  network     = "default"

  allow {
    protocol = "tcp"
    ports    = [22]
  }
}

# A firewall rule allowing http
resource "google_compute_firewall" "http" {
  name        = "${var.instance_name}-http"
  description = "Firewall rule allowing http to cloudperf."
  network     = "default"

  allow {
    protocol = "tcp"
    ports    = [80]
  }
}
