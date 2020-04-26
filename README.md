# k8s-node-backdoor

Main goal af this repo: going through architecture of infra setups for application.
-----------------------------------------------------------------------------------

## Application

Tooling for providing admin backdoor to k8s node. Should help k8s administrator w/
debugging, troubleshooting, monitoring operations in k8s cluster, which has not got
Logging/Monitoring/Alerting configuration or its broken by some reason.


## Architecture

### Why golang?

Shortly:
It's pretty easy to operate w/ binaries while you decide to follow microservice architecture.
Packing code into binaries, moving it inside containers and run over the container orchestrator

### Why binaries?

Shortly:
User can operate that binary w/o installation tons of dependencies. Just `wget` to your local machine and run.
Simple. From the other hand you may pack binaries in containers and run as cloud-native app.

### Why containers?

Shortly:
Get rid of all dependencies, you need only docker. Own safe sandbox with separate cgroups/namespaces for your experiments.
Check applicaition against multiple Operation Systems. Ability to run application in microservices-way. Containers is the best way
to build/test go binaries as well, you don't need to manage complicated go-infra on your CI/CD system

### Why microservices?

Shortly:
Cloud-native applications should be as much agile as possible and have ability to reflect to all code
changes quickly. When your applocation consists of thousands of pieces, it's easier to
change small parts and monitor whole service reflection. It's easier to debug application because each microservice
was developed to perform single, strictly defined goal. It's easier to perform upgrade procedures as well.

### Why Kubernetes?

Shortly:
Best container orchestration system at the current moment (26.04.2020).
- Pretty easy to implement Logging/Monitoring
- Actively develops
- CRD's for application customization
- Simple declarative way to rollout all k8s-objects
- Api customizable
- Customization of cri(docker, containerd), cni(calico, weave), csi(cloud-providers drivers, like cinder csi for OS cloud) interfaces

### Why K8s daemonset?

Shortly:
K8s has several sane-default object for applications. Daemonset is one of them (also we can use Deployment, Statefulset, etc..).
Advantages of k8s Daemonset:
- Automatic scaling in case of k8s cluster node amount change
- Upgrade supporting
- Shared pvc, because application is stateless

### Why Makefile?

Shortly:
Aggegating all logic, needed to build/test/promote apllication in one place in form of simple shell scripts, allows you:
- Simplify development process, ypu may run make targets from your local machine
- Simplify CICD integration, pipelines will use the same make targets to reduce code duplicationg and possible differencies between local development and CI support.
- Trasfer from one CICD system to another is greatly facilitated, because all depedencies and logic hidden in project itslef, not in infra code.

### Why CICD?

Shortly:
Simplify development/testing/promoting processes, reduce human-related errors. Basically it's useless question in 2020.
