#!/bin/bash

mkdir -p .awsprice
CACHE_PERIOD=86400

# API_REGION is the AWS region where the API requests will be directed. It's *not* the region 
# corresponding to where the prices belong! (we only use Ireland)
API_REGION="us-east-1"

# Function to get the on-demand price of an EC2 instance.
# This function takes the instance type as an argument.
function get_ondemand_price {

    instance_type=$1

    # Use the AWS Pricing API to fetch the on-demand price.
    # Filters are applied to match the specific instance type, location, operating system, etc.
    # The jq command is used to parse the JSON output and extract the relevant pricing information.
    price=$(aws pricing get-products --profile $AWS_PROFILE --service-code AmazonEC2 --filters \
    'Type=TERM_MATCH,Field=instanceType,Value='\"$instance_type\"'' \
    'Type=TERM_MATCH,Field=location,Value="EU (Ireland)"' \
    'Type=TERM_MATCH,Field=operatingSystem,Value="Linux"' \
    'Type=TERM_MATCH,Field=preInstalledSw,Value=NA' \
    'Type=TERM_MATCH,Field=tenancy,Value=Shared' \
    'Type=TERM_MATCH,Field=capacitystatus,Value=Used' \
    --region "$API_REGION" | \
    jq -r '.PriceList[] | fromjson | .terms.OnDemand[] | .priceDimensions[] | .pricePerUnit.USD')

    echo $price
}

# Function to get the spot price of an EC2 instance.
# This function takes the instance type as an argument.
function get_spot_price {

    instance_type=$1

    # Use the AWS EC2 API to fetch the latest spot price history for the specified instance type.
    # The command gets the spot price history starting from the current time.
    # The jq command calculates the average of the returned spot prices.
    price=$(aws ec2 describe-spot-price-history --profile $AWS_PROFILE  \
        --product-descriptions "Linux/UNIX" \
        --instance-types "$instance_type" \
        --start-time $(date -u +"%Y-%m-%dT%H:%M:%S") \
        --region eu-west-1 \
        --query 'SpotPriceHistory[*]' | jq  '[.[].SpotPrice | tonumber] | add/length')

    echo $price
}

# Function to get the price of an EC2 instance under an instance saving plan.
# This function takes the instance type and lease contract length as arguments.
function get_instancesavingplans_price {

    instance_type=$1
    lease_contract_length=$2

    # Use the AWS Pricing API to fetch the price for instance saving plans.
    # Filters are applied to match the specific instance type, location, operating system, lease contract length, etc.
    price=$(aws pricing get-products --profile $AWS_PROFILE --service-code AmazonEC2 --filters \
        'Type=TERM_MATCH,Field=instanceType,Value='\"$instance_type\"'' \
        'Type=TERM_MATCH,Field=location,Value="EU (Ireland)"' \
        'Type=TERM_MATCH,Field=operatingSystem,Value=Linux' \
        'Type=TERM_MATCH,Field=preInstalledSw,Value=NA' \
        'Type=TERM_MATCH,Field=tenancy,Value=Shared' \
        'Type=TERM_MATCH,Field=leaseContractLength,Value='\"$lease_contract_length\"'' \
        'Type=TERM_MATCH,Field=purchaseOption,Value="No Upfront"' \
        'Type=TERM_MATCH,Field=offeringClass,Value=standard' \
        --region "$API_REGION" | \
        jq -r '.PriceList[] | fromjson | select(.terms.Reserved != null) | .terms.Reserved[] | select(.termAttributes.LeaseContractLength == '\"$lease_contract_length\"' and .termAttributes.PurchaseOption == "No Upfront" and .termAttributes.OfferingClass == "standard") | .priceDimensions[] | select(.unit == "Hrs") | .pricePerUnit.USD')

    echo $price
}

function help {
    echo "Use this script to fetch the per hour price of AWS instances, for spot, on demand or instance saving plans"
    echo "usage: awsprice.sh -h -p [AWS_PROFILE_NAME] -i [INSTANCE_TYPE] -l [LEASE_PLAN]"
    echo "       [AWS_PROFILE_NAME]: (Optional) an AWS profile name, that had access to the pricing API."
    echo "       [INSTANCE_TYPE]: an instance description, for example \"c6a.4xlarge\""
    echo "       [LEASE_PLAN]: Can be \"ondemand\", \"1yr\", \"3yr\" or \"spot\""
    exit
}

# Script entry point

AWS_PROFILE=""
INSTANCE_TYPE=""
LEASE_PLAN=""

while getopts “p:i:l:h” opt; do
  case $opt in
    h) help ;;
    p) AWS_PROFILE=$OPTARG
       ;;
    i) INSTANCE_TYPE=$OPTARG
       ;;
    l) LEASE_PLAN=$OPTARG 
       ;;
  esac
done

if [ "$INSTANCE_TYPE" == "" ]; then
    help
fi

if [ "$LEASE_PLAN" == "" ]; then
    help
fi

if [ "$AWS_PROFILE" == "" ]; then
    help
fi


#echo "Will get price using profile \"$AWS_PROFILE\" for \"$INSTANCE_TYPE\" using lease plan \"$LEASE_PLAN\"" >&2

CACHE_FILE=".awsprice/${LEASE_PLAN}-${INSTANCE_TYPE}"

price=""

if [ -f $CACHE_FILE ]; then
    modified=$(ls -l -D "%s" "$CACHE_FILE" | awk '{print $6}')
    now=$(date +%s)
    delta=$(($now-$modified))
    if [ $delta -lt $CACHE_PERIOD ]; then
        #echo "Will use cached data" >&2
        price=$(cat $CACHE_FILE)
    fi
fi

if [ "$price" == "" ]; then
    # Main logic to determine which pricing information to fetch based on the user input.
    # The script supports different pricing types: ondemand, 1yr, 3yr, and spot.
    case $LEASE_PLAN in
        ondemand)
            price=$(get_ondemand_price "$INSTANCE_TYPE")
            ;;
        1yr)
            price=$(get_instancesavingplans_price "$INSTANCE_TYPE" "$LEASE_PLAN")
            ;;
        3yr)
            price=$(get_instancesavingplans_price "$INSTANCE_TYPE" "$LEASE_PLAN")
            ;;
        spot)
            price=$(get_spot_price "$INSTANCE_TYPE")
            ;;
        *)
            price=0
        esac
        echo $price > $CACHE_FILE
fi

echo $price