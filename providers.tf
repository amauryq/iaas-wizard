terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "4.62.1"
    }
    random = {
      source = "hashicorp/random"
      version = "3.5.1"
    }
    template = {
      source = "hashicorp/template"
      version = "2.2.0"
    }
  }
  backend "gcs" {
  }
  required_version = ">=1.4.4,<1.5"
}

provider "google" {}
