import config
import utils

from utils import Col

__author__ = 'arnav'

l_url = "http://" + config.g_url + "/changes/?q=status:open"


def show_list(url):
    json_data = utils.get_json_from_url(url)
    for item in json_data:
        print(Col.ylw + str(item.get('_number')) + Col.rst + "\t" + item.get('subject'))
        print("  " + Col.grn + item.get('project') + Col.rst + "\n")


def show_all_list():
    show_list(l_url)


def show_proj_list(proj_path):
    proj_url_path = utils.change_path_to_project_url(proj_path)
    full_url = l_url + "+project:" + proj_url_path
    show_list(full_url)


if __name__ == '__main__':
    show_all_list()