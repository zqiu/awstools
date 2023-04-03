REGIONS=("us-east-1" "us-east-2")
INSTANCES="c6a.4xlarge c6g.4xlarge c6i.4xlarge c7g.4xlarge"

for i in ${REGIONS[@]}; do
	aws --region=${REGIONS[$i]} ec2 describe-spot-price-history --instance-types $INSTANCES --start-time=$(date +%s) --product-descriptions="Linux/UNIX"  --query 'SpotPriceHistory[*].{az:AvailabilityZone, price:SpotPrice, type:InstanceType}'
done