import os

import config
import utils
from utils import Col


__author__ = 'arnav'

p_url = "http://" + config.g_url + "/changes/"
top_dir = os.environ['ANDROID_BUILD_TOP']


def select_rev_index(rev_numbers, given_rev_no):
    max_rev = 0
    sel_rev = 0

    for rev in rev_numbers:
        if rev > max_rev:
            max_rev = rev

    if given_rev_no > 0:
        sel_rev = given_rev_no
    elif given_rev_no == 0:
        sel_rev = max_rev
    elif given_rev_no < 0:
        print("Which revision of the change would you like to pull? [" + str(max_rev) + "] :")
        try:
            sel_rev = int(input())
        except:
            sel_rev = max_rev

    if not sel_rev in rev_numbers:
        sel_rev = max_rev

    return rev_numbers.index(sel_rev)


def cherry_pick_change(dir_path, url, ref):
    cd_command = "cd " + top_dir + "/" + dir_path

    fetch_command = "git fetch " + url + " " + ref
    cherrypick_command = "git cherry-pick FETCH_HEAD"

    os.system(cd_command + " && " + fetch_command + " && " + cherrypick_command)


def pull_one_change(raw_change_no):
    change_no = utils.segmentise_change_no(raw_change_no)[0]
    rev_no = utils.segmentise_change_no(raw_change_no)[1]
    url = p_url + change_no + "?o=ALL_REVISIONS"
    json_data = utils.get_json_from_url(url)
    proj_name = json_data.get('project')
    change_sub = json_data.get('subject')
    dir_path = utils.change_projname_to_dirpath(proj_name)
    print("Pulling change . . . ")
    print(Col.ylw + str(change_no) + "\t" + Col.grn + change_sub + Col.rst)
    print("   onto directory " + Col.pnk + dir_path + Col.rst)
    rev_numbers = []
    rev_branches = []
    rev_urls = []
    revisions = json_data.get("revisions")
    for revision in revisions:
        rev_numbers.append(json_data["revisions"][revision].get("_number"))
        rev_branches.append(json_data["revisions"][revision]['fetch']['anonymous http']['ref'])
        rev_urls.append(json_data["revisions"][revision]['fetch']['anonymous http']['url'])
    rev_index = select_rev_index(rev_numbers, int(rev_no))
    cherry_pick_change(dir_path, rev_urls[rev_index], rev_branches[rev_index])


def pull_changes(change_nos):
    for change_no in change_nos:
        pull_one_change(change_no)
