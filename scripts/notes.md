**Problem:**

0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.

***Solution:***

kubectl taint nodes --all node-role.kubernetes.io/master-

***Link:***
https://github.com/kubernetes-sigs/kubespray/issues/2798


**Problem:**

Unable to update cni config: No networks found in /etc/cni/net.d

***Solution:***

#re-deploy weave network (in my case)
export kubever=$(kubectl version | base64 | tr -d '\n')
kubectl apply -f "https://cloud.weave.works/k8s/net?k8s-version=$kubever"

***Link:***
https://github.com/kubernetes/kubernetes/issues/54918

**Problem:**
Deleting persistent volume stuck

***Solution:***
manually edited the pv individually and then removing the finalizers


