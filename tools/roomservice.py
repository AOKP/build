#!/usr/bin/env python
# Copyright (C) 2016, AOKP
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import argparse
import base64
import json
import sys
import os

try:
  # For python3
  import urllib.error
  import urllib.parse
  import urllib.request
except ImportError:
  # For python2
  import imp
  import urllib2
  import urlparse
  urllib = imp.new_module('urllib')
  urllib.error = urllib2
  urllib.parse = urlparse
  urllib.request = urllib2

from xml.etree import ElementTree


parser = argparse.ArgumentParser()
parser.add_argument('-d', '--depsonly', action='store_true')
parser.add_argument('device')

args = parser.parse_args()
depsonly = args.depsonly

mm = ElementTree.Element("manifest")
lm = ElementTree.Element("manifest")

local_manifests = r'.repo/local_manifests'
if not os.path.exists(local_manifests): os.makedirs(local_manifests)

# Hold a copy of the main manifest
try:
    mm = ElementTree.parse(".repo/manifest.xml")
    mm = mm.getroot()
except:
    mm = ElementTree.Element("manifest")


# Hold a copy of local manifest
def load_local_manifest():
  try:
      lm = ElementTree.parse(".repo/local_manifests/roomservice.xml")
      lm = lm.getroot()
      print("Got local manifest")
  except:
      print("Did not get local manifest")
      lm = ElementTree.Element("manifest")

def write_out_local_manifest(manif):
    indent(manif, 0)
    raw_xml = ElementTree.tostring(manif).decode()
    raw_xml = '<?xml version="1.0" encoding="UTF-8"?>\n' + raw_xml

    f = open('.repo/local_manifests/roomservice.xml', 'w')
    f.write(raw_xml)
    f.close()

def is_path_in_manifest(checkpath):
    for defpath in mm.findall("project"):
        if (defpath.get("path") == checkpath):
            print("Path %s is already tracked in default manifest from %s" % (checkpath, defpath.get("name")))
            return True
    for localpath in lm.findall("project"):
        if localpath.get("path") == checkpath:
            print("Path %s is already tracked in local manifest from %s" % (checkpath, localpath.get("name")))
            return True



def add_to_local_manifest(path, name, remote):
    print(path)
    if is_path_in_manifest(path):
        sys.exit()
    else:
        print("Adding %s to track from %s in local manifest" % (path, name))


def get_from_github(device):
        print("Going to fetch %s from AOKP github" % device)
        try:
            authtuple = netrc.netrc().authenticators("api.github.com")

            if authtuple:
                auth_string = ('%s:%s' % (authtuple[0], authtuple[2])).encode()
                githubauth = base64.encodestring(auth_string).decode().replace('\n', '')
            else:
                githubauth = None
        except:
            githubauth = None

        githubreq = urllib.request.Request("https://api.github.com/search/repositories?q=%s+user:AOKP+in:name" % device)
        if githubauth:
            githubreq.add_header("Authorization","Basic %s" % githubauth)

        try:
            result = json.loads(urllib.request.urlopen(githubreq).read().decode())
        except urllib.error.URLError:
            print("Failed to search GitHub")
            sys.exit()
        except ValueError:
            print("Failed to parse return data from GitHub")
            sys.exit()

        for res in result.get('items', []):
            print(res['name'])
            add_to_local_manifest(res['name'].replace("_","/"), res['full_name'], "aokp")

def checkdeps(device):
    load_local_manifest()
    print("Going to check dependencies of %s" % device)

if not depsonly:
    get_from_github(args.device)

checkdeps(args.device)


