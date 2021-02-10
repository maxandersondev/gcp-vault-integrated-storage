data "google_compute_image" "debian_9" {
  family  = "debian-9"
  project = "debian-cloud"
}

data "google_compute_image" "centos_8" {
  family  = "centos-8"
  project = "centos-cloud"
}

data "google_compute_image" "debian_10" {
  family  = "debian-10"
  project = "debian-cloud"
}