instance_name=$1
aws_account_id=$2
aws_region=$3
KUBE_NAMESPACE=$4


ROLE_SESSION_NAME="poc-platform-eks-base-$(date +%s)"

aws sts assume-role --role-arn arn:aws:iam::"${aws_account_id}":role/POCTerraformRole --role-session-name "$ROLE_SESSION_NAME" > assumed-role-output.json

export AWS_ACCESS_KEY_ID=$(cat assumed-role-output.json | jq -r ".Credentials.AccessKeyId")
export AWS_SECRET_ACCESS_KEY=$(cat assumed-role-output.json | jq -r ".Credentials.SecretAccessKey")
export AWS_SESSION_TOKEN=$(cat assumed-role-output.json | jq -r ".Credentials.SessionToken")

aws eks update-kubeconfig --name "$instance_name" \
--region "$aws_region" \
--role-arn arn:aws:iam::"${aws_account_id}":role/POCTerraformRole --alias "$instance_name" \
--kubeconfig "~/.kube/config"

# Check if the namespace exists!
if kubectl get namespace "$KUBE_NAMESPACE" &> /dev/null; then
  echo "Namespace '$KUBE_NAMESPACE' already exists."
else
  # Create the namespace
  kubectl create namespace "$KUBE_NAMESPACE"
  echo "Namespace '$KUBE_NAMESPACE' created."
fi


kubectl apply -f dist/kubernetes/deploy.yaml --namespace $KUBE_NAMESPACE