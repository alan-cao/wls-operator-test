
cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: helm-user-cluster-admin-role
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: default
  namespace: kube-system
EOF


#install traefik
helm install stable/traefik \
  --name traefik-operator \
  --namespace traefik \
  --values ${WLS_OPERATOR_HOME}/kubernetes/samples/charts/traefik/values.yaml \
  --set "kubernetes.namespaces={traefik}" \
  --wait


#install the operator

kubectl create namespace sample-weblogic-operator-ns
kubectl create serviceaccount -n sample-weblogic-operator-ns sample-weblogic-operator-sa


helm install ${WLS_OPERATOR_HOME}/kubernetes/charts/weblogic-operator \
  --name sample-weblogic-operator \
  --namespace sample-weblogic-operator-ns \
  --set image=${WEBLOGIC_OPERATOR_IMAGE} \
  --set serviceAccount=sample-weblogic-operator-sa \
  --set "domainNamespaces={}" \
  --wait

kubectl get pods -n sample-weblogic-operator-ns

kubectl logs -n sample-weblogic-operator-ns -c weblogic-operator deployments/weblogic-operator



