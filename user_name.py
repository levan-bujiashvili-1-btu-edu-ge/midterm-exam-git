#!/usr/bin/python

import os
from urllib.parse import urlparse

uri = os.environ['CODE_REPO_URL']
result = urlparse(uri)
path = result.path
user_path = path.split("/")
user_name = user_path[1]
print(user_name)
 