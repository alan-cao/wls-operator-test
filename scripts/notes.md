**Problem:**

0/1 nodes are available: 1 node(s) had taints that the pod didn't tolerate.

***Solution:***

kubectl taint nodes --all node-role.kubernetes.io/master-

***Link:***
https://github.com/kubernetes-sigs/kubespray/issues/2798
