data google_project default {

}

resource google_cloud_run_service default {
  name = var.name
  location = var.location
  autogenerate_revision_name = true

  template {
    spec {
      container_concurrency = var.concurrency
      timeout_seconds = var.timeout
      service_account_name = var.service_account_email

      containers {
        image = var.image

        resources {
          limits = {
            cpu = var.cpus
            memory = "${var.memory}Mi"
          }
        }

        dynamic "env" {
          for_each = var.env

          content {
            name = env.key
            value = env.value
          }
        }
      }
    }

    metadata {
      annotations = {
        "run.googleapis.com/cloudsql-instances" = join(",", var.cloudsql_connections)
        "run.googleapis.com/vpc-access-connector" = var.vpc_connector_name
        "autoscaling.knative.dev/maxScale" = var.max_instances
      }
    }
  }

  traffic {
    percent = 100
    latest_revision = var.revision == null
    revision_name = var.revision
  }
}


resource google_cloud_run_service_iam_member public_access {
  count = var.allow_public_access ? 1 : 0
  service = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  role = "roles/run.invoker"
  member = "allUsers"
}

resource google_cloud_run_domain_mapping domains {
  for_each = var.map_domains

  location = google_cloud_run_service.default.location
  name = each.value

  metadata {
    namespace = data.google_project.default.project_id
  }

  spec {
    route_name = google_cloud_run_service.default.name
  }
}