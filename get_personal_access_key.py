#!/usr/bin/python

from dotenv import load_dotenv
from os import getenv
load_dotenv(".env")
PERSONAL_ACCESS_TOKEN = getenv("GITHUB_PERSONAL_ACCESS_TOKEN")
print(PERSONAL_ACCESS_TOKEN)