# Octant Dashboard turnkey Docker image and Helm deployment files

This repository provides ready-to-use Helm deployment files and a Docker image
to deploy the [Octant](https://octant.dev/) tool in your Kubernetes cluster in
a read-only manner.

## This is a fork of [aleveille/octant-dashboard-turnkey](https://github.com/aleveille/octant-dashboard-turnkey)

Changes with upstream:

 - Uses oauth2-proxy instead of keycloak-gatekeeper.
 - Upgrade octant version (0.25.0 to 0.25.1).
 - Docker image for both ARM64 and AMD64 platforms.

## What is Octant

From the [Octant GitHub repository](https://github.com/vmware-tanzu/octant):

> A highly extensible platform for developers to better understand the complexity of Kubernetes clusters.

Octant is a tool for developers to understand how applications run on a Kubernetes cluster. It aims to be part of the developer's toolkit for gaining insight and approaching complexity found in Kubernetes. Octant offers a combination of introspective tooling, cluster navigation, and object management along with a plugin system to further extend its capabilities.

## The purpose of this repo

I like Octant, but sometimes giving Kubectl config to your developers isn't
feasible or practical (for various reasons, which is another discussion
altogether!).

So I figured I could deploy octant in as a read-only dashboard alternative to
the official Kubernetes dashboard. This repository is me open-sourcing and
sharing my deployment configuration. I often use Keycloak Gatekeeper as an SSO
proxy to various application and this Helm deployment chart supports enabling
Gatekeeper as an SSO proxy to Octant.

Effectively, using this repo you can:
* Install Octant as read-only in your Kubernetes cluster(s)
* Protect that dashboard with SSO

## Installing with Helm

First, add the Helm chart repository (provided through GitHub Pages with the help of [Chart Releaser](https://github.com/helm/chart-releaser))

```
helm repo add octant-dashboard https://sintef.github.io/octant-dashboard-turnkey/repo
```

Then install the chart:

```
helm upgrade octant-dashboard octant-dashboard/octant --namespace octant  --install --values myValues.yaml
```

Here's a sample Helm value file compatible with [External DNS](https://github.com/kubernetes-sigs/external-dns), [NGINX Ingress Controller](https://kubernetes.github.io/ingress-nginx/)
and that assumes you are terminating SSL somewhere upstream. By default, this chart will have Octant listens on port `8000` (service & pod). There's also a way to give Octant more cluster role rules in order to list custom resources that aren't
already part of this chart (in the values files below you can see an example to whitelist *everything*).

```
#imagePullSecrets:
#- name: someSecret

oauth2-proxy:
  enabled: true
  config:
    clientID: octantClientId
    clientSecret: 123e4567-e89b-12d3-a456-426655440000
    cookieSecret: 0123456789abcdef
    configFile: |
        provider = "keycloak-oidc"
        skip_provider_button = true
        redirect_url = "https://octant.example.net/oauth2/callback"
        oidc_issuer_url = "https://keycloak.example.net/auth/realms/master"
        reverse_proxy = true
        upstreams = ["http://octant:8000/"]
  ingress:
    enabled: true
    annotations:
      kubernetes.io/ingress.class: nginx
      external-dns.alpha.kubernetes.io/target: octant.example.net.
    hosts:
      - host: octant.example.net
        paths:
        - path: /
          pathType: ImplementationSpecific
    tls: []

clusterRole:
  rules:
  - apiGroups:
    - "*"
    resources: ["*"]
    verbs:
    - get
    - list
    - watch
```


## Contributing or asking for features

While this repo is heavily inspired by my deployments of Octant and how I deploy
it, I'm happy to improve it if you have different needs (eg: other SSO proxies
or non-read-only deployments). Just open a GitHub issue and I'll see if I can
support your use-case.
