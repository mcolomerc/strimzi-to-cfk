#!/bin/sh

echo "Generate a CA pair to use:"

openssl genrsa -out ca-key.pem 2048

openssl req -new -key ca-key.pem -x509 \
  -days 1000 \
  -out ca.pem \
  -subj "/C=US/ST=CA/L=MountainView/O=Confluent/OU=Operator/CN=TestCA"

echo "Create a Kubernetes secret for the certificate authority:"

kubectl create secret tls ca-pair-sslcerts --cert=ca.pem --key=ca-key.pem -n confluent