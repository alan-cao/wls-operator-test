## Prerequisites:
- **Maven**
- **JDK11** required by Maven pom.xml
- **Docker**
- **WLS Docker Image: https://hub.docker.com/_/oracle-weblogic-server-12c**
- **Oracle Database Image: https://hub.docker.com/_/oracle-database-enterprise-edition**
- **Kubernetes**
- **Helm**
- **Environments** Can use Google cloud

## Build Weblogic Operator
``` bash
mvn clean install
# The dockerfile will install something with yum, which doesn't work for proxy. 
# The workaround so far is to comment out the yum install in dockfile
docker build --build-arg VERSION=2.2 -t weblogic-kubernetes-operator:<TAG> --no-cache=true .
```
**For simplicity, all the instructions below should be executed on K8S Node**

## Create Domain with Domain Home in Docker Image

- Copy [set-env.sh-template](./scripts/set-env.sh-template) to set-env.sh
- Edit set-env.sh
- Set environment varilables: source set-env.sh 
- Configure WLS Operator: . [config-operator.sh](./scripts/config-operator.sh)
- Configure WLS domain: [config-wls-domain.sh](./scripts/config-wls-domain.sh)

### Clean Domain
- . [cleanup-wls-domain.sh](./scripts/cleanup-wls-domain.sh)
- . [cleanup-operator.sh](./scripts/cleanup-operator.sh)

## Create Domain with Domain Home in Persistent Volume

- Create Directory on Kunbertes host machine
- Change the directory mode to 777 (may not be necessary)
- Copy [set-env.sh-template](./scripts/set-env.sh-template) to set-env.sh
- Edit set-env.sh, needs to set WEBLOGIC_PV_PATH pointing to the new directory created
- Set environment varilables: source set-env.sh 
- Create k8s Persistent Volume and Persistent Volume Claim: . [create-pv-pvc.sh](./scripts/create-pv-pvc.sh). This step will create the namespace for WLS domain. As the PV must be created in same namespace as WLS domain
- Configure WLS Operator: . [config-operator.sh](./scripts/config-operator.sh)
- Configure WLS domain: [config-wls-domain-on-pv.sh](./scripts/config-wls-domain-on-pv.sh)

### Clean Domain
- . [cleanup-wls-domain.sh](./scripts/cleanup-wls-domain.sh)
- . [cleanup-operator.sh](./scripts/cleanup-operator.sh)


## Create FMW Domain

### Build FMW Image
See https://github.com/oracle/docker-images/tree/master/OracleFMWInfrastructure
https://github.com/oracle/docker-images/tree/master/OracleFMWInfrastructure/dockerfiles/12.2.1.3
https://github.com/oracle/docker-images/tree/master/OracleFMWInfrastructure/samples/12213-patch-fmw-for-k8s

https://github.com/oracle/weblogic-kubernetes-operator/blob/release/2.2/docs-source/content/userguide/managing-domains/fmw-infra/_index.md


### Install database
docker pull container-registry.oracle.com/database/enterprise:12.2.0.1-slim
docker pull store/oracle/database-instantclient:12.2.0.1

kubectl create namespace database-namespace
kubectl apply -f [scripts/my-database.yaml](./scripts/my-database.yaml)

## References
- https://oracle.github.io/weblogic-kubernetes-operator/quickstart/
- https://oracle.github.io/weblogic-kubernetes-operator/developerguide/building/
