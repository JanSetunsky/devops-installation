/bin/bash install_kubernetes_cluster.sh
sleep 200
/bin/bash install_helm.sh
/bin/bash install_kubernetes_prometheus.sh
/bin/bash install_kubernetes_grafana.sh
/bin/bash install_kubernetes_jenkins_master.sh
/bin/bash install_kubernetes_jenkins_agents.sh
/bin/bash install_kubernetes_elastic.sh
