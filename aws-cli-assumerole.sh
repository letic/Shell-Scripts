#! /bin/bash
#
# Dependencies:
#   MacOS : brew install jq
#   Linux (deb based) : apt install jq
#
# Setup:
#   chmod +x ./aws-cli-assumerole.sh
#
# Execute:
#   source ./aws-cli-assumerole.sh <AWS_ID> [<AWS_ROLE> [<SESSION_NAME>]]
#
# Description:
#   Makes assuming an AWS IAM role (+ exporting new temp keys) easier

AWS_PROFILE="default"
AWS_ROLE="OrganizationAccountAccessRole"

if [ $# -eq 0 ] || [ $# -gt 3 ]; then
  echo "Usage : $0 <AWS_ID> [<AWS_ROLE> <SESSION_NAME>]"
else
  if [ ! -z "$2" ]; then
    AWS_ROLE=$2
  fi
  if [ ! -z "$3" ]; then
    AWS_SESSION_NAME=$3
  else
    AWS_SESSION_NAME="Assume-$1"
  fi

  unset  AWS_SESSION_TOKEN
  export AWS_ACCESS_KEY_ID=$(grep -A2 "\[$AWS_PROFILE\]" ~/.aws/credentials | awk -F"= " '/aws_access_key_id/ {print $2}')
  export AWS_SECRET_ACCESS_KEY=$(grep -A2 "\[$AWS_PROFILE\]" ~/.aws/credentials | awk -F"= " '/aws_secret_access_key/ {print $2}')
  export AWS_REGION=$(grep -A2 "\[$AWS_PROFILE\]" ~/.aws/config | awk -F"= " '/region/ {print $2}')

  TEMP_ROLE=$(aws sts assume-role \
                    --role-arn "arn:aws:iam::$1:role/$AWS_ROLE" \
                    --role-session-name "$AWS_SESSION_NAME")

  echo "Assumed ARN : $(echo $TEMP_ROLE | jq .AssumedRoleUser.Arn | xargs)"

  export AWS_ACCESS_KEY_ID=$(echo $TEMP_ROLE | jq .Credentials.AccessKeyId | xargs)
  export AWS_SECRET_ACCESS_KEY=$(echo $TEMP_ROLE | jq .Credentials.SecretAccessKey | xargs)
  export AWS_SESSION_TOKEN=$(echo $TEMP_ROLE | jq .Credentials.SessionToken | xargs)

  env | grep -i AWS_
fi
