terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "azure-devsecops-landing-zone"
    workspaces {
      name = "azure-devsecops-landing-zone"
    }
  }
}