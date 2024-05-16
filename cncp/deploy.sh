 helm uninstall cncp-basic-services
 helm uninstall ddi-components
 helm uninstall cncp-core-components
 kubectl delete -f nginx-ds.yaml
 kubectl delete pvc opensearch-cluster-master-opensearch-cluster-master-0 -n cncp-system
 kubectl delete pvc postgres -n cncp-system
 kubectl delete pvc redis -n cncp-system
 helm install cncp-basic-services ./cncp-basic-services/ --debug
 helm install cncp-core-components ./cncp-core-components/ --debug
 kubectl create -f nginx-ds.yaml
 helm uninstall ddi-components
 helm install ddi-components ./ddi-components/ --debug