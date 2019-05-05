TEST_DIR=./outputs

cp $WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc/create-pv-pvc-inputs.yaml ${TEST_DIR}/

sed -i -e "s;#weblogicDomainStoragePath: /scratch/k8s_dir;weblogicDomainStoragePath: ${WEBLOGIC_PV_PATH} ;" ${TEST_DIR}/create-pv-pvc-inputs.yaml

$WLS_OPERATOR_HOME/kubernetes/samples/scripts/create-weblogic-domain-pv-pvc/create-pv-pvc.sh   -i ${TEST_DIR}/create-pv-pvc-inputs.yaml  -o $TEST_DIR  -e

# verify the result
kubectl describe pv weblogic-sample-pv

