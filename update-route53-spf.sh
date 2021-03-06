#!/bin/bash 

# Connect to master SPF record and run spf-tools to convert structure into direct ip addresses and split up as per 240char limit for SPF records
# Will output the required records into $SPFDIR

# Get current path
current_path="$( cd "$( dirname "$0" )" && pwd )"

$current_path/despf.sh spfzero.stackla.net | $current_path/normalize.sh | $current_path/simplify.sh \ | $current_path/mkblocks.sh stackla.net spf | $current_path/xsel.sh

# Take SPF records and convert to valid JSON format for update via AWS Route53

DATE=$(date +%d-%m-%Y)
COMMENT="SPF update - $DATE"
TTL="60"
TYPE="TXT"
SPFDIR="$current_path/spf-records"
FILES="$(ls $SPFDIR)"
ZONEID="Z3LWGOH3KT4VO5"

for f in $FILES

do
SPF="$(cat $SPFDIR/$f | sed 's/"/\\"/g')"
echo $SPF
JSONFILE="$f.json"
echo $f
echo "-------"
cat > $JSONFILE << EOF
{
  "Comment":"$COMMENT",
  "Changes":[
    {
      "Action":"UPSERT",
      "ResourceRecordSet":{
        "ResourceRecords":[
          {
            "Value":"$SPF"
          }
        ],
        "Name":"$f",
        "Type":"$TYPE",
        "TTL":$TTL
      }
    }
  ]
}
EOF

aws route53 change-resource-record-sets --hosted-zone-id "$ZONEID" --change-batch file://$JSONFILE

done
