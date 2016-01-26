import json
import re

import urllib2

import config


__author__ = 'arnav'


# Console colsor constants
class Col:
    ylw = '\033[93m'
    pnk = '\033[95m'
    grn = '\033[92m'
    rst = '\033[0m'


def change_path_to_project_url(path):
    path = path.replace('/', '_')
    path = config.g_proj_basedir + path
    return path


def change_projname_to_dirpath(projname):
    # remove the project's base dir (for eg. the "AOKP/" part)
    dirpath = projname.replace(projname[:len(config.g_proj_basedir)], '')
    dirpath = dirpath.replace('_', '/')
    return dirpath


def get_json_from_url(url):
    response = urllib2.urlopen(url)
    resp_str = response.read()
    response.close()

    # ugly hack because gerrit's json has 4 stupid characters in the first line
    resp_str = resp_str.replace(resp_str[:4], '')

    return json.loads(resp_str)


def segmentise_change_no(raw_change_no):
    rcn = str(raw_change_no)
    change_component_list = []
    re1 = '(\\d+)'
    re2 = '(\\/)'
    re3 = '(\\d+)'

    regex_change_slash_rev = re.compile(re1 + re2 + re3)
    regex_change_slash = re.compile(re1 + re2)
    regex_change = re.compile(re1)

    if regex_change_slash_rev.match(rcn):
        rcn = rcn.split('/', 1)
        change_component_list.append(rcn[0])
        change_component_list.append(rcn[1])
    elif regex_change_slash.match(rcn):
        change_component_list.append(rcn)
        change_component_list.append(-1)
    elif regex_change.match(rcn):
        change_component_list.append(rcn)
        change_component_list.append(0)

    return change_component_list