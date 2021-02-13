resource "google_service_account" "default" {
  account_id   = "vault-compute-svc"
  display_name = "Vault Compute Service Account"
}

resource "google_compute_instance" "default" {
  name         = "Vault Node"
  machine_type = "e2-medium"
  zone         = "us-central1-a"

  tags = ["vault-member", "vault-cluster-node"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
    }
  }

  // Local SSD disk
  scratch_disk {
    interface = "SCSI"
  }

  network_interface {
    #network = "default"
    subnetwork    = google_compute_subnetwork.management-sub.self_link
    access_config {
      // Ephemeral IP
    }
  }

  metadata = {
    foo = "bar"
  }

  metadata_startup_script = "echo hi > /test.txt"

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }
}