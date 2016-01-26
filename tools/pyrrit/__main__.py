#!/usr/bin/python2.7
import sys

import listchanges
import pullchange
import topicpull


__author__ = 'arnav'


def print_help(extended):
    print("Usage : pyrrit <mode [parameters]> [-flag parameter]")
    print("Where mode can be \n")
    print("list [dirpath]              - Show all open patches [for given directory path]")
    print("upload")
    print("pull ps1 [ps2 [ps3..]]      - Pull the given patchset(s)")
    print("pstest device ps1 [ps2..]   - Pull the given patchset(s), and make a build for device to test")
    print("topicpull topic             - Pull all patchset(s) of given topic")
    print("topictest device topic      - Pull all patchset(s) of given topic, and make a build for device to test")
    print("help                        - Show extended help")
    if extended:
        print("\n")
        print("Some example commands\n")
        print("pyrrit list                           - List all open changes on gerrit")
        print("pyrrit list device/sony/common        - List open changes that can be pulled to device/sony/common")
        print("\n")
        print("pyrrit pull 17223 17224 17276         - Pull these changes to their respective projects")
        print("pyrrit pull 17223/2 17224/1           - Same as above, but also specifying revision number")
        print("pyrrit pull 17712/                    - An open ended / will ask user input for revision number")
        print("\n")


if __name__ == '__main__':
    if len(sys.argv) < 2:
        print_help(False)

    elif sys.argv[1] == "help":
        print_help(True)

    elif sys.argv[1] == "pull":
        if len(sys.argv) >= 3:
            changes = sys.argv[2:]
            pullchange.pull_changes(changes)
        else:
            print('Please mention the change # of patch you want to pull')

    elif sys.argv[1] == "topicpull":
        topicpull.topicpull(sys.argv[2])

    elif sys.argv[1] == "list":
        if len(sys.argv) == 3:
            listchanges.show_proj_list(sys.argv[2])
        else:
            listchanges.show_all_list()

    elif sys.argv[1] == "upload":
        print("upload")
        ##TODO: write upload funciton

    else:
        print("Bad argument passed")
        print_help(False)

