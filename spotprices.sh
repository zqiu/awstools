REGIONS=("us-east-1" "us-east-2" "us-west-1" "us-west-2" "ap-south-1" "ap-northeast-1" "ap-northeast-2" "ap-northeast-3" "ca-central-1" "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3" "eu-north-1")
INSTANCES="c6a.4xlarge c6i.4xlarge c6id.4xlarge c6in.4xlarge c7g.4xlarge"
INSTANCES2X="c6a.2xlarge c6i.2xlarge c6id.2xlarge c6in.2xlarge c7g.2xlarge"
INSTANCEARRAY=($INSTANCES)
INSTANCEARRAY2X=($INSTANCES2X)
QUOTE="'"

rm 4xlarge
rm 2xlarge
rm combined
rm combined2x

for i in ${REGIONS[@]}; do
	echo getting $i
	aws --region=$i ec2 describe-spot-price-history --instance-types $INSTANCES --start-time=$(date +%s) --product-descriptions="Linux/UNIX"  --query 'SpotPriceHistory[*].{az:AvailabilityZone, price:SpotPrice, type:InstanceType}' >> 4xlarge
	aws --region=$i ec2 describe-spot-price-history --instance-types $INSTANCES2X --start-time=$(date +%s) --product-descriptions="Linux/UNIX"  --query 'SpotPriceHistory[*].{az:AvailabilityZone, price:SpotPrice, type:InstanceType}' >> 2xlarge
done

#combine all data
cat 4xlarge | jq -s 'add' > combined
cat 2xlarge | jq -s 'add' > combined2x
#get global min
echo "global min"
cat combined | jq -c 'min_by(.price)'
cat combined2x | jq -c 'min_by(.price)'

#get min by instance type
for i in ${INSTANCES[@]}; do
	echo $i "min"
	command="jq -c ${QUOTE}map(select( .type == \"${i}\")) | min_by(.price)${QUOTE}"
	cat combined | eval $command
done

for i in ${INSTANCES2X[@]}; do
	echo $i "min"
	command="jq -c ${QUOTE}map(select( .type == \"${i}\")) | min_by(.price)${QUOTE}"
	cat combined2x | eval $command
done