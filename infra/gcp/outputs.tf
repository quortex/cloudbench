output "cloudperf_internal_ip" {
  value = google_compute_instance.cloudperf.network_interface.0.network_ip
}

output "cloudperf_external_ip" {
  value = google_compute_instance.cloudperf.network_interface.0.access_config.0.nat_ip
}

output "ssh_user" {
  value = var.ssh_user
}

output "cpu_platform" {
  value = google_compute_instance.cloudperf.cpu_platform
}