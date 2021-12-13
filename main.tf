#creating vpcnetwork
resource "google_compute_network" "vpc_network" {
  name                    = var.vpc_network
  auto_create_subnetworks ="false"
}
#creating custom subnetwork with enable vpc flow logs in specifies ip ranges
resource "google_compute_subnetwork" "vpc_subnetwork" {
  name          = var.vpc_subnetwork
  network       = var.vpc_network
  region = "us-west1"
  ip_cidr_range = "10.1.3.0/24"
  #flow_logs="true"

  #log aggregation of subnetwork in vpc network
  log_config {
    aggregation_interval = "INTERVAL_5_MIN"
    #flow_logs="true"
    flow_sampling        = 0.5
    metadata             = "INCLUDE_ALL_METADATA"
  }
}
#creating firewall rules of the vpc-network with target tags and specified source ip ranges
resource "google_compute_firewall" "allow_http_ssh" {
  name    = "allow-http-ssh"
  network       = var.vpc_network
  target_tags = ["http-server"]
  source_ranges = ["0.0.0.0/0"]
#allowing tcp protocol with required ports
  allow {
    protocol = "tcp"
    ports    = ["80","22"]
  }
}
#creating instance(creating web server)
resource "google_compute_instance" "default" {
  name         = "web-server"
  zone         = "us-west1-a"
  machine_type = "f1-micro"
  boot_disk {
    initialize_params {
     image = "debian-cloud/debian-9"
    }
  }
  network_interface {
    network = var.vpc_network
    subnetwork = var.vpc_subnetwork
    access_config {
      # Allocate a one-to-one NAT IP to the instance
    }
  }
  #installing apache server
  metadata_startup_script = "sudo apt-get update && sudo apt-get install apache2 -y && echo '<!doctype html><html><body><h1>Hello World!</h1></body></html>' | sudo tee /var/www/html/index.html"

    #Apply the firewall rule to allow external IPs to access this instance
    tags = ["http-server"]
}

#Enabling audit logs(data access logs) on cloud storage

resource "google_project_iam_audit_config" "project"{
  project = var.project
  service = "storage.googleapis.com"
  audit_log_config {
    log_type = "ADMIN_READ"
  }
  audit_log_config {
    log_type = "DATA_WRITE"
  }
  audit_log_config {
    log_type = "DATA_READ"
    exempted_members = [
    ]
  }
}
#Export the network traffic to BigQuery to further analyze the logs
#creating Dataset

resource "google_bigquery_dataset" "default" {
        dataset_id                  = "auditandvpclogs"
        friendly_name               = "auditandvpclogs"
        location                    = "EU"

        labels = {
            env = "default"
        }
}
    #creating sink
    resource "google_logging_project_sink" "default" {
    name        = "vpc_flows"
    description = "exporting logs to bigquery"
    destination = "bigquery.googleapis.com/projects/fluted-anthem-331611/datasets/${google_bigquery_dataset.default.dataset_id}"
    filter ="resource.type= (gce_subnetwork  OR gcs_bucket) AND logName=projects/fluted-anthem-331611/logs/compute.googleapis.com%2Fvpc_flows OR  projects/fluted-anthem-331611/logs/cloudaudit.googleapis.com%2Factivity"

    # Whether or not to create a unique identity associated with this sink.
    unique_writer_identity = true

    /*bigquery_options {
    # options associated with big query
    # Refer to the resource docs for more information on the options you can use
  }*/
}
/*
resource "google_logging_project_sink" "default1" {
    name        = "audit_logs"
    description = "exporting logs to bigquery"
    destination ="bigquery.googleapis.com/projects/fluted-anthem-331611/datasets/${google_bigquery_dataset.default.dataset_id}"
    filter      = "resource.type=gcs_bucket AND logName=projects/fluted-anthem-331611/logs/cloudaudit.googleapis.com%2Factivity"
    # Whether or not to create a unique identity associated with this sink.
    unique_writer_identity = true

}*/



resource "google_project_iam_member" "log_writer" {
    project=var.project
    role = "roles/bigquery.dataEditor"
    member = google_logging_project_sink.default.writer_identity
}



