import config
import pullchange
import utils

from utils import Col

__author__ = 'arnav'

t_url = "http://" + config.g_url + "/changes/?q=status:open"


def topicpull(topic):
    json_data = utils.get_json_from_url(t_url)
    changes_to_pull = []
    for item in json_data:
        if item.get('topic') == topic:
            changes_to_pull.append(item.get('_number'))
    pullchange.pull_changes(changes_to_pull)


