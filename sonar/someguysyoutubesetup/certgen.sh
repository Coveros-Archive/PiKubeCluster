mkdir $HOME/certs
cd $HOME/certs
openssl genrsa -out dashboard.key 2048
openssl rsa -in dashboard.key -out dashboard.key
openssl req -sha256 -new -key dashboard.key -out dashboard.csr -subj '/CN=dashboard'
openssl x509 -req -sha256 -days 365 -in dashboard.csr -signkey dashboard.key -out dashboard.crt
kubectl -n kube-system create secret generic kubernetes-dashboard-certs --from-file=$HOME/certs
# Return to dashboard directory
kubectl create -f dashboard.yaml -f dashboard-user.yaml

kubectl -n kubernetes-dashboard describe secret $(kubectl -n kubernetes-dashboard get secret | grep admin-user| awk '{print $1}')

