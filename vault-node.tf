resource "google_service_account" "default" {
  account_id   = "vault-compute-svc"
  display_name = "Vault Compute Service Account"
}

# resource "google_project_iam_binding" "project" {
#   project = var.gcp_project_id
#   #role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   role = "roles/iam.serviceAccountAdmin"

#   members = [
#     format("serviceAccount:%s", google_service_account.default.email),
#   ]
# }

# data "google_iam_policy" "admin" {
#   binding {
#     role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

#     members = [
#       format("serviceAccount:%s", google_service_account.default.email),
#     ]
#   }
# }

# resource "google_project_iam_policy" "project" {
#   project     = var.gcp_project_id
#   policy_data = data.google_iam_policy.admin.policy_data
# }


resource "google_compute_instance" "default" {
  name         = "vault-node-1"
  machine_type = "n1-standard-1"
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

  metadata_startup_script = data.template_file.vault_first.rendered

  service_account {
    # Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = google_service_account.default.email
    scopes = ["cloud-platform"]
  }
}

data "template_file" "vault_first" {
  template = file("${path.module}/scripts/vault-config-first.tpl")
  vars = {
    encrypt_key = var.encrypt_key
    data_center = var.data_center
    project_name = var.gcp_project_id
    vault_join_tag = var.vault_join_tag
  }
}

output "rendered" {
  value = data.template_file.vault_first.rendered
}