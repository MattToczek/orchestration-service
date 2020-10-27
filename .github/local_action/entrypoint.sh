#!/bin/bash -vx

#set +x

# sets TAGS as an array
IFS=', ' read -r -a TAGS <<< "$2"
# sets TAG_MAP value
TAG_MAP="$4"
# sets GHTOKEN
GHTOKEN="$1"
# sets path to terraform dir
TERRAFORM_DIR="$3"
config_file=/tmp/.tflint.hcl


function create_config_file {
  echo "rule aws_resource_missing_tags {" > ${config_file}
  echo "  enabled = true" >> ${config_file}
  echo "  tags    = [$(for i in "${TAGS[@]}"; do echo -n "\"${i}\", "; done)]" >> ${config_file}
  echo "}"  >> ${config_file}
  cat ${config_file}
}


function find_missing_tags {
  sections=($(tflint -f json --force --disable-rule=aws_cloudwatch_log_group_invalid_name --config=${1} ${2} | jq -c '.issues[] | "\(.rule.name),\(.range.filename),\(.range.start.line)"' | tr '\n' ' ' | sed 's/"//g'))
  touch ./comment.txt
  for i in ${sections[@]}; do
    lineNumber=$(echo ${i} | cut -d ',' -f 3)
    fileName=$(echo ${i} | cut -d ',' -f 2)
    ruleName=$(echo ${i} | cut -d ',' -f 1)
    tag_count=0
    tag_map_count=0
    dynamic_block=$(sed -n "${lineNumber},/^}/p" ${fileName} | sed '/dynamic/,$!d')
    if [ ${#dynamic_block} -gt 0 ]; then
      for tag in ${TAGS[@]}; do
        echo "$dynamic_block" | grep $tag
        if [ ! $? -eq 0 ]; then
          tag_count+=1
          echo "tag_count: ${tag_count}"
        fi
      done
      echo "$dynamic_block" | grep $TAG_MAP
      if [ ! $? -eq 0 ]; then
        tag_map_count+=1
        echo "tag_map_count: ${tag_map_count}"
      fi;

      if [ ! $tag_count -eq 0 ] && [ ! $tag_map_count -eq 0 ]; then
        message+="ISSUE FOUND: $ruleName in $fileName line ${lineNumber}¡"
      fi
      tag_count=0
      tag_map_count=0
      else message+="ISSUE FOUND: $ruleName in $fileName line ${lineNumber}¡"
    fi;
  done

  IFS='¡' read -r -a message_array <<< "$message"
  if [ "${message}" ]; then
    echo "***ISSUE(S) FOUND IN ${2}***:" >> ./comment.txt
    echo "\`\`\`" >> ./comment.txt;
    for i in "${message_array[@]}"
      do echo $i >> ./comment.txt
    done
    echo "\`\`\`" >> ./comment.txt
  fi
  echo "message: ${message}"
  unset message
  unset message_array
}


function post_comment {
  if [ $(wc -l comment.txt | awk '{print 1}') -gt 0 ]; then
    pr_number=$(IFS='/' read -r -a split <<< "${GITHUB_REF}"; echo "${split[2]}")
    body=$(cat comment.txt)
    curl -s -H "Authorization: token ${GHTOKEN}" \
    -X POST -d '{"body": "'"${body//$'\n'/'\n'}"'"}' \
    "https://api.github.com/repos/${GITHUB_REPOSITORY}/issues/${pr_number}/comments"
  fi
}


create_config_file
find_missing_tags ${config_file} ${TERRAFORM_DIR}
for d in $(find "${TERRAFORM_DIR}/" -type d); do find_missing_tags ${config_file} ${d}; done
post_comment
rm comment.txt
