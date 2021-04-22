#!/usr/bin/env bash

set -eu

# Options
#
# DEPLOY_ENV - Typical name of the deployment we're targetting.
# AWS_DEFAULT_REGION - AWS region we're working in.
# FLAPPY_TIMEOUT - The time for the script to be running for.
# FLAPPY_SLEEP - The time for the subnet to be out for.

: "${DEPLOY_ENV?"We need a DEPLOY_ENV variable set to establish which VPC we're looking at..."}"
: "${AWS_DEFAULT_REGION?"We need a AWS_DEFAULT_REGION variable set to disable the correct set of subnets..."}"

FLAPPY_TIMEOUT=${FLAPPY_TIMEOUT:-300}
FLAPPY_SLEEP=${FLAPPY_SLEEP:-1}

VPC_ID=$(aws ec2 describe-vpcs --filter "Name=tag:Name,Values=${DEPLOY_ENV}" --query 'Vpcs[*].{id:VpcId}' --output text)

echo -e "VPC has been discovered. Using:\n${VPC_ID}"
echo ""

azs[0]="a"
azs[1]="b"
azs[2]="c"

rand=$((RANDOM % 3))
RANDOM_AZ="${AWS_DEFAULT_REGION}${azs[$rand]}"

echo -e "AZ has been randombly chosen. Using:\n${RANDOM_AZ}"
echo ""

SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=${VPC_ID}" "Name=availability-zone,Values=${RANDOM_AZ}" --query 'Subnets[*].[SubnetId]' --output json | jq '. | flatten')

echo -e "SubnetIDs have been discovered. Using:\n${SUBNET_IDS}"
echo ""

NETWORK_ACL_ID=$(aws ec2 describe-network-acls --region "${AWS_DEFAULT_REGION}" --filters "Name=vpc-id,Values=${VPC_ID}" "Name=default,Values=true" --query 'NetworkAcls[*].{id:NetworkAclId}' --output text)

echo -e "Network ACL has been discovered.\nUsing: ${NETWORK_ACL_ID}"
echo ""

CHAOTIC_NETWORK_ACL_ID=$(aws ec2 create-network-acl --vpc-id "${VPC_ID}" --region "${AWS_DEFAULT_REGION}" --tag-specifications "ResourceType=network-acl,Tags=[{Key=chaos,Value=${DEPLOY_ENV}}]" | jq -r '.NetworkAcl.NetworkAclId')

echo -e "New Network ACL has been created.\nUsing: ${CHAOTIC_NETWORK_ACL_ID}"
echo ""

CURRENT_TIME=$(date +%s)
while [ "$(date +%s)" -lt $((CURRENT_TIME+FLAPPY_TIMEOUT)) ]
do
  echo "Associating subnets with chaos ACL..."
  RAW_NETWORK_ACL_ASSOCIATION_IDS=$(aws ec2 describe-network-acls --region "${AWS_DEFAULT_REGION}" --filters "Name=vpc-id,Values=${VPC_ID}" "Name=network-acl-id,Values=${NETWORK_ACL_ID}" --query 'NetworkAcls[*].Associations[*].{id:NetworkAclAssociationId,subnet:SubnetId}' | jq '. | flatten')
  NETWORK_ACL_ASSOCIATION_IDS=$(jq '.[] | select(.subnet | IN($subnets[]))' --argjson subnets "${SUBNET_IDS}" <<< "${RAW_NETWORK_ACL_ASSOCIATION_IDS}" | jq -r .id)
  for NETWORK_ACL_ASSOCIATION_ID in ${NETWORK_ACL_ASSOCIATION_IDS}
  do
    echo "Changing association for ${NETWORK_ACL_ASSOCIATION_ID} to chaos ACL ${CHAOTIC_NETWORK_ACL_ID}"
    aws ec2 replace-network-acl-association --region "${AWS_DEFAULT_REGION}" --association-id "${NETWORK_ACL_ASSOCIATION_ID}" --network-acl-id "${CHAOTIC_NETWORK_ACL_ID}" > /dev/null
  done
  echo ""

  sleep "${FLAPPY_SLEEP}"

  echo "Associating subnets with original ACL..."
  RAW_CHAOS_NETWORK_ACL_ASSOCIATION_IDS=$(aws ec2 describe-network-acls --region "${AWS_DEFAULT_REGION}" --filters "Name=vpc-id,Values=${VPC_ID}" "Name=network-acl-id,Values=${CHAOTIC_NETWORK_ACL_ID}" --query 'NetworkAcls[*].Associations[*].{id:NetworkAclAssociationId,subnet:SubnetId}' | jq '. | flatten')
  CHAOS_NETWORK_ACL_ASSOCIATION_IDS=$(jq '.[] | select(.subnet | IN($subnets[]))' --argjson subnets "${SUBNET_IDS}" <<< "${RAW_CHAOS_NETWORK_ACL_ASSOCIATION_IDS}" | jq -r .id)
  for NETWORK_ACL_ASSOCIATION_ID in ${CHAOS_NETWORK_ACL_ASSOCIATION_IDS}
  do
    echo "Changing association for ${NETWORK_ACL_ASSOCIATION_ID} to chaos ACL ${CHAOTIC_NETWORK_ACL_ID}"
    aws ec2 replace-network-acl-association --region "${AWS_DEFAULT_REGION}" --association-id "${NETWORK_ACL_ASSOCIATION_ID}" --network-acl-id "${NETWORK_ACL_ID}" > /dev/null
  done
  echo ""
done

echo "Done with flappiness..."
echo ""

echo -e "Deleting Network ACL created for chaos testing.\nUsing: ${CHAOTIC_NETWORK_ACL_ID}"
echo ""

aws ec2 delete-network-acl --network-acl-id "${CHAOTIC_NETWORK_ACL_ID}" --region "${AWS_DEFAULT_REGION}" > /dev/null

echo "Done..."
