TEST_DOMAIN_NS=$TEST_DOMAIN-ns
TEST_DIR=./outputs

echo $TEST_DOMAIN
echo $TEST_DOMAIN_NS

helm delete --purge ${TEST_DOMAIN}-ingress

$WLS_OPERATOR_HOME/kubernetes/samples/scripts/delete-domain/delete-weblogic-domain-resources.sh -d ${TEST_DOMAIN}

kubectl get pod -n $TEST_DOMAIN_NS 

kubectl get svc -n $TEST_DOMAIN_NS

helm upgrade \
  --reuse-values \
  --set "kubernetes.namespaces={traefik}" \
  --wait \
  traefik-operator \
  stable/traefik

helm upgrade \
  --reuse-values \
  --set "domainNamespaces={}" \
  --wait \
  sample-weblogic-operator \
  $WLS_OPERATOR_HOME/kubernetes/charts/weblogic-operator



kubectl delete namespace $TEST_DOMAIN_NS


