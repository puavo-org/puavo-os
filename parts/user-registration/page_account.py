# The "Create account" page

import re
import unicodedata
import socket
import json
import threading
import http.client
import gettext
import time
import logging

import gi

gi.require_version('Gtk', '3.0')
from gi.repository import GLib, Gtk

import utils

from page_definition import PageDefinition

gettext.bindtextdomain('puavo-user-registration', '/usr/share/locale')
gettext.textdomain('puavo-user-registration')
_tr = gettext.gettext


# These language codes must be the same that are configured/allowed
# on the server!
LANGUAGES = [
    ('fi_FI.UTF-8', _tr('Finnish')),
    ('sv_FI.UTF-8', _tr('Swedish')),
    ('en_US.UTF-8', _tr('English')),
    ('de_CH.UTF-8', _tr('German')),
]


# Used when interpreting a failed server response
FIELD_ERRORS = {
    'first_name': {
        'name': _tr('first name'),
        'reasons': {
            'empty': _tr('is empty'),
            'failed_validation': _tr('contains bad characters'),
        }
    },

    'last_name': {
        'name': _tr('last name'),
        'reasons': {
            'empty': _tr('is empty'),
            'failed_validation': _tr('contains bad characters'),
        }
    },

    'username': {
        'name': _tr('login name'),
        'reasons': {
            'empty': _tr('is empty'),
            'failed_validation': _tr('contains bad characters'),
        }
    },

    'email': {
        'name': _tr('email address'),
        'reasons': {
            'empty': _tr('is empty'),
            'failed_validation': _tr('contains bad characters'),
        }
    },

    'phone': {
        'name': _tr('phone number'),
        'reasons': {
            'empty': _tr('is empty'),
            'failed_validation': _tr('contains bad characters'),
            'too_long': _tr('is too long'),
        }
    },
}


class PageAccount(PageDefinition):
    def __init__(self, application, parent_window, parent_container, data_dir, main_builder):
        super().__init__(application, parent_window, parent_container, data_dir, main_builder)

        self.load_file('account.glade', 'register_user')

        self.USERNAME_FILTER = re.compile(r'[^a-z|0-9|.|\-]')

        self.network_thread_event = None
        self.network_thread = None

        # Get handles to elements
        self.first_name_field = self.builder.get_object('first_name')
        self.last_name_field = self.builder.get_object('last_name')
        self.username_field = self.builder.get_object('username')
        self.username_hint = self.builder.get_object('username_hint')
        self.email_field = self.builder.get_object('email')
        self.email_hint = self.builder.get_object('email_hint')
        self.password_field = self.builder.get_object('password')
        self.password_confirm_field = self.builder.get_object('password_confirm')
        self.language_combo = self.builder.get_object('language')
        self.phone_field = self.builder.get_object('phone_number')
        self.phone_hint = self.builder.get_object('phone_number_hint')
        self.spinner = self.builder.get_object('registration_spinner')
        self.status = self.builder.get_object('status_message')
        self.submit_button = self.builder.get_object('submit')

        for lang in LANGUAGES:
            self.language_combo.insert(-1, lang[0], lang[1])

        self.language_combo.set_active(0)

        # Setup event handling
        handlers = {
            'on_first_name_changed': self.on_first_name_changed,
            'on_last_name_changed': self.on_last_name_changed,
            'on_username_changed': self.on_username_changed,
            'on_email_changed': self.on_email_changed,
            'on_password_changed': self.on_password_changed,
            'on_password_confirm_changed': self.on_password_confirm_changed,
            'on_language_changed': self.on_language_changed,
            'on_phone_number_changed': self.on_phone_number_changed,
            'on_submit_clicked': self.on_submit_clicked,
            'on_previous_clicked': self.on_previous_clicked,
        }

        self.builder.connect_signals(handlers)

        # Manually bind this event because we need its signal ID and
        # connect_signals() won't return them
        self.username_change_signal \
            = self.username_field.connect('changed', self.on_username_changed)

        # These members store the form contents. They're cleaned up
        # and validated, so use them!
        self.user_first_name = ''
        self.user_last_name = ''
        self.user_username = ''
        self.user_email = ''
        self.user_password = ''
        self.user_password_confirm = ''
        self.user_language = 'fi_FI.UTF-8'
        self.user_phone = ''

        self.update_username_hint(True)
        self.set_submit_state()


    def get_main_title(self):
        return _tr('Account Setup')


    def activate(self):
        super().activate()
        self.builder.get_object('first_name').grab_focus()


    def on_previous_clicked(self, *args):
        self.application.previous_page()


    # ==========================================================================
    # ==========================================================================
    # DIALOG VALIDATION


    def enable_inputs(self, state):
        for obj in self.builder.get_objects():
            if obj is self.status:
                continue

            if isinstance(obj, Gtk.Entry) or \
               isinstance(obj, Gtk.Label) or \
               isinstance(obj, Gtk.Button) or \
               isinstance(obj, Gtk.ComboBoxText):
                obj.set_sensitive(state)


    def set_submit_state(self):
        state = True

        if len(self.user_first_name) == 0:
            state = False

        if len(self.user_last_name) == 0:
            state = False

        if len(self.user_username) < 3 or \
                re.search(self.USERNAME_FILTER, self.user_username) or \
                self.user_username[0] not in 'abcdefghijklmnopqrstuvwxyz0123456789':
            state = False

        if len(self.user_email) == 0:
            state = False

        if len(self.user_password) == 0:
            state = False

        if len(self.user_password_confirm) == 0:
            state = False

        if len(self.user_phone) > 0 and not self.__only_digits(self.user_phone):
            state = False

        if self.user_password != self.user_password_confirm:
            state = False

        self.submit_button.set_sensitive(state)


    # Python strings have a isdigit() method, but it accepts things
    # like superscripts and Kharotshi numbers, which our database
    # will reject because it does not consider them to be digits.
    def __only_digits(self, s):
        for c in s:
            if not c in "0123456789":
                return False

        return True


    def __normalize_string(self, s):
        out = s.lower()

        out = out.strip()

        # Decompose Unicode characters into separate combining characters
        # (For example, "ä" gets turned into "a" and "U0308 COMBINING DIAERESIS")
        out = unicodedata.normalize('NFD', out)

        # Then remove all bytes outside of the a-z/number/some punctuation range.
        # All accents, diacritics, etc. will disappear, leaving only unaccented
        # characters behind.
        out = re.sub(self.USERNAME_FILTER, r'', out)

        return out


    def build_username(self):
        fn = self.__normalize_string(self.user_first_name)
        ln = self.__normalize_string(self.user_last_name)

        # Combine the parts "intelligently"
        if len(fn) == 0 and len(ln) == 0:
            username = ''
        elif len(fn) > 0 and len(ln) == 0:
            username = fn
        elif len(fn) == 0 and len(ln) > 0:
            username = ln
        else:
            username = fn + '.' + ln

        self.user_username = username


    def update_username_hint(self, is_initial=False):
        if is_initial:
            # The form was just created, all fields are empty,
            # do no validation yet
            self.username_hint.set_markup('')
            return

        username = self.user_username

        if re.search(self.USERNAME_FILTER, username):
            message = _tr('The login name contains invalid characters')
            is_good = False
        elif len(username) < 3:
            message = _tr('The login name must be at least three characters long')
            is_good = False
        elif username[0] not in 'abcdefghijklmnopqrstuvwxyz0123456789':
            message = _tr('The login name must start with a letter or a number')
            is_good = False
        else:
            message = ''
            is_good = True

        color = '#888' if is_good else '#f44'
        self.username_hint.set_markup('<span color="%s">%s</span>' % (color, message))


    # Update the username field without triggering a "changed" event
    def update_username_field(self):
        with self.username_field.handler_block(self.username_change_signal):
            self.username_field.set_text(self.user_username)


    def on_first_name_changed(self, edit):
        # Clean up the first name
        self.user_first_name = self.first_name_field.get_text().strip()

        while self.user_first_name.startswith('.'):
            self.user_first_name = self.user_first_name[1:]

        self.build_username()
        self.update_username_field()
        self.update_username_hint()
        self.set_submit_state()


    def on_last_name_changed(self, edit):
        # Clean up the last name
        self.user_last_name = self.last_name_field.get_text().strip()

        while self.user_last_name.startswith('.'):
            self.user_last_name = self.user_last_name[1:]

        self.build_username()
        self.update_username_field()
        self.update_username_hint()
        self.set_submit_state()


    def on_username_changed(self, edit):
        # This is called when the user is manually editing the
        # username field. Validate the input, but no cleanups.
        self.user_username = self.username_field.get_text().strip()
        self.update_username_hint()
        self.set_submit_state()


    def on_email_changed(self, edit):
        self.user_email = self.email_field.get_text().strip()
        self.set_submit_state()


    def on_password_changed(self, edit):
        # NOTE: no strip() call here, the field contents are used
        # as-is!
        self.user_password = self.password_field.get_text()
        self.set_submit_state()


    def on_password_confirm_changed(self, edit):
        self.user_password_confirm = self.password_confirm_field.get_text()
        self.set_submit_state()


    def on_language_changed(self, combo):
        self.user_language = LANGUAGES[self.language_combo.get_active()][0]
        self.set_submit_state()


    def on_phone_number_changed(self, edit):
        self.user_phone = self.phone_field.get_text().strip()
        self.set_submit_state()


    # ==========================================================================
    # ==========================================================================
    # NETWORKING AND SERVER RESPONSE INTERPRETATION


    def on_submit_clicked(self, *args):
        # ----------------------------------------------------------------------
        # Gather data

        user = {}
        user['first_name'] = self.user_first_name
        user['last_name'] = self.user_last_name
        user['username'] = self.user_username
        user['email'] = self.user_email
        user['password'] = self.user_password
        user['password_confirm'] = self.password_confirm_field.get_text()
        user['language'] = self.user_language
        user['phone'] = self.user_phone

        data = {
            'user': user,
            'machine': self.application.get_machine_data(),
        }

        json_data = json.dumps(data, ensure_ascii=False)

        # --------------------------------------------------------------------------
        # Launch a background thread

        self.enable_inputs(False)
        self.status.set_text(_tr('Sending information to the server...'))
        self.spinner.start()

        self.network_thread_event = threading.Event()

        self.network_thread = NetworkThread(json_data,
                                            self.network_thread_event)
        self.network_thread.daemon = True
        self.network_thread.start()

        # This will interpret the server's response
        GLib.idle_add(self.idle_func,
                      self.network_thread_event,
                      self.network_thread)


    def handle_server_error(self, response):
        logging.error('handle_server_error(): response=%s', response)

        utils.show_error_message(
            self.parent_window,
            _tr('Error'),
            _tr('Something went wrong on the server end.') \
            + '  ' + _tr('Please contact support and give them this code:') \
            + '\n\n<big>{0}</big>'.format(response['log_id']))


    def handle_server_400(self, response):
        logging.error('handle_server_400(): response=%s', response)

        if response['status'] == 'missing_data':
            if len(response['failed_fields']) > 0:
                msg = _tr('Something is wrong on the following form fields.' \
                          '  Check their contents and try again.')

                msg += '\n\n'

                for field in response['failed_fields']:
                    error = FIELD_ERRORS[field['name']]
                    msg += '\t- {0} {1}\n'. \
                        format(error['name'], error['reasons'][field['reason']])

                utils.show_error_message(
                    self.parent_window,
                    _tr('Bad Information'),
                    msg)

        elif response['status'] == 'malformed_json':
            # *We* sent invalid data :-(
            utils.show_error_message(
                self.parent_window,
                _tr('Bad Information'),
                _tr('This registration program sent bad information to the server.') + \
                _tr('Please contact support and give them this code:') + \
                '\n\n<big>{0}</big>'.format(response['log_id']))

        elif response['status'] == 'incomplete_data':
            # *We* sent incomplete/missing data :-(
            utils.show_error_message(
                self.parent_window,
                _tr('Missing information'),
                _tr('Registration program did not send all required information to server.') + \
                '  ' +
                _tr('Please contact support and give them this code:') + \
                '\n\n<big>{0}</big>'.format(response['log_id']))

        elif response['status'] == 'invalid_username':
            utils.show_error_message(
                self.parent_window,
                _tr('Invalid input'),
                _tr('The login name contains invalid characters.'))

        elif response['status'] == 'invalid_email':
            utils.show_error_message(
                self.parent_window,
                _tr('Invalid input'),
                _tr('The email address is not valid.'))

        elif response['status'] == 'password_mismatch':
            utils.show_error_message(
                self.parent_window,
                _tr('Invalid input'),
                _tr('The password and its confirmation do not match.'))

        elif response['status'] == 'invalid_language':
            utils.show_error_message(
                self.parent_window,
                _tr('Invalid input'),
                _tr('The selected language is not valid.'))

        else:
            utils.show_error_message(
                self.parent_window,
                _tr('Error'),
                _tr('An unknown error occurred when handling user information.') + \
                '\n\n' +
                _tr('Please contact support and give them this code:') + \
                '\n\n<big>{0}</big>'.format(response['log_id']))


    def handle_server_401(self, response):
        logging.error('handle_server_401(): response=%s', response)

        if response['status'] == 'unknown_machine':
            # This machine does not exist in the database
            utils.show_error_message(
                self.parent_window,
                _tr('Unregistered host'),
                _tr('This host was not found on the database.') \
                  + '  ' + _tr('Please contact support and give them this code:') \
                  + '\n\n<big>{0}</big>'.format(response['log_id']))

        elif response['status'] == 'device_already_in_use':
            # This machine already has a user. THIS SHOULD NOT HAPPEN.
            utils.show_error_message(
                self.parent_window,
                _tr('Host is already in use'),
                _tr('User registration has already been done on this host.') \
                   + '  ' + _tr('Please contact support and give them this code:') +
                '\n\n<big>{0}</big>'.format(response['log_id']))

        elif response['status'] == 'server_error':
            self.handle_server_error(response)

        else:
            utils.show_error_message(
                self.parent_window,
                _tr('Error'),
                _tr('An unknown error occurred when handling host information.') \
                  + '\n\n<big>{0}</big>'.format(response['log_id']))


    def handle_server_409(self, response):
        logging.error('handle_server_409(): response=%s', response)

        if response['status'] == 'username_unavailable':
            utils.show_error_message(
                self.parent_window,
                _tr('Login name already in use'),
                _tr('The login name you have chosen is already in use.  Please choose another.'))

        elif response['status'] == 'username_too_short':
            utils.show_error_message(
                self.parent_window,
                _tr('Too short login name'),
                _tr('Your login name is too short.  It must have at least three characters.'))

        elif response['status'] == 'duplicate_email':
            utils.show_error_message(
                self.parent_window,
                _tr('Email address is already in use'),
                _tr('This email address is already in use.  Please use another address.') +
                '\n\n' +
                _tr('If using another email address is not possible, please contact support ' \
                    'and give them this code:') + \
                '\n\n<big>{0}</big>'.format(response['log_id']))

        else:
            utils.show_error_message(
                self.parent_window,
                _tr('Error'),
                _tr('An unknown error occurred when handling user information.') \
                 + '\n\n<big>{0}</big>'.format(response['log_id']))


    def handle_server_500(self, response):
        logging.error('handle_server_500(): response=%s', response)
        self.handle_server_error(response)


    def handle_network_error(self, msg):
        logging.error('handle_network_error: msg="%s"', msg)

        utils.show_error_message(
            self.parent_window,
            _tr('Error'),
            _tr('Could not contact the server:') + '\n\n\t{0}\n\n'.format(msg) + \
            _tr('Check the network connection and try again.') \
              + '  ' + _tr('If the problem persists, contact support.'))


    def idle_func(self, event, thread):
        if event.is_set():
            logging.info('Thread event set, idle function is exiting')
            self.status.set_text('')
            self.spinner.stop()

            logging.info('idle_func(): full server response: |%s|', thread.response)

            if thread.response['failed']:
                if thread.response['error'] == 'timeout':
                    utils.show_error_message(
                        self.parent_window,
                        _tr('Error'),
                        _tr('The server is not responding.  Try again after a while.  ' \
                            'If the problem persists, contact support.'))
                else:
                    self.handle_network_error(thread.response['error'])
            else:
                self.interpret_server_response(
                    thread.response['code'],
                    thread.response['headers'],
                    thread.response['data'])

            self.enable_inputs(True)

            # Remove the idle function
            return False

        # Don't make CPU fans spin. This idle function is called where there
        # are no other messages to handle and that includes the server response
        # waiting. It's a long time to listen to CPU fans whirring...
        time.sleep(0.05)

        # Don't remove the idle function yet
        return True


    def interpret_server_response(self, response_code, response_headers, response_data):
        # Parse the returned JSON
        try:
            logging.info('Trying to parse server response |%s|', str(response_data))
            server_data = response_data.decode('utf-8')
            server_json = json.loads(server_data)
        except Exception as exc:
            logging.error(str(exc), exc_info=True)

            utils.show_error_message(
                self.parent_window,
                _tr('Error'),
                _tr('Could not interpret the response sent by the server.') \
                  + '\n\n' +
                _tr('Please contact support.'))

            self.enable_inputs(True)
            return

        # Interpret the JSON
        try:
            if response_code == 400:            # missing/incomplete/invalid data
                self.handle_server_400(server_json)
                self.enable_inputs(True)
                return
            elif response_code == 401:          # device errors
                self.handle_server_401(server_json)
                self.enable_inputs(True)
                return
            elif response_code == 409:          # unavailable username/email
                self.handle_server_409(server_json)
                self.enable_inputs(True)
                return
            elif response_code == 500:          # server errors
                self.handle_server_500(server_json)
                self.enable_inputs(True)
                return
            elif response_code == 200:          # the good response
                logging.info('interpret_server_response(): received a 200 response code!')

                # The parent window has no way to retrieve the username or
                # the password.
                self.application.save_user_details(
                    self.user_username, self.user_password)

                # Proceed to the "complete" page
                self.application.next_page()

                return

            # All other return codes fall through to the "should not get here"
            # block below

        except Exception as exc:
            logging.error(str(exc), exc_info=True)

            utils.show_error_message(
                self.parent_window,
                _tr('Something went wrong'),
                _tr('Could not interpret the response sent by the server.') \
                  + '  ' + _tr('Please contact support.'))
            return

        # If we get here, something has gone horribly wrong
        utils.show_error_message(
            self.parent_window,
            _tr('Something went wrong'),
            _tr('This situation should never happen, something has gone very ' \
                'badly wrong.') + '  ' + _tr('Please contact support.'))


    def enable_login_button(self):
        return True


class NetworkThread(threading.Thread):
    def __init__(self, json_data, event):
        super().__init__()
        self.json_data = json_data
        self.event = event
        self.response = {}


    def run(self):
        logging.info('Network thread is starting')

        self.response['failed'] = False
        self.response['error'] = None

        response = None

        headers = {
            'Content-type': 'application/json',
        }

        conn = None

        try:
            server_addr = open('/etc/puavo/domain', 'rb').read().decode('utf-8').strip()

            conn = http.client.HTTPSConnection(server_addr, timeout=10)

            conn.request('POST',
                         '/register_user',
                         body=bytes(self.json_data, 'utf-8'),
                         headers=headers)

            # Must read the response here, because the "finally" handler
            # closes the connection and that happens before we can read
            # the response
            response = conn.getresponse()
            self.response['code'] = response.status
            self.response['headers'] = response.getheaders()
            self.response['data'] = response.read()

        except socket.timeout:
            self.response['error'] = 'timeout'
            self.response['failed'] = True
        except http.client.HTTPException as exc:
            self.response['error'] = exc
            self.response['failed'] = True
        except Exception as exc:
            self.response['error'] = exc
            self.response['failed'] = True
        finally:
            if conn:
                conn.close()

        self.event.set()
        logging.info('Network thread is exiting')
