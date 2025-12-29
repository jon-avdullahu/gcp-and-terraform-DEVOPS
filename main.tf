#FILLIMI
terraform {
  #SPECIFIKAT E PROVIDERIT
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.8.0"
    }
  }
}

# SPECIFIKAT E PROVIDERIT "GOOGLE"
provider "google" {
  project = "argon-liberty-482210-c3"
  region  = "europe-north1"
}

#DEFINIMI I RRJETIT VPC

resource "google_compute_network" "custom_vpc_network" {
  name                    = "terraform-custom-vpc"
  auto_create_subnetworks = false
  #FALSE = MANUAL ||||| TRUE = AUTOMATIK
  routing_mode = "REGIONAL"
}


# DEFINIMI I SUBNETIT MRENDA VPC

resource "google_compute_subnetwork" "network_subnet" {
  name          = "terraform-subnet-europe-north1"
  ip_cidr_range = "10.0.1.0/24"
  region        = "europe-north1"
  network       = google_compute_network.custom_vpc_network.id

}


# GKE CLUSTER
#SSD TOTAL GB : REQUEST REQUIRES 300 AND IS SHORT 50 GB, WHY? 
#BECAUSE FREE ACCOUNT has 250gb, initial default node pool uses 3 nodes
#with 100 gb each

resource "google_container_cluster" "primary" {

  name     = "primary-cluster"
  location = "europe-north1"


  network    = google_compute_network.custom_vpc_network.id
  subnetwork = google_compute_subnetwork.network_subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

  node_config {
    disk_size_gb = 50
    disk_type    = "pd-standard" #USE HDD INSTEAD OF SSD
  }
}
# NODES (SERVERAT QE I BOJN RUN APP-S)

resource "google_container_node_pool" "primary_nodes" {
  name       = "primary-node-pool"
  location   = "europe-north1"
  cluster    = google_container_cluster.primary.name ##KOMENT?
  node_count = 1

  node_config {
    preemptible  = true #Cheaper (But why?) and what is the meaning of it?
    machine_type = "e2-medium"
    disk_size_gb = 50
    disk_type    = "pd-standard"

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}

resource "google_artifact_registry_repository" "my-repo" { #DEFINIMI I EMRIT
  location      = "europe-north1"
  repository_id = "my-repo"
  description   = "Docker repository"
  format        = "DOCKER"
}


resource "google_compute_firewall" "allow_http" {
  name    = "allow-http-traffic"
  network = google_compute_network.custom_vpc_network.id
  allow {
    protocol = "tcp"
    ports    = ["80", "5000"]
  }
  source_ranges = ["0.0.0.0/0"]
}
