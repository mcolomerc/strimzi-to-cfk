# Strimzi to Confluent For Kubernetes

**Source**: Strimzi Kafka

**Destination**: Confluent For Kubernetes

## Strimzi Kafka Cluster

1. Install Strimzi Operator

`helm repo add strimzi https://strimzi.io/charts/`

`helm install strimzi-kafka strimzi/strimzi-kafka-operator`

`kubectl get pods -l=name=strimzi-cluster-operator`

`kubectl get crd | grep strimzi`

2. Kafka Deployment

`kubectl apply -f ./strimzi-kafka-deployment/kafka.yaml`

3. Create Topics

`kubectl apply -f ./strimzi-kafka-deployment/topics.yaml`

4. Produce and Consume

```sh
kubectl run kafka-producer -ti \
  --image=quay.io/strimzi/kafka:0.32.0-kafka-3.2.0 \
  --rm=true \
  --restart=Never \
  -- bin/kafka-console-producer.sh \
  --broker-list strimzi-cluster-kafka-bootstrap:9092 \
  --topic topic1
```

```sh
kubectl run kafka-consumer -ti \
  --image=quay.io/strimzi/strimzi/kafka:0.32.0-kafka-3.2.0 \
  --rm=true \
  --restart=Never \
  -- bin/kafka-console-consumer.sh \
  --bootstrap-server strimzi-cluster-kafka-bootstrap:9092 \
  --topic topic1 \
  --from-beginning
```

Optional: Kafka-UI web tool

```sh
helm repo add kafka-ui https://provectus.github.io/kafka-ui 
helm install kafka-ui kafka-ui/kafka-ui --set envs.config.KAFKA_CLUSTERS_0_NAME=strimzi-cluster  --set envs.config.KAFKA_CLUSTERS_0_BOOTSTRAPSERVERS=strimzi-cluster-kafka-bootstrap:9092 --set service.type=LoadBalancer 
```

---

## Confluent For Kubernetes

1. Install Confluent Operator

Create a namespace for the Confluent Operator: `kubectl create namespace confluent`

Deploy with Helm:

`helm repo add confluentinc https://packages.confluent.io/helm`

`helm repo update`

`helm upgrade --install confluent-operator confluentinc/confluent-for-kubernetes --namespace confluent`

2. Create Kafka Cluster, Zookeeper, and control center

Generate a CA pair to use

`openssl genrsa -out ca-key.pem 2048`

```sh
  openssl req -new -key ca-key.pem -x509 \
  -days 1000 \
  -out ca.pem \
  -subj "/C=US/ST=CA/L=MountainView/O=Confluent/OU=Operator/CN=TestCA"
```

Create a Kubernetes secret for the certificate authority:

`kubectl create secret tls ca-pair-sslcerts --cert=ca.pem --key=ca-key.pem -n confluent`

Deployment: 

`kubectl apply -f ./confluent/zookeeper.yaml`

`kubectl apply -f ./confluent/kafka.yaml`

`kubectl apply -f ./confluent/kafkarestclass.yaml`

Control center: 

`kubectl apply -f ./confluent/controlcenter.yaml`

Ingress rule for control center:

`kubectl apply -f ./confluent/ingress.yaml`

3. Get Strimzi Kafka Cluster ID

`kubectl exec strimzi-cluster-kafka-0 -c kafka -- cat /var/lib/kafka/data-0/kafka-log0/meta.properties`

Output:

```properties
broker.id=0
version=0
cluster.id=TIkMCeOOSLaet3sEmUZRfg
```

4. Cluster Linking

Edit and update the cluster ID in `./confluent/cluster-link.yaml`

`kubectl apply -f ./confluent/cluster-link.yaml`

5. Describe Cluster Link

`kubectl get clusterlink clusterlink-cflt -oyaml -n confluent`
