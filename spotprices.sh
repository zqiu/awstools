#REGIONS=("us-east-1" "us-east-2" "us-west-1" "us-west-2" "ap-south-1" "ap-northeast-1" "ap-northeast-2" "ap-northeast-3" "ca-central-1" "eu-central-1" "eu-west-1" "eu-west-2" "eu-west-3" "eu-north-1")
REGIONS=("us-east-1" "us-east-2" "us-west-1" "us-west-2")
INSTANCESIZE=("large" "xlarge" "2xlarge" "4xlarge")
INSTANCETYPE=("c6a." "c6i." "c6id." "c6in." "c7g.")
INSTANCES=()
QUOTE="'"

#when adding string as element into array " " is default IFS so will cause addition of multiple elements
#set IFS to something random (,) to ignore
oldIFS=$IFS
IFS=","

#delete any leftover files
rm combined*
rm raw*

#build up array of instance string to pass to AWS command
for i in ${INSTANCESIZE[@]}; do
	tempinstance=( "${INSTANCETYPE[@]/%/$i}" )
	#temp=$(IFS=" " ; echo "${tempinstance[*]}")
	temp=""
	for j in ${INSTANCETYPE[@]};do
		temp+="$j$i "
	done
	INSTANCES+=($temp)
done

#restore IFS so string parsing in AWS command works again
IFS=$oldIFS

#call AWS commands
for i in ${REGIONS[@]}; do
	echo getting $i
	for ((j = 0; j<${#INSTANCES[@]};j++)); do
		aws --region=$i ec2 describe-spot-price-history --start-time=$(date +%s) --product-descriptions="Linux/UNIX" --query "SpotPriceHistory[*].{az:AvailabilityZone, price:SpotPrice, type:InstanceType}" --instance-types ${INSTANCES[$j]} >> raw${INSTANCESIZE[$j]}
	done
done

#combine all data and get global mins
echo "global min"
for i in ${INSTANCESIZE[@]}; do
	cat raw$i | jq -s 'add' > combined$i
	cat combined$i | jq -c 'min_by(.price)'
done

#get min by instance type
for ((i = 0; i<${#INSTANCES[@]};i++)); do
	echo ${INSTANCESIZE[$i]} min
	INSTANCEARRAY=(${INSTANCES[$i]})
	for j in ${INSTANCEARRAY[@]}; do
		command="jq -c ${QUOTE}map(select( .type == \"${j}\")) | min_by(.price)${QUOTE}"
		cat combined${INSTANCESIZE[$i]} | eval $command
	done
done