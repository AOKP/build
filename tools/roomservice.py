#!/usr/bin/env python
# Copyright (C) 2012-16, The CyanogenMod Project
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
import glob

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

ran_checkdeps_on = []

local_manifests = r'.repo/local_manifests'
if not os.path.exists(local_manifests): os.makedirs(local_manifests)

# Hold a copy of the main manifest
try:
    mm = ElementTree.parse(".repo/manifest.xml")
    mm = mm.getroot()
except:
    mm = ElementTree.Element("manifest")

try:
    lm = ElementTree.parse(".repo/local_manifests/roomservice.xml")
    lm = lm.getroot()
    print("Got local manifest")
except:
    print("Did not get local manifest, will create a new one")
    lm = ElementTree.Element("manifest")


# Hold a copy of local manifest
def reload_local_manifest():
  try:
      lm = ElementTree.parse(".repo/local_manifests/roomservice.xml")
      lm = lm.getroot()
      print("Got local manifest")
  except:
      print("Did not get local manifest, will create a new one")
      lm = ElementTree.Element("manifest")

# in-place prettyprint formatter
def indent(elem, level=0):
    i = "\n" + level*"  "
    if len(elem):
        if not elem.text or not elem.text.strip():
            elem.text = i + "  "
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
        for elem in elem:
            indent(elem, level+1)
        if not elem.tail or not elem.tail.strip():
            elem.tail = i
    else:
        if level and (not elem.tail or not elem.tail.strip()):
            elem.tail = i

def write_out_local_manifest(manif):
    indent(manif, 0)
    raw_xml = ElementTree.tostring(manif).decode()
    raw_xml = '<?xml version="1.0" encoding="UTF-8"?>\n' + raw_xml

    f = open('.repo/local_manifests/roomservice.xml', 'w')
    f.write(raw_xml)
    f.close()

def is_path_in_manifest(checkpath, name, remote, branch):
    for defpath in mm.findall("project"):
        if (defpath.get("path") == checkpath):
            # print("Path %s is already tracked in default manifest from %s" % (checkpath, defpath.get("name")))
            return True
    for localpath in lm.findall("project"):
        if (localpath.get("path") == checkpath):
            if ((localpath.get("name") != name) or (localpath.get("remote") != remote) or (localpath.get("branch") != branch)):
                print("Change in dependency : ")
                print("OLD MAP: %s:%s:%s -> %s" % (localpath.get("remote"), localpath.get("name"), 
                    localpath.get("branch"), localpath.get("path")))
                print("NEW MAP: %s:%s:%s -> %s" % (remote, name, branch, checkpath))
                lm.remove(localpath)
                return False

            # print("Path %s is already tracked in local manifest from %s" % (checkpath, localpath.get("name")))
            return True

def reposync(syncrepo):
    os.system('repo sync --force-sync %s' % syncrepo)


def add_to_local_manifest(path, name, remote, branch=None):
    if (remote == "cm"):
        if (branch == None):
            branch = "cm-13.0"
        if not (name.find("CyanogenMod/") == 0):
            name = "CyanogenMod/" + name
    if (remote == "aokp"):
        if (branch == None):
            branch = "mm"
        if not (name.find("AOKP/") == 0):
            name = "AOKP/" + name

    if is_path_in_manifest(path, name, remote, branch):
        # Error messages are present in the called function, so just exit
        return False
    else:
        print("Adding %s to track from %s (branch: %s) in local manifest" % (path, name, branch))
        newproject = ElementTree.Element("project", attrib = { "path": path,
            "remote": remote, "name": name, "branch": branch })
        lm.append(newproject)
        write_out_local_manifest(lm)
        reload_local_manifest()
        return True



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

        githubreq = urllib.request.Request("https://api.github.com/search/repositories?q=%s+user:AOKP+in:name+fork:true" % device)
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

        for res in result['items']:
            if (res['name'].endswith("_%s" % device)):
                print("Found %s" % res['name'])
                devicepath = res['name'].replace("_","/")
                if add_to_local_manifest(devicepath, res['full_name'], "aokp"):
                    reposync(res['full_name'])
                break

def checkdeps(repo_path):
    cmdeps = glob.glob(repo_path + "/cm.dependencies")
    aokpdeps = glob.glob(repo_path + "/aokp.dependencies")
    if ((len(cmdeps) + len(aokpdeps)) < 1):
        ran_checkdeps_on.append("NO_DEPS:\t\t" + repo_path)
        return
    else:
        if (len(cmdeps) > 0):
            ran_checkdeps_on.append("HAS_CM_DEPS:\t" + repo_path)
            cmdeps = cmdeps[0]
            cmdeps = open(cmdeps, 'r')
            cmdeps = json.loads(cmdeps.read())
            for dep in cmdeps:
                try:
                    branch = dep['branch']
                except:
                    branch = None
                try:
                    remote = dep['remote']
                except:
                    remote = "cm"
                if add_to_local_manifest(dep['target_path'], dep['repository'], remote, branch):
                    reposync(dep['target_path'])
                checkdeps(dep['target_path'])


        if (len(aokpdeps) > 0):
            ran_checkdeps_on.append("HAS_AOKP_DEPS:\t" + repo_path)
            aokpdeps = aokpdeps[0]
            aokpdeps = open(aokpdeps, 'r')
            aokpdeps = json.loads(aokpdeps.read())
            for dep in aokpdeps:
                try:
                    branch = dep['branch']
                except:
                    branch = None
                try:
                    remote = dep['remote']
                except:
                    remote = "aokp"
                if add_to_local_manifest(dep['target_path'], dep['repository'], remote, branch):
                    reposync(dep['target_path'])
                checkdeps(dep['target_path'])

######## MAIN SCRIPT STARTS HERE ############

reload_local_manifest()

if not depsonly:
    get_from_github(args.device)

checkdeps("device/*/%s" % args.device)

print("Checked dependency tree over : ")
for repo in ran_checkdeps_on:
    print("    %s" % repo)


