
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

```bash
# Or you can pull the images and re-tag
docker pull yulongtsao/fmw-infrastructure:12213-update-k8s
docker pull yulongtsao/fmw-infrastructure:12.2.1.3

docker tag yulongtsao/fmw-infrastructure:12213-update-k8s oracle/fmw-infrastructure:12213-update-k8s
docker tag yulongtsao/fmw-infrastructure:12.2.1.3 oracle/fmw-infrastructure:12.2.1.3
```

### Install database
```bash
docker pull container-registry.oracle.com/database/enterprise:12.2.0.1-slim
docker pull store/oracle/database-instantclient:12.2.0.1

kubectl create namespace database-namespace
kubectl apply -f [scripts/my-database.yaml](./scripts/my-database.yaml)
```
***Database default sys password: Oradoc_db1***

***Database URL database.database-namespace:1521/orclpdb.us.oracle.com***
Please see https://github.com/oracle/weblogic-kubernetes-operator/blob/release/2.2/docs-source/content/userguide/overview/database.md

### Run RCU to Prepare DB Schemas ###
Please see https://github.com/oracle/weblogic-kubernetes-operator/blob/release/2.2/docs-source/content/userguide/managing-domains/fmw-infra/_index.md

#### 1. Start a RCU POD ####
```bash
kubectl run --generator=run-pod/v1 rcu -ti --image oracle/fmw-infrastructure:12.2.1.3 -- sleep 100000
```
#### 2. Connect to the POD to Execute Commands ####
The RCU pod uses FMW docker image, 

Connect to rcu pod
```bash
kubectl exec -ti rcu /bin/bash
```

./oracle_common/bin/rcu -silent -createRepository -databaseType ORACLE -connectString database.database-***namespace.svc.cluster.local:1521/orclpdb.us.oracle.com*** -dbUser sys -dbRole sysdba -useSamePasswordForAllSchemaUsers true -schemaPrefix ***fmwdomain***  -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component  OPSS -component  WLS -component STB

For domain creation script uses domain name as schema prefix. So please select proper value for RCU run.

You will be asked for sys password (***Oradoc_db1***), and schema passwords.

Similarly, schemas can be dropped with RCU:

./oracle_common/bin/rcu -silent ***-dropRepository*** -databaseType ORACLE -connectString ***database.database-namespace.svc.cluster.local:1521/orclpdb.us.oracle.com*** -dbUser sys -dbRole sysdba -schemaPrefix ***fmwdomain***  -component MDS -component IAU -component IAU_APPEND -component IAU_VIEWER -component  OPSS -component  WLS -component STB

#### 3. Stop the RCU POD ####
```bash
kubectl delete pod rcu
```
### Configure FMW Domain ###
Copy set-env.sh-template set-fmw-env.sh
Edit set-fmw-env.sh
source set-fmw-env.sh

#### 1. Prepare Persistent Volume ####
Create directory for PV as defined in set-fmw-env.sh
. [create-pv-pvc.sh](./scripts/create-pv-pvc)

#### 2. Prepare Operator ####
. [config-operator.sh](./scripts/config-operator.sh)

#### 3. Create Domain ####
Will use DB schema created previous. The schema prefix is same as domain name.

. [config-fmw-domain.sh](./scripts/config-fmw-domain.sh)

## References
- https://oracle.github.io/weblogic-kubernetes-operator/quickstart/
- https://oracle.github.io/weblogic-kubernetes-operator/developerguide/building/
