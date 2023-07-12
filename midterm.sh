#!/bin/bash

#set -o errexit
#set -o nounset
set -o pipefail

# if [[ "${BASH_TRACE:-0}" == "1" ]]; then
#     set -o xtrace
# fi

cd "$(dirname "$0")"

GITHUB_PERSONAL_ACCESS_TOKEN="$(echo $GITHUB_PERSONAL_ACCESS_TOKEN)"
CODE_REPO_URL=$1
REPOSITORY_BRANCH_CODE=$2
REPORT_REPO_URL=$3
REPOSITORY_BRANCH_REPORT=$4
if [[ -z $GITHUB_PERSONAL_ACCESS_TOKEN ]]

export CODE_REPO_URL
export REPORT_REPO_URL

then read -p "provide your github personal access token!:" GITHUB_PERSONAL_ACCESS_TOKEN
fi

if [[ -z $1 ]]
then read -p "provide your code repo to test it!:" CODE_REPO_URL
fi

if [[ -z $2 ]]
then read -p "provide your code branch to test it!:" REPOSITORY_BRANCH_CODE
fi

if [[ -z $3 ]]
then read -p "provide your report repo to upload results!:" REPORT_REPO_URL
fi

if [[ -z $4 ]]
then read -p "provide your report repo branch to upload results!:" REPOSITORY_BRANCH_REPORT
fi



export CODE_REPO_URL
export REPORT_REPO_URL

REPOSITORY_OWNER_CODE="$(python user_name.py)"
REPOSITORY_NAME_CODE="$(python get_code_name.py)"
REPOSITORY_NAME_REPORT="$(python get_report_code_name.py)"
REPOSITORY_OWNER_REPORT="$(python report_user_name.py)"


if [[ ! -z $1 ]]
then 
    CHECK="$(curl https://api.github.com/repos/${REPOSITORY_OWNER_CODE}/${REPOSITORY_NAME_CODE})"
    RESULT="$(echo $CHECK | jq ".id")"
    if [ "$RESULT" == "null" ];
    then 
        echo "REPO NOT VALID, PLEASE PROVIDE IT AGAIN"
        read -p "provide repo of code that needs testing" CODE_REPO_URL
    else 
        echo "1ST REPO VALIDATED"
    fi
fi

if [[ ! -z $2 ]]
then
    CHECK="$(git ls-remote --heads https://github.com/${REPOSITORY_OWNER_CODE}/${REPOSITORY_NAME_CODE} $2)"
    #echo $CHECK
    if [[ -z $CHECK ]]
    then 
        echo "branch doesnt exist"
        read -p "BRANCH to test!:" REPOSITORY_BRANCH_CODE
    else 
        echo "1st BRANCH VALIDATED"
    fi
fi

if [[ ! -z $3 ]]
then 
    CHECK="$(curl https://api.github.com/repos/${REPOSITORY_OWNER_REPORT}/${REPOSITORY_NAME_REPORT})"
    RESULT="$(echo $CHECK | jq ".id")"
    if [ "$RESULT" == "null" ];
    then 
        echo "REPO NOT VALID, PLEASE PROVIDE IT AGAIN"
        read -p "provide repo for report upload" REPORT_REPO_URL
    else 
        echo "2nd REPO VALIDATED"
    fi
fi

if [[ ! -z $4 ]]
then 
    CHECK="$(git ls-remote --heads https://github.com/${REPOSITORY_OWNER_REPORT}/${REPOSITORY_NAME_REPORT} $4)"
    #echo $CHECK
    if [[ -z $CHECK ]]
    then 
        echo "branch doesnt exist"
        read -p "BRANCH for results!:" REPOSITORY_BRANCH_REPORT
    else 
        echo "2nd BRANCH VALIDATED"
    fi
fi


echo $GITHUB_PERSONAL_ACCESS_TOKEN
echo "code url: $CODE_REPO_URL"
echo "branch name: $REPOSITORY_BRANCH_CODE"
echo "report URL: $REPORT_REPO_URL"
echo "report branch name: $REPOSITORY_BRANCH_REPORT"
echo "repo owner code: $REPOSITORY_OWNER_CODE"

# GITHUB_PERSONAL_ACCESS_TOKEN="$(python get_personal_access_key.py)"

echo "personal access token: $GITHUB_PERSONAL_ACCESS_TOKEN"

echo "REPOSITORY_NAME: $REPOSITORY_NAME_CODE"

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

REPOSITORY_PATH_CODE=$(mktemp --directory)
REPOSITORY_PATH_REPORT=$(mktemp --directory)
PYTEST_REPORT_PATH=$(mktemp)
BLACK_OUTPUT_PATH=$(mktemp)
BLACK_REPORT_PATH=$(mktemp)
REQUEST_PATH=$(mktemp)
PYTEST_RESULT=0
BLACK_RESULT=0
TESTED_REVISIONS=()


function github_api_get_request()
{
    curl --request GET \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        --output "$2" \
        --silent \
        "$1"
        #--dump-header /dev/stderr \
}

function github_post_request()
{
    curl --request POST \
        --header "Accept: application/vnd.github+json" \
        --header "Authorization: Bearer $GITHUB_PERSONAL_ACCESS_TOKEN" \
        --header "X-GitHub-Api-Version: 2022-11-28" \
        --header "Content-Type: application/json" \
        --silent \
        --output "$3" \
        --data-binary "@$2" \
        "$1"
        #--dump-header /dev/stderr \
}

function jq_update()
{
    local IO_PATH=$1
    local TEMP_PATH=$(mktemp)
    shift
    cat $IO_PATH | jq "$@" > $TEMP_PATH
    mv $TEMP_PATH $IO_PATH
}
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "INSTALLING JQ"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
mkdir -p "/usr/local/bin"
curl -L -o /usr/local/bin/jq.exe \
             https://github.com/stedolan/jq/releases/latest/download/jq-win64.exe
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "INSTALLING black"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
pip install black

echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "INSTALLING pytest"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
pip install pytest
pip install pytest-html
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "INSTALLING JQ"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"

echo "CLONING CODE REPO"
git clone $CODE_REPO_URL $REPOSITORY_PATH_CODE
pushd $REPOSITORY_PATH_CODE
git switch $REPOSITORY_BRANCH_CODE

COMMIT_HASH=0
REV_LIST=$(git rev-list HEAD)



while true
do
for i in ${REV_LIST[@]}; do
TESTED_REVISIONS+=("$i")
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
echo "$i"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
git switch --detach $i
COMMIT_HASH=$i

if [[ !" ${TESTED_REVISIONS[*]} " =~ " ${i} " ]]; then
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
for l in ${TESTED_REVISIONS[@]};do
    echo "$l"
done
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"




#echo "COMMIT_HASH $COMMIT_HASH"
#echo "REV_LIST $REV_LIST"
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
AUTHOR_EMAIL=$(git log -n 1 --format="%ae" HEAD)
#echo "AUTHOR EMAIL $AUTHOR_EMAIL"
if pytest --verbose --html=$PYTEST_REPORT_PATH --self-contained-html
then
    PYTEST_RESULT=$?
    echo "PYTEST SUCCEEDED $PYTEST_RESULT"
else
    PYTEST_RESULT=$?
    echo "PYTEST FAILED $PYTEST_RESULT"
fi

echo "\$PYTEST_RESULT = $PYTEST_RESULT \$BLACK_RESULT=$BLACK_RESULT"

if black --check --diff *.py > $BLACK_OUTPUT_PATH
then
    BLACK_RESULT=$?
    echo "BLACK SUCCEEDED $BLACK_RESULT"
else
    BLACK_RESULT=$?
    echo "BLACK FAILED $BLACK_RESULT"
    pip install pygments
    cat $BLACK_OUTPUT_PATH | pygmentize -l diff -f html -O full,style=solarized-light -o $BLACK_REPORT_PATH
fi

echo "\$PYTEST_RESULT = $PYTEST_RESULT \$BLACK_RESULT=$BLACK_RESULT"

popd
echo "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
pwd
git clone git@github.com:${REPOSITORY_OWNER_REPORT}/${REPOSITORY_NAME_REPORT}.git $REPOSITORY_PATH_REPORT

pushd $REPOSITORY_PATH_REPORT

git switch $REPOSITORY_BRANCH_REPORT
REPORT_PATH="${COMMIT_HASH}-$(date +%s)"
mkdir --parents $REPORT_PATH
mv $PYTEST_REPORT_PATH "$REPORT_PATH/pytest.html"
mv $BLACK_REPORT_PATH "$REPORT_PATH/black.html"
git add $REPORT_PATH
git commit -m "$COMMIT_HASH report."
git push

popd

#rm -rf $REPOSITORY_PATH_CODE
rm -rf $REPOSITORY_PATH_REPORT
rm -rf $PYTEST_REPORT_PATH
rm -rf $BLACK_REPORT_PATH

if (( ($PYTEST_RESULT != 0) || ($BLACK_RESULT != 0) ))
then
    echo "++++++++++++++++CHECK USERS++++++++++++++++++"
    AUTHOR_USERNAME=""
    # https://docs.github.com/en/rest/search?apiVersion=2022-11-28#search-users
    RESPONSE_PATH=$(mktemp)
    github_api_get_request "https://api.github.com/search/users?q=$AUTHOR_EMAIL" $RESPONSE_PATH

    TOTAL_USER_COUNT=$(cat $RESPONSE_PATH | jq ".total_count")
    #echo "USER COUNT: $TOTAL_USER_COUNT"
    #echo "TOTAL_USER_COUNT $TOTAL_USER_COUNT"

    if [[ $TOTAL_USER_COUNT == 1 ]]
    then
        USER_JSON=$(cat $RESPONSE_PATH | jq ".items[0]")
        AUTHOR_USERNAME=$(cat $RESPONSE_PATH | jq --raw-output ".items[0].login")
        #echo "AUTHOR USERNAME $AUTHOR_USERNAME"
    fi

    REQUEST_PATH=$(mktemp)
    RESPONSE_PATH=$(mktemp)
    echo "{}" > $REQUEST_PATH
    BODY=""

    BODY+="Automatically generated message
    "
    if (( $PYTEST_RESULT != 0 ))
    then
    BODY+="Pytest report: https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/$REPORT_PATH/pytest.html "
    #echo "Pytest report: https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/$REPORT_PATH/pytest.html "
    BODY+="Black report: https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/$REPORT_PATH/black.html "
    #echo "Black report: https://${REPOSITORY_OWNER}.github.io/${REPOSITORY_NAME_REPORT}/$REPORT_PATH/black.html "

    #echo "BODY $BODY"
    if [[ ! -z $AUTHOR_USERNAME ]]
    then
        jq_update $REQUEST_PATH --arg username "$AUTHOR_USERNAME"  '.assignees = [$username]'
    fi

        if (( $BLACK_RESULT != 0 ))
        then
            TITLE="${COMMIT_HASH::7} failed unit and formatting tests."
            BODY+="${COMMIT_HASH} failed unit and formatting tests.
            "
            jq_update $REQUEST_PATH '.labels = ["ci-pytest", "ci-black"]
            '
        else
            TITLE="${COMMIT_HASH::7} failed unit tests.
            "
            BODY+="${COMMIT_HASH} failed unit tests.
            "
            jq_update $REQUEST_PATH '.labels = ["ci-pytest"]
            '
        fi
    else
        TITLE="${COMMIT_HASH::7} failed formatting test.
        "
        BODY+="${COMMIT_HASH} failed formatting test.
        "
        jq_update $REQUEST_PATH '.labels = ["ci-black"]
        '
    fi
    jq_update $REQUEST_PATH --arg title "$TITLE" '.title = $title'
    jq_update $REQUEST_PATH --arg body  "$BODY"  '.body = $body'
    
    #echo "REQUEST_PATH $REQUEST_PATH"

    # https://docs.github.com/en/rest/issues/issues?apiVersion=2022-11-28#create-an-issue
    github_post_request "https://api.github.com/repos/${REPOSITORY_OWNER_CODE}/${REPOSITORY_NAME_CODE}/issues" $REQUEST_PATH $RESPONSE_PATH
    #cat $REQUEST_PATH
    #cat $RESPONSE_PATH
    cat $RESPONSE_PATH | jq ".html_url"
    
    rm $RESPONSE_PATH
    rm -rf $REQUEST_PATH
else
    git tag $i "$REPOSITORY_NAME_CODE-ci-success"
fi

#echo "nothing"

pushd $REPOSITORY_PATH_CODE
fi
done
sleep 15
done
rm -rf $REPOSITORY_PATH_CODE