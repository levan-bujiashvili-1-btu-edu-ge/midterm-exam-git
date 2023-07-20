#!/bin/bash
if black --check --diff *.py
then
    BLACK_RESULT_BISECT=$?
    echo "$BLACK_RESULT_BISECT"
else
    BLACK_RESULT_BISECT=$?
    echo "$BLACK_RESULT_BISECT"
fi