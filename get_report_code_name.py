
import os
from urllib.parse import urlparse

uri = os.environ['REPORT_REPO_URL']
result = urlparse(uri)
path = result.path
git_path = path.split("/")
git_name = git_path[2]
print(git_name)