TEST_DOMAIN_NS=${TEST_DOMAIN}-ns
TEST_DIR=./outputs

mkdir $TEST_DIR

echo $TEST_DOMAIN
echo $TEST_DOMAIN_NS
kubectl create namespace $TEST_DOMAIN_NS

helm upgrade \
  --reuse-values \
  --set "domainNamespaces={${TEST_DOMAIN_NS}}" \
  --wait \
  sample-weblogic-operator \
  ${WLS_OPERATOR_HOME}/kubernetes/charts/weblogic-operator


helm upgrade \
  --reuse-values \
  --set "kubernetes.namespaces={traefik,${TEST_DOMAIN_NS}}" \
  --wait \
  traefik-operator \
  stable/traefik


$WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-weblogic-domain-credentials/create-weblogic-credentials.sh \
  -u weblogic -p welcome1 -n $TEST_DOMAIN_NS -d $TEST_DOMAIN


cp $WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-weblogic-domain/domain-home-in-image/create-domain-inputs.yaml ${TEST_DIR}/${TEST_DOMAIN}.yaml

sed -i -e "s/namespace: default/namespace: ${TEST_DOMAIN_NS}/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s/domainUID: domain1/domainUID: ${TEST_DOMAIN}/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s/weblogicCredentialsSecretName: domain1-weblogic-credentials/weblogicCredentialsSecretName: ${TEST_DOMAIN}-weblogic-credentials/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml
#sed -i -e "s/#image:/image:yulongtsao\/${TEST_DOMAIN}/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml

echo "running: $WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-weblogic-domain/domain-home-in-image/create-domain.sh -i ${TEST_DIR}/${TEST_DOMAIN}.yaml -o $TEST_DIR/directory -u weblogic -p welcome1 -e"
$WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-weblogic-domain/domain-home-in-image/create-domain.sh -i ${TEST_DIR}/${TEST_DOMAIN}.yaml -o $TEST_DIR/directory -u weblogic -p welcome1 -e


kubectl describe domain $TEST_DOMAIN -n $TEST_DOMAIN_NS 

kubectl get pod -n $TEST_DOMAIN_NS 

kubectl get svc -n $TEST_DOMAIN_NS


helm install ${WLS_OPERATOR_HOME}/kubernetes/samples/charts/ingress-per-domain \
  --name ${TEST_DOMAIN}-ingress \
  --namespace ${TEST_DOMAIN_NS} \
  --set wlsDomain.domainUID=${TEST_DOMAIN} \
  --set traefik.hostname=${TEST_DOMAIN}.org


kubectl get pod -n $TEST_DOMAIN_NS

