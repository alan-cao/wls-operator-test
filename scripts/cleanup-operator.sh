helm delete --purge sample-weblogic-operator

kubectl delete namespace sample-weblogic-operator-ns

helm delete --purge traefik-operator

kubectl delete namespace traefik
