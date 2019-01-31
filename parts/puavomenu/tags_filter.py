# For explicitly hiding (and showing) programs, menus, categories and more
# through puavo-conf values.


class Action:
    """A single action that either shows or hides something."""

    # What this action does?
    HIDE = 0
    SHOW = 1

    # What this action targets?
    TAG = 0
    PROGRAM = 1
    MENU = 2
    CATEGORY = 3

    ACTIONS_FOR_LOGGER = {
        HIDE: 'hide',
        SHOW: 'show'
    }

    TARGETS_FOR_LOGGER = {
        TAG: 'tag',
        PROGRAM: 'program',
        MENU: 'menu',
        CATEGORY: 'category'
    }

    def __init__(self, action, target, name):
        self.action = action
        self.target = target
        self.name = name

    def __str__(self):
        return '<Filter action: {0} {1} {2}>'.format( \
            self.ACTIONS_FOR_LOGGER[self.action],
            self.TARGETS_FOR_LOGGER[self.target],
            self.name)


class Filter:
    """Zero or more actions that are applied to programs, menus,
    categories and programs tagged with certain tags."""

    def __init__(self, initial=None):
        self.actions = []
        self.program_names = set()
        self.menu_names = set()
        self.category_names = set()

        if initial:
            self.parse_string(initial)


    def have_data(self):
        return len(self.actions) > 0


    def reset(self):
        self.actions = []
        self.program_names = set()
        self.menu_names = set()
        self.category_names = set()


    def parse_string(self, tag_string, strict_reject=True):
        import re
        import logging
        from settings import SETTINGS

        logging.info('Parsing filter string: "%s"', str(tag_string))

        tags = [tag.strip() for tag in re.split(',|;|\ ', str(tag_string) if tag_string else '')]
        tags = filter(None, tags)
        tags = [p.lower() for p in tags]

        self.reset()


        for tag in tags:
            orig_tag = tag

            # Default actions
            action = Action.SHOW
            target = Action.TAG

            # Show or hide?
            if tag[0] == '+':
                action = Action.SHOW
                tag = tag[1:]
            elif tag[0] == '-':
                action = Action.HIDE
                tag = tag[1:]

            # What are we targeting?
            namespace = 't'
            sep = tag.find(':')

            if sep != -1:
                namespace = tag[:sep]
                tag = tag[sep+1:]

            if len(namespace) == 0 or len(tag) == 0:
                if strict_reject:
                    logging.error('Rejecting filter string "%s" because "%s" '
                                  'is not a valid tag' %
                                  (tag_string, orig_tag))
                    self.reset()
                    return False

                continue

            if namespace in ('t', 'tag'):
                target = Action.TAG
            elif namespace in ('p', 'prog', 'program'):
                target = Action.PROGRAM
                self.program_names.add(tag)
            elif namespace in ('m', 'menu'):
                target = Action.MENU
                self.menu_names.add(tag)
            elif namespace in ('c', 'cat', 'category'):
                target = Action.CATEGORY
                self.category_names.add(tag)
            else:
                if strict_reject:
                    logging.error('Rejecting filter string "%s" because "%s" '
                                  'is not a valid tag namespace' %
                                  (tag_string, namespace))
                    self.reset()
                    return False

                continue

            self.actions.append(Action(action, target, tag))
            logging.debug('Filter action: %s %s "%s"',
                          Action.ACTIONS_FOR_LOGGER[action],
                          Action.TARGETS_FOR_LOGGER[target],
                          tag)

        return True
