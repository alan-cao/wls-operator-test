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

# create weblogic credential
$WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-weblogic-domain-credentials/create-weblogic-credentials.sh \
  -u weblogic -p welcome1 -n $TEST_DOMAIN_NS -d $TEST_DOMAIN


# create RCU credentials
$WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-rcu-credentials/create-rcu-credentials.sh -a sys -q Oradoc_db1 -u ${TEST_DOMAIN} -p welcome1 -d ${TEST_DOMAIN} -s ${TEST_DOMAIN}-rcu-credentials -n ${TEST_DOMAIN_NS}


cp $WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-fmw-infrastructure-domain/create-domain-inputs.yaml ${TEST_DIR}/${TEST_DOMAIN}.yaml

sed -i -e "s/namespace: default/namespace: ${TEST_DOMAIN_NS}/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s/domainUID: domain1/domainUID: ${TEST_DOMAIN}/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s/weblogicCredentialsSecretName: domain1-weblogic-credentials/weblogicCredentialsSecretName: ${TEST_DOMAIN}-weblogic-credentials/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s/persistentVolumeClaimName: domain1-weblogic-sample-pvc/persistentVolumeClaimName: weblogic-sample-pvc/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s/domain1/${TEST_DOMAIN}/g" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s;database:1521/service;database.database-namespace:1521/orclpdb.us.oracle.com;" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s;oracle/fmw-infrastructure:12.2.1.3;oracle/fmw-infrastructure:12213-update-k8s;" ${TEST_DIR}/${TEST_DOMAIN}.yaml
sed -i -e "s;exposeAdminNodePort: false;exposeAdminNodePort: true;" ${TEST_DIR}/${TEST_DOMAIN}.yaml

#debug 29683926
sed -i -e "s;createDomainScriptsMountPath: /u01/weblogic;createDomainScriptsMountPath: /u01/weblogic11;" ${TEST_DIR}/${TEST_DOMAIN}.yaml

$WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-fmw-infrastructure-domain/create-domain.sh -i ${TEST_DIR}/${TEST_DOMAIN}.yaml -o $TEST_DIR/directory -e


kubectl describe domain $TEST_DOMAIN -n $TEST_DOMAIN_NS 

kubectl get pod -n $TEST_DOMAIN_NS 

kubectl get svc -n $TEST_DOMAIN_NS


helm install ${WLS_OPERATOR_HOME}/kubernetes/samples/charts/ingress-per-domain \
  --name ${TEST_DOMAIN}-ingress \
  --namespace ${TEST_DOMAIN_NS} \
  --set wlsDomain.domainUID=${TEST_DOMAIN} \
  --set traefik.hostname=${TEST_DOMAIN}.org


kubectl get pod -n $TEST_DOMAIN_NS

