# ingress-traefik

create traefik ingress which cert-manager tls set up

```hcl
module "lotus_ingress" {
  source = "github.com/linolabx/tfmodules?ref=k8s-ingress-traefik@v0.0.1"

  namespace = "staging"

  app = {
    name = "main-srv"
    port = 8080
  }

  domain = "api.staging.example.com"
  issuer = "letsencrypt-prod"
  tls    = [{
    secret_name = "example-tls"
    hosts       = ["*.staging.example.com", "*.example.com"]
  }]
}
```
