terraform {
  required_version = ">= 1.2.6"
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
      version = "~> 2.21.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.6.0"
    }
  }
}

module "k8s_infra" {
  source = "../do/infra"
  do_token = var.do_token
  k8s_ingress_domain = var.k8s_ingress_domain
}

module "ingress_nginx" {
  source = "../ingress-nginx"
  cluster_token =  module.k8s_infra.cluster_token
  cluster_host =  module.k8s_infra.cluster_endpoint
  cluster_ca_certificate_b64 = module.k8s_infra.cluster_certificate
  loadbalancer_id =  module.k8s_infra.load_balancer_id
}

provider "helm" {
  kubernetes {
    host  = module.k8s_infra.cluster_endpoint
    token =  module.k8s_infra.cluster_token
    cluster_ca_certificate = base64decode(
      module.k8s_infra.cluster_certificate
    )
  }
}


module "cert_manager" {
  source = "../cert-manager"
  cluster_token =  module.k8s_infra.cluster_token
  cluster_host =  module.k8s_infra.cluster_endpoint
  cluster_ca_certificate_b64 = module.k8s_infra.cluster_certificate
  letsencrypt_email = var.letsencrypt_email

  depends_on = [module.ingress_nginx]

  providers = {
    helm = helm
  }
}

module "argocd" {
  source = "../argocd"
  cluster_token =  module.k8s_infra.cluster_token
  cluster_host =  module.k8s_infra.cluster_endpoint
  cluster_ca_certificate_b64 =  module.k8s_infra.cluster_certificate
  argocd_oauth_key =  var.argocd_oauth_key
  ingress_domain = var.k8s_ingress_domain
}
