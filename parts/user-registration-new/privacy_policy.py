# The "Privacy Policy" window

import gi

gi.require_version('Gtk', '3.0')
gi.require_version('WebKit2', '4.0')
from gi.repository import Gtk
from gi.repository import WebKit2


class PrivacyPolicy(Gtk.Dialog):
    def __init__(self, parent, policy_file):
        Gtk.Dialog.__init__(self, 'Privacy Policy', parent, 0,
                            (Gtk.STOCK_CLOSE, Gtk.ResponseType.OK))

        self.set_title('Privacy Policy')
        self.set_default_size(1000, 590)
        self.set_position(Gtk.WindowPosition.CENTER_ON_PARENT)
        self.set_decorated(False)

        self.get_action_area().get_style_context().add_class('policy_buttons')

        manager = WebKit2.WebsiteDataManager.new_ephemeral()
        context = WebKit2.WebContext.new_with_website_data_manager(manager)
        self.webview = WebKit2.WebView.new_with_context(context)

        settings = WebKit2.Settings()
        settings.set_enable_javascript(False)
        settings.set_enable_java(False)
        settings.set_enable_plugins(False)
        self.webview.set_settings(settings)

        self.webview.connect('context_menu', self.block_context_menu)

        policy_file = 'file://%s' % policy_file
        self.webview.load_uri(policy_file)

        # TODO: The content area does not seem to resize its child elements
        # automatically?
        self.webview.set_size_request(-1, 590)

        self.get_content_area().add(self.webview)
        self.get_content_area().show_all()

        self.show()


    def block_context_menu(self, webview, context_menu, event, hit_test_result):
        # Completely block the context menu
        return True
