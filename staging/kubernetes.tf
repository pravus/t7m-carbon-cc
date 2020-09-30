resource "digitalocean_kubernetes_cluster" "staging" {
  name    = "staging"
  region  = var.k8s_region
  version = "1.18.8-do.0"
  tags    = ["staging"]

  node_pool {
    name       = "worker-pool"
    size       = "s-2vcpu-2gb"
    node_count = 2
    tags       = ["staging"]
  }
}

provider "kubernetes" {
  load_config_file = false
  host  = digitalocean_kubernetes_cluster.staging.endpoint
  token = digitalocean_kubernetes_cluster.staging.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.staging.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    load_config_file = false
    host  = digitalocean_kubernetes_cluster.staging.endpoint
    token = digitalocean_kubernetes_cluster.staging.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.staging.kube_config[0].cluster_ca_certificate
    )
  }
}

resource "digitalocean_container_registry_docker_credentials" "staging" {
  registry_name = var.docker_registry
}

resource "kubernetes_secret" "staging" {
  metadata {
    name = "registry-${var.docker_registry}"
  }
  type = "kubernetes.io/dockerconfigjson"
  data = {
    ".dockerconfigjson" = digitalocean_container_registry_docker_credentials.staging.docker_credentials
  }
}

resource "kubernetes_default_service_account" "staging" {
  metadata {
    namespace = "default"
  }
  image_pull_secret {
    name = kubernetes_secret.staging.metadata[0].name
  }
}

resource "kubernetes_namespace" "ingress-nginx" {
  metadata {
    name = "ingress-nginx"
  }
}

resource "helm_release" "nginx-ingress-controller" {
  name       = "nginx-ingress"
  chart      = "ingress-nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  namespace  = "ingress-nginx"
}

resource "kubernetes_deployment" "www-carbon-cc" {
  metadata {
    name = "www-carbon-cc"
    labels = {
      app = "www-carbon-cc"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "www-carbon-cc"
      }
    }
    template {
      metadata {
        labels = {
          app = "www-carbon-cc"
        }
      }
      spec {
        container {
          name  = "www"
          image = "registry.digitalocean.com/${var.docker_registry}/www-carbon-cc:v0.0.7"
          port {
            container_port = 8000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "www-carbon-cc" {
  metadata {
    name = "www-carbon-cc"
  }
  spec {
    selector = {
      app = kubernetes_deployment.www-carbon-cc.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 8000
    }
    type = "NodePort"
  }
}

resource "kubernetes_deployment" "www-at-jhord-http" {
  metadata {
    name = "www-at-jhord-http"
    labels = {
      app = "www-at-jhord-http"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "www-at-jhord-http"
      }
    }
    template {
      metadata {
        labels = {
          app = "www-at-jhord-http"
        }
      }
      spec {
        container {
          name  = "www"
          image = "registry.digitalocean.com/${var.docker_registry}/www-at-jhord-http:v0.0.18"
          port {
            container_port = 8000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "www-at-jhord-http" {
  metadata {
    name = "www-at-jhord-http"
  }
  spec {
    selector = {
      app = kubernetes_deployment.www-at-jhord-http.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 80
      target_port = 8000
    }
    type = "NodePort"
  }
}

resource "kubernetes_deployment" "www-at-jhord-grpc" {
  metadata {
    name = "www-at-jhord-grpc"
    labels = {
      app = "www-at-jhord-grpc"
    }
  }
  spec {
    replicas = 2
    selector {
      match_labels = {
        app = "www-at-jhord-grpc"
      }
    }
    template {
      metadata {
        labels = {
          app = "www-at-jhord-grpc"
        }
      }
      spec {
        container {
          name  = "www"
          image = "registry.digitalocean.com/${var.docker_registry}/www-at-jhord-grpc:v0.0.18"
          port {
            container_port = 5000
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "www-at-jhord-grpc" {
  metadata {
    name = "www-at-jhord-grpc"
  }
  spec {
    selector = {
      app = kubernetes_deployment.www-at-jhord-grpc.spec.0.template.0.metadata[0].labels.app
    }
    port {
      port        = 5000
      target_port = 5000
    }
    type = "NodePort"
  }
}

resource "kubernetes_ingress" "www" {
  metadata {
    name = "www"
    annotations = {
      "kubernetes.io/ingress.class" = "nginx"
      "nginx.ingress.kubernetes.io/use-regex" = "true"
      "nginx.ingress.kubernetes.io/rewrite-target" = "/$2"
      "nginx.ingress.kubernetes.io/from-to-www-redirect" = "true"
      "service.beta.kubernetes.io/do-loadbalancer-hostname" = "${var.k8s_host}.${data.digitalocean_domain.carbon-cc.name}"
      "service.beta.kubernetes.io/do-loadbalancer-redirect-http-to-https" = "true"
      "service.beta.kubernetes.io/do-loadbalancer-healthcheck-port" = "80"
      "service.beta.kubernetes.io/do-loadbalancer-healthcheck-protocol" = "http"
      "service.beta.kubernetes.io/do-loadbalancer-healthcheck-path" = "/healthz"
      "service.beta.kubernetes.io/do-loadbalancer-healthcheck-check-interval-seconds" = "3"
      "service.beta.kubernetes.io/do-loadbalancer-healthcheck-response-timeout-seconds" = "5"
      "service.beta.kubernetes.io/do-loadbalancer-healthcheck-unhealthy-threshold" = "3"
      "service.beta.kubernetes.io/do-loadbalancer-healthcheck-healthy-threshold" = "5"
    }
  }
  spec {
    rule {
      host = "${var.k8s_host}.${data.digitalocean_domain.carbon-cc.name}"
      http {

        path {
          path = "/@jhord(/|$)(.*)"
          backend {
            service_name = "www-at-jhord-http"
            service_port = 80
          }
        }
        path {
          path = "/()(.*)"
          backend {
            service_name = "www-carbon-cc"
            service_port = 80
          }
        }

      }
    }
  }
}

resource "digitalocean_record" "staging" {
  domain = data.digitalocean_domain.carbon-cc.name
  type   = "A"
  name   = var.k8s_host
  value  = kubernetes_ingress.www.load_balancer_ingress[0].ip
}
