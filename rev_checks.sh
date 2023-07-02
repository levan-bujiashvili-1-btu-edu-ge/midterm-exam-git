#!/bin/bash
TESTED_REVISIONS=()

while true
do
for i in ${REV_LIST[@]}; do

git switch --detach $i
TESTED_REVISIONS+=("$i")
pytest -v
PYTEST_RESULT="$(pytest -v)"
echo "pytest result: $PYTEST_RESULT"

done
echo "$TESTED_REVISIONS"
done