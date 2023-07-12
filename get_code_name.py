#!/usr/bin/python

import os
from urllib.parse import urlparse

uri = os.environ['CODE_REPO_URL']
result = urlparse(uri)
path = result.path
user_path = path.split("/")
code_name = user_path[1]
code_name_clean=code_name.split(".")[0]
print(code_name_clean)