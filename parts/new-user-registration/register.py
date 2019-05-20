#!/usr/bin/python3

# New user registration dialog v0.5

# TODO:
#  - everything

import re
import json
import time
import socket
import threading
import subprocess
import unicodedata
import http.client

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, GLib, Pango


# Mapped to correct values on server-side
LANGUAGES = [
    ('fi', 'Suomi'),
    ('sv', 'Ruotsi'),
    ('en', 'Englanti'),
    ('de', 'Saksa'),
]

# Used when interpreting a failed server response
FIELD_ERRORS = {
    'first_name': {
        'name': 'etunimi',
        'reasons': {
            'empty': 'on tyhjä',
            'failed_validation': 'sisältää virheellisiä merkkejä',
        }
    },

    'last_name': {
        'name': 'sukunimi',
        'reasons': {
            'empty': 'on tyhjä',
            'failed_validation': 'sisältää virheellisiä merkkejä',
        }
    },

    'username': {
        'name': 'käyttäjänimi',
        'reasons': {
            'empty': 'on tyhjä',
            'failed_validation': 'sisältää virheellisiä merkkejä',
        }
    },

    'email': {
        'name': 'email',
        'reasons': {
            'empty': 'on tyhjä',
            'failed_validation': 'sisältää virheellisiä merkkejä',
        }
    },
}


def show_info_message(parent, message, secondary_message=None):
    """Show a modal information message box."""

    dialog = Gtk.MessageDialog(parent=parent,
                               flags=Gtk.DialogFlags.MODAL,
                               type=Gtk.MessageType.INFO,
                               buttons=Gtk.ButtonsType.OK,
                               message_format=message)

    if secondary_message:
        dialog.format_secondary_markup(secondary_message)

    dialog.run()
    dialog.hide()

def show_error_message(parent, message, secondary_message=None):
    """Show a modal error message box."""

    dialog = Gtk.MessageDialog(parent=parent,
                               flags=Gtk.DialogFlags.MODAL,
                               type=Gtk.MessageType.ERROR,
                               buttons=Gtk.ButtonsType.OK,
                               message_format=message)

    if secondary_message:
        dialog.format_secondary_markup(secondary_message)

    dialog.run()
    dialog.hide()


builder = Gtk.Builder()
builder.add_from_file('register.glade')
main_window = builder.get_object('register_window')

# Get object handles
first_name_field = builder.get_object('first_name')
last_name_field = builder.get_object('last_name')
username_field = builder.get_object('username')
username_hint = builder.get_object('username_hint')
email_field = builder.get_object('email')
password_field = builder.get_object('password')
password_confirm_field = builder.get_object('password_confirm')
language_combo = builder.get_object('language')
phone_field = builder.get_object('phone_number')
spinner = builder.get_object('spinner')
status = builder.get_object('status_message')

submit_button = builder.get_object('submit')
reset_button = builder.get_object('reset')

username_change_signal = -1

network_thread = None
network_thread_event = None

USERNAME_FILTER = re.compile(r'[^a-z|0-9|.|\-|_]')


def set_username_hint_status(is_good=True):
    color = '#888' if is_good else '#f00'
    username_hint.set_markup('<span color="%s">Käyttäjätunnuksiin kelpaavat merkit a-z, 0-9, -, _ ja piste.</span>' % color)


def set_submit_state():
    state = True

    if len(first_name_field.get_text().strip()) == 0:
        state = False

    if len(last_name_field.get_text().strip()) == 0:
        state = False

    if len(username_field.get_text().strip()) == 0 or \
       re.search(USERNAME_FILTER, username_field.get_text()):
        state = False

    if len(email_field.get_text().strip()) == 0:
        state = False

    if len(password_field.get_text()) == 0:
        state = False

    if len(password_confirm_field.get_text()) == 0:
        state = False

    if password_field.get_text() != password_confirm_field.get_text():
        state = False

    submit_button.set_sensitive(state)


def enable_inputs(state):
    for obj in builder.get_objects():
        if obj is status:
            continue

        if isinstance(obj, Gtk.Entry) or \
           isinstance(obj, Gtk.Label) or \
           isinstance(obj, Gtk.Button) or \
           isinstance(obj, Gtk.ComboBoxText):
            obj.set_sensitive(state)


def update_username():
    fn = first_name_field.get_text().strip()
    ln = last_name_field.get_text().strip()

    if len(fn) == 0 and len(ln) == 0:
        username = ''
    elif len(fn) > 0 and len(ln) == 0:
        username = fn
    elif len(fn) == 0 and len(ln) > 0:
        username = ln
    else:
        username = fn + '.' + ln

    username = username.lower()

    # Decompose Unicode into separate combining characters
    username = unicodedata.normalize('NFD', username)

    # Then remove all bytes outside of the a-z/number/some punctuation range.
    # All accents, diacritics, etc. will disappear, leaving only unaccented
    # characters behind.
    username = re.sub(USERNAME_FILTER, r'', username)

    # Update the username without triggering a "changed" event
    with username_field.handler_block(username_change_signal):
        username_field.set_text(username)


def on_first_name_changed(edit):
    update_username()
    set_submit_state()


def on_last_name_changed(edit):
    update_username()
    set_submit_state()


def on_username_changed(edit):
    username = edit.get_text()

    if re.search(USERNAME_FILTER, username):
        set_username_hint_status(False)
    else:
        set_username_hint_status(True)

    set_submit_state()


def on_email_changed(edit):
    set_submit_state()


def on_password_changed(edit):
    set_submit_state()


def on_password_confirm_changed(edit):
    set_submit_state()


def on_language_changed(combo):
    set_submit_state()


def on_phone_number_changed(edit):
    set_submit_state()


def handle_server_error(response):
    show_error_message(main_window, 'Virhe',
       'Palvelinpäässä meni jokin pieleen. Ole hyvä ja ota yhteys tukeen. '
       'Anna tuelle tämä koodi:\n\n<big>{0}</big>'.format(response['log_id']))


def handle_server_400(response):
    if response['status'] == 'missing_data':
        if len(response['failed_fields']) > 0:
            msg = 'Näiden kenttien sisältö ei ole kunnollinen. Tarkista niiden sisältö.\n\n'

            for field in response['failed_fields']:
                error = FIELD_ERRORS[field['name']]
                msg += '- {0} {1}\n'.format(error['name'], error['reasons'][field['reason']])

            show_error_message(
                main_window,
                'Virheellinen data',
                msg)

    elif response['status'] == 'invalid_username':
        show_error_message(main_window, 'Virheellinen data',
                           'Käyttäjätunnus sisältää virheellisiä merkkejä.')

    elif response['status'] == 'invalid_email':
        show_error_message(main_window, 'Virheellinen data',
                           'Sähköpostiosoite ei ole kunnollinen.')

    elif response['status'] == 'password_mismatch':
        show_error_message(main_window, 'Virheellinen data',
                           'Salasana ja sen varmistus eivät täsmää.')

    elif response['status'] == 'invalid_language':
        show_error_message(main_window, 'Virheellinen data',
                           'Kieli on virheellinen.')

    else:
        show_error_message(main_window, 'Virhe',
           'Käyttäjätietojen käsittelyssä tapahtui tuntematon virhe. '
           'Ota yhteys tukeen ja anne heille tämä koodi:\n\n'
           '<big>{0}</big>'.format(response['log_id']))


def handle_server_401(response):
    if response['status'] == 'unknown_machine':
        # This machine does not exist in the database
        show_error_message(main_window, 'Rekisteröimätön kone',
            'Koneesi tietoja ei löydy tietokannasta. Ole hyvä ja ota '
            'yhteys tukeen. Anna tuelle tämä koodi:\n\n<big>{0}</big>'.
            format(response['log_id']))

    elif response['status'] == 'device_already_in_use':
        # This machine already has a user. THIS SHOULD NOT HAPPEN.
        show_error_message(main_window, 'Kone on jo käytössä',
            'Tältä koneelta on jo suoritettu käyttäjän luonti. Ole hyvä ja ota '
            'yhteys tukeen. Anna tuelle tämä koodi:\n\n<big>{0}</big>'.
            format(response['log_id']))

    elif response['status'] == 'server_error':
        handle_server_error(response)

    else:
        show_error_message(main_window, 'Virhe',
           'Laitetietojen käsittelyssä tapahtui tuntematon virhe. '
           'Ota yhteys tukeen ja anne heille tämä koodi:\n\n'
           '<big>{0}</big>'.format(response['log_id']))


def handle_server_409(response):
    if response['status'] == 'username_unavailable':
        show_error_message(main_window, 'Käyttäjätunnus on jo käytössä',
            'Valitsemasi käyttäjätunnus on jo käytössä. Valitse toinen nimi.')

    elif response['status'] == 'duplicate_email':
        show_error_message(main_window, 'Sähköpostiosoite on jo käytössä',
            'Tämä sähköpostiosoite on jo käytössä. Käytä toista osoitetta.\n\n'
            'Jos toisen osoitten käyttö ei ole mahdollista, ota yhteys tukeen. '
            'Anna heille tämä koodi:\n\n'
            '<big>{0}</big>'.format(response['log_id']))

    else:
        show_error_message(main_window, 'Virhe',
           'Käyttäjätietojen käsittelyssä tapahtui tuntematon virhe. '
           'Ota yhteys tukeen ja anne heille tämä koodi:\n\n<big>{0}</big>'.
           format(response['log_id']))


def handle_server_500(response):
    handle_server_error(response)


def handle_network_error(msg):
    show_error_message(main_window, 'Virhe',
        'Palvelimeen ei saada yhteyttä:\n\n\t{0}\n\n'
        'Tarkista verkkoyhteyden tila ja yritä uudelleen. Jos ongelma toistuu,'
        'ota yhteys tukeen.'.format(msg))


class NetworkThread(threading.Thread):
    def __init__(self, json, event):
        super().__init__()
        self.json = json
        self.event = event
        self.response = {}

    def run(self):
        self.response['failed'] = False
        self.response['error'] = None

        response = None

        conn = http.client.HTTPConnection('10.246.144.92', 9491, timeout=10)

        headers = {
            'Content-type': 'application/json',
        }

        try:
            conn.request('POST',
                         '/try_register_user',
                         body=bytes(self.json, 'utf-8'),
                         headers=headers)

            # Must read the response here, because the "finally" handler
            # closes the connection and that happens before we can read
            # the response
            response = conn.getresponse()
            self.response['code'] = response.status
            self.response['headers'] = response.getheaders()
            self.response['data'] = response.read()

        except socket.timeout as st:
            self.response['error'] = 'timeout'
            self.response['failed'] = True
        except http.client.HTTPException as e:
            self.response['error'] = e
            self.response['failed'] = True
        except Exception as e:
            self.response['error'] = e
            self.response['failed'] = True
        finally:
            conn.close()

        self.event.set()
        print('Network thread exiting')


def idle_func(event, thread):
    if event.is_set():
        print('Thread event set, idle function is exiting')
        status.set_text('')
        spinner.stop()

        if thread.response['failed']:
            if thread.response['error'] == 'timeout':
                show_error_message(main_window, 'Virhe',
                    'Palvelin ei vastaa pyyntöön. Yritä lähetystä uudelleen hetken kuluttua. '
                    'Jos tilanne toistuu, ota yhteys tukeen.')
            else:
                handle_network_error(thread.response['error'])
        else:
            interpret_server_response(
                thread.response['code'],
                thread.response['headers'],
                thread.response['data'])

        enable_inputs(True)

        # Remove the idle function
        return False

    # Don't make CPU fans spin. This idle function is called where there
    # are no other messages to handle and that includes the server response
    # waiting. It's a long time to listen to CPU fans whirring...
    time.sleep(0.05)

    # Don't remove the idle function yet
    return True


def interpret_server_response(response_code, response_headers, response_data):
    # Parse the returned JSON
    try:
        print('Trying to parse server response |{0}|'.format(response_data))
        server_data = response_data.decode('utf-8')
        server_json = json.loads(server_data)
    except Exception as e:
        show_error_message(main_window, 'Virhe',
            'Palvelimen lähettämää vastausta ei pystytty tulkitsemaan.\n\n'
            'Ole hyvä ja ota yhteys tukeen.')
        enable_inputs(True)
        return

    try:
        if response_code == 400:            # missing/incomplete/invalid data
            handle_server_400(server_json)
            enable_inputs(True)
            return
        elif response_code == 401:          # device errors
            handle_server_401(server_json)
            enable_inputs(True)
            return
        elif response_code == 409:          # unavailable username/email
            handle_server_409(server_json)
            enable_inputs(True)
            return
        elif response_code == 500:          # server errors
            handle_server_500(server_json)
            enable_inputs(True)
            return
        elif response_code == 200:          # the good response
            show_info_message(main_window,
                'Tunnus luotu',
                'Tunnuksesi on luotu. Voit aloittaa koneen käytön.\n\nMukavia hetkiä opiskelun pariin!')
            enable_inputs(True)

            # Quit
            Gtk.main_quit()

            return

        # All other return codes fall through to the "should not get here"
        # block below

    except Exception as e:
        show_error_message(main_window,
            'Jokin meni pieleen',
            'Palvelimen palauttamaa viestiä ei pystytty tulkitsemaan. Ole hyvä ja ota yhteys tukeen.')
        return

    # If we get here, something has gone horribly wrong
    show_error_message(main_window,
        'Jokin meni pieleen',
        'Tätä viestiä ei pitäisi tulla. Koska luet sitä nyt, on jokin mennyt pahasti pieleen.'
        'Ole hyvä ja ota yhteys tukeen.')


def on_submit_clicked(button):
    # --------------------------------------------------------------------------
    # Gather data

    user = {}
    user['first_name'] = first_name_field.get_text().strip()
    user['last_name'] = last_name_field.get_text().strip()
    user['username'] = username_field.get_text()
    user['email'] = email_field.get_text().strip()
    user['password'] = password_field.get_text()
    user['password_confirm'] = password_confirm_field.get_text()
    user['language'] = LANGUAGES[language_combo.get_active()][0]
    user['phone'] = phone_field.get_text().strip()

    machine = {}

    try:
        machine['dn'] = open('data/dn', 'rb').read().decode('utf-8').strip()
        machine['password'] = open('data/password', 'rb').read().decode('utf-8').strip()
        machine['hostname'] = open('data/hostname', 'rb').read().decode('utf-8').strip()
    except Exception as e:
        print(e)

    data = {}
    data['user'] = user
    data['machine'] = machine

    json_data = json.dumps(data, ensure_ascii=False)

    # --------------------------------------------------------------------------
    # Launch a background thread

    status.set_text('Lähetetään tiedot palvelimelle...')
    enable_inputs(False)
    spinner.start()

    network_thread_event = threading.Event()

    network_thread = NetworkThread(json_data, network_thread_event)
    network_thread.daemon = True
    network_thread.start()

    # This will interpret the server's response
    GLib.idle_add(idle_func, network_thread_event, network_thread)


def on_reset_clicked(button):
    first_name_field.set_text('')
    last_name_field.set_text('')

    with username_field.handler_block(username_change_signal):
        username_field.set_text('')

    email_field.set_text('')
    password_field.set_text('')
    password_confirm_field.set_text('')
    language_combo.set_active(0)        # triggers a "change" event, but it's okay
    phone_field.set_text('')

    submit_button.set_sensitive(False)

    first_name_field.grab_focus()


def on_destroy(self, *args):
    Gtk.main_quit()


# Setup initial values
for lang in LANGUAGES:
    language_combo.insert(-1, lang[0], lang[1])

language_combo.set_active(0)


# Setup event handling
handlers = {
    'on_first_name_changed': on_first_name_changed,
    'on_last_name_changed': on_last_name_changed,
    'on_username_changed': on_username_changed,
    'on_email_changed': on_email_changed,
    'on_password_changed': on_password_changed,
    'on_password_confirm_changed': on_password_confirm_changed,
    'on_language_changed': on_language_changed,
    'on_phone_number_changed': on_phone_number_changed,

    'on_submit_clicked': on_submit_clicked,
    'on_reset_clicked': on_reset_clicked,

    'on_destroy': on_destroy,
}

builder.connect_signals(handlers)

# Manually bind this event because we need the signal ID and
# connect_signals() won't return them
username_change_signal = username_field.connect('changed', on_username_changed)

set_username_hint_status(True)
set_submit_state()
status.set_text('')

# Go!
main_window.show_all()
Gtk.main()
