terraform {
  required_version = ">= 0.12.20"
  required_providers {
    dynatrace = {
      // source = "drqc/dynatrace"
      source ="dynatrace.com/local/dynatrace"
       version = "1.0.4"
    }
    google = {
      version = ">= 3.58.0"
    }
    random = {
      version = "~> 2.2"
    }
    local = {
      version = "~> 1.4"
    }
  }
}
