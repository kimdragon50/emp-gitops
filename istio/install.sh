## 1.9.2 version
curl -sL https://istio.io/downloadIstioctl | sh -
export PATH=$PATH:$HOME/.istioctl/bin
istioctl version


## istio operator yaml
istioctl install -f istio_values.yaml