# Makefile for PO directory in any package using GNU gettext.
# Copyright (C) 1995-1997, 2000-2007, 2009-2010 by Ulrich Drepper <drepper@gnu.ai.mit.edu>
#
# Copying and distribution of this file, with or without modification,
# are permitted in any medium without royalty provided the copyright
# notice and this notice are preserved.  This file is offered as-is,
# without any warranty.
#
# Origin: gettext-0.19.7
GETTEXT_MACRO_VERSION = 0.19

PACKAGE = gtk+
VERSION = 3.24.5
PACKAGE_BUGREPORT = http://bugzilla.gnome.org/enter_bug.cgi?product=gtk%2B

SED = /usr/bin/sed
SHELL = /bin/sh


srcdir = ../../../../po
top_srcdir = ../../../..
VPATH = ../../../../po

prefix = /usr
exec_prefix = ${prefix}
datarootdir = ${prefix}/share
datadir = ${datarootdir}
localedir = ${datarootdir}/locale
gettextsrcdir = $(datadir)/gettext/po

INSTALL = /usr/bin/install -c
INSTALL_DATA = ${INSTALL} -m 644

# We use $(mkdir_p).
# In automake <= 1.9.x, $(mkdir_p) is defined either as "mkdir -p --" or as
# "$(mkinstalldirs)" or as "$(install_sh) -d". For these automake versions,
# ${SHELL} /state/adm-home/adm-juhaerk/src/gtk/gtk+3.0-3.24.5/build-aux/install-sh does not start with $(SHELL), so we add it.
# In automake >= 1.10, $(MKDIR_P) is derived from ${MKDIR_P}, which is defined
# either as "/path/to/mkdir -p" or ".../install-sh -c -d". For these automake
# versions, $(mkinstalldirs) and $(install_sh) are unused.
mkinstalldirs = $(SHELL) ${SHELL} /state/adm-home/adm-juhaerk/src/gtk/gtk+3.0-3.24.5/build-aux/install-sh -d
install_sh = $(SHELL) ${SHELL} /state/adm-home/adm-juhaerk/src/gtk/gtk+3.0-3.24.5/build-aux/install-sh
MKDIR_P = /usr/bin/mkdir -p
mkdir_p = $(MKDIR_P)

# When building gettext-tools, we prefer to use the built programs
# rather than installed programs.  However, we can't do that when we
# are cross compiling.
CROSS_COMPILING = @CROSS_COMPILING@

GMSGFMT_ = /usr/bin/msgfmt
GMSGFMT_no = /usr/bin/msgfmt
GMSGFMT_yes = /usr/bin/msgfmt
GMSGFMT = $(GMSGFMT_$(USE_MSGCTXT))
MSGFMT_ = /usr/bin/msgfmt
MSGFMT_no = /usr/bin/msgfmt
MSGFMT_yes = /usr/bin/msgfmt
MSGFMT = $(MSGFMT_$(USE_MSGCTXT))
XGETTEXT_ = /usr/bin/xgettext
XGETTEXT_no = /usr/bin/xgettext
XGETTEXT_yes = /usr/bin/xgettext
XGETTEXT = $(XGETTEXT_$(USE_MSGCTXT))
MSGMERGE = msgmerge
MSGMERGE_UPDATE = /usr/bin/msgmerge --update
MSGINIT = msginit
MSGCONV = msgconv
MSGFILTER = msgfilter

POFILES =  $(srcdir)/af.po $(srcdir)/am.po $(srcdir)/an.po $(srcdir)/ang.po $(srcdir)/ar.po $(srcdir)/as.po $(srcdir)/ast.po $(srcdir)/az.po $(srcdir)/az_IR.po $(srcdir)/be.po $(srcdir)/be@latin.po $(srcdir)/bg.po $(srcdir)/bn.po $(srcdir)/bn_IN.po $(srcdir)/br.po $(srcdir)/bs.po $(srcdir)/ca.po $(srcdir)/ca@valencia.po $(srcdir)/crh.po $(srcdir)/cs.po $(srcdir)/cy.po $(srcdir)/da.po $(srcdir)/de.po $(srcdir)/dz.po $(srcdir)/el.po $(srcdir)/en.po $(srcdir)/en_CA.po $(srcdir)/en_GB.po $(srcdir)/en@shaw.po $(srcdir)/eo.po $(srcdir)/es.po $(srcdir)/et.po $(srcdir)/eu.po $(srcdir)/fa.po $(srcdir)/fi.po $(srcdir)/fr.po $(srcdir)/fur.po $(srcdir)/ga.po $(srcdir)/gd.po $(srcdir)/gl.po $(srcdir)/gu.po $(srcdir)/he.po $(srcdir)/hi.po $(srcdir)/hr.po $(srcdir)/hu.po $(srcdir)/hy.po $(srcdir)/ia.po $(srcdir)/id.po $(srcdir)/io.po $(srcdir)/is.po $(srcdir)/it.po $(srcdir)/ja.po $(srcdir)/ka.po $(srcdir)/kg.po $(srcdir)/kk.po $(srcdir)/km.po $(srcdir)/kn.po $(srcdir)/ko.po $(srcdir)/ku.po $(srcdir)/ky.po $(srcdir)/lg.po $(srcdir)/li.po $(srcdir)/lt.po $(srcdir)/lv.po $(srcdir)/mai.po $(srcdir)/mi.po $(srcdir)/mk.po $(srcdir)/ml.po $(srcdir)/mn.po $(srcdir)/mr.po $(srcdir)/ms.po $(srcdir)/my.po $(srcdir)/nb.po $(srcdir)/nds.po $(srcdir)/ne.po $(srcdir)/nl.po $(srcdir)/nn.po $(srcdir)/nso.po $(srcdir)/oc.po $(srcdir)/or.po $(srcdir)/pa.po $(srcdir)/pl.po $(srcdir)/ps.po $(srcdir)/pt.po $(srcdir)/pt_BR.po $(srcdir)/ro.po $(srcdir)/ru.po $(srcdir)/rw.po $(srcdir)/si.po $(srcdir)/sk.po $(srcdir)/sl.po $(srcdir)/sq.po $(srcdir)/sr.po $(srcdir)/sr@ije.po $(srcdir)/sr@latin.po $(srcdir)/sv.po $(srcdir)/ta.po $(srcdir)/te.po $(srcdir)/tg.po $(srcdir)/th.po $(srcdir)/tk.po $(srcdir)/tr.po $(srcdir)/tt.po $(srcdir)/ug.po $(srcdir)/uk.po $(srcdir)/ur.po $(srcdir)/uz.po $(srcdir)/uz@cyrillic.po $(srcdir)/vi.po $(srcdir)/wa.po $(srcdir)/xh.po $(srcdir)/yi.po $(srcdir)/zh_CN.po $(srcdir)/zh_HK.po $(srcdir)/zh_TW.po
GMOFILES =  $(srcdir)/af.gmo $(srcdir)/am.gmo $(srcdir)/an.gmo $(srcdir)/ang.gmo $(srcdir)/ar.gmo $(srcdir)/as.gmo $(srcdir)/ast.gmo $(srcdir)/az.gmo $(srcdir)/az_IR.gmo $(srcdir)/be.gmo $(srcdir)/be@latin.gmo $(srcdir)/bg.gmo $(srcdir)/bn.gmo $(srcdir)/bn_IN.gmo $(srcdir)/br.gmo $(srcdir)/bs.gmo $(srcdir)/ca.gmo $(srcdir)/ca@valencia.gmo $(srcdir)/crh.gmo $(srcdir)/cs.gmo $(srcdir)/cy.gmo $(srcdir)/da.gmo $(srcdir)/de.gmo $(srcdir)/dz.gmo $(srcdir)/el.gmo $(srcdir)/en.gmo $(srcdir)/en_CA.gmo $(srcdir)/en_GB.gmo $(srcdir)/en@shaw.gmo $(srcdir)/eo.gmo $(srcdir)/es.gmo $(srcdir)/et.gmo $(srcdir)/eu.gmo $(srcdir)/fa.gmo $(srcdir)/fi.gmo $(srcdir)/fr.gmo $(srcdir)/fur.gmo $(srcdir)/ga.gmo $(srcdir)/gd.gmo $(srcdir)/gl.gmo $(srcdir)/gu.gmo $(srcdir)/he.gmo $(srcdir)/hi.gmo $(srcdir)/hr.gmo $(srcdir)/hu.gmo $(srcdir)/hy.gmo $(srcdir)/ia.gmo $(srcdir)/id.gmo $(srcdir)/io.gmo $(srcdir)/is.gmo $(srcdir)/it.gmo $(srcdir)/ja.gmo $(srcdir)/ka.gmo $(srcdir)/kg.gmo $(srcdir)/kk.gmo $(srcdir)/km.gmo $(srcdir)/kn.gmo $(srcdir)/ko.gmo $(srcdir)/ku.gmo $(srcdir)/ky.gmo $(srcdir)/lg.gmo $(srcdir)/li.gmo $(srcdir)/lt.gmo $(srcdir)/lv.gmo $(srcdir)/mai.gmo $(srcdir)/mi.gmo $(srcdir)/mk.gmo $(srcdir)/ml.gmo $(srcdir)/mn.gmo $(srcdir)/mr.gmo $(srcdir)/ms.gmo $(srcdir)/my.gmo $(srcdir)/nb.gmo $(srcdir)/nds.gmo $(srcdir)/ne.gmo $(srcdir)/nl.gmo $(srcdir)/nn.gmo $(srcdir)/nso.gmo $(srcdir)/oc.gmo $(srcdir)/or.gmo $(srcdir)/pa.gmo $(srcdir)/pl.gmo $(srcdir)/ps.gmo $(srcdir)/pt.gmo $(srcdir)/pt_BR.gmo $(srcdir)/ro.gmo $(srcdir)/ru.gmo $(srcdir)/rw.gmo $(srcdir)/si.gmo $(srcdir)/sk.gmo $(srcdir)/sl.gmo $(srcdir)/sq.gmo $(srcdir)/sr.gmo $(srcdir)/sr@ije.gmo $(srcdir)/sr@latin.gmo $(srcdir)/sv.gmo $(srcdir)/ta.gmo $(srcdir)/te.gmo $(srcdir)/tg.gmo $(srcdir)/th.gmo $(srcdir)/tk.gmo $(srcdir)/tr.gmo $(srcdir)/tt.gmo $(srcdir)/ug.gmo $(srcdir)/uk.gmo $(srcdir)/ur.gmo $(srcdir)/uz.gmo $(srcdir)/uz@cyrillic.gmo $(srcdir)/vi.gmo $(srcdir)/wa.gmo $(srcdir)/xh.gmo $(srcdir)/yi.gmo $(srcdir)/zh_CN.gmo $(srcdir)/zh_HK.gmo $(srcdir)/zh_TW.gmo
UPDATEPOFILES =  af.po-update am.po-update an.po-update ang.po-update ar.po-update as.po-update ast.po-update az.po-update az_IR.po-update be.po-update be@latin.po-update bg.po-update bn.po-update bn_IN.po-update br.po-update bs.po-update ca.po-update ca@valencia.po-update crh.po-update cs.po-update cy.po-update da.po-update de.po-update dz.po-update el.po-update en.po-update en_CA.po-update en_GB.po-update en@shaw.po-update eo.po-update es.po-update et.po-update eu.po-update fa.po-update fi.po-update fr.po-update fur.po-update ga.po-update gd.po-update gl.po-update gu.po-update he.po-update hi.po-update hr.po-update hu.po-update hy.po-update ia.po-update id.po-update io.po-update is.po-update it.po-update ja.po-update ka.po-update kg.po-update kk.po-update km.po-update kn.po-update ko.po-update ku.po-update ky.po-update lg.po-update li.po-update lt.po-update lv.po-update mai.po-update mi.po-update mk.po-update ml.po-update mn.po-update mr.po-update ms.po-update my.po-update nb.po-update nds.po-update ne.po-update nl.po-update nn.po-update nso.po-update oc.po-update or.po-update pa.po-update pl.po-update ps.po-update pt.po-update pt_BR.po-update ro.po-update ru.po-update rw.po-update si.po-update sk.po-update sl.po-update sq.po-update sr.po-update sr@ije.po-update sr@latin.po-update sv.po-update ta.po-update te.po-update tg.po-update th.po-update tk.po-update tr.po-update tt.po-update ug.po-update uk.po-update ur.po-update uz.po-update uz@cyrillic.po-update vi.po-update wa.po-update xh.po-update yi.po-update zh_CN.po-update zh_HK.po-update zh_TW.po-update
DUMMYPOFILES =  af.nop am.nop an.nop ang.nop ar.nop as.nop ast.nop az.nop az_IR.nop be.nop be@latin.nop bg.nop bn.nop bn_IN.nop br.nop bs.nop ca.nop ca@valencia.nop crh.nop cs.nop cy.nop da.nop de.nop dz.nop el.nop en.nop en_CA.nop en_GB.nop en@shaw.nop eo.nop es.nop et.nop eu.nop fa.nop fi.nop fr.nop fur.nop ga.nop gd.nop gl.nop gu.nop he.nop hi.nop hr.nop hu.nop hy.nop ia.nop id.nop io.nop is.nop it.nop ja.nop ka.nop kg.nop kk.nop km.nop kn.nop ko.nop ku.nop ky.nop lg.nop li.nop lt.nop lv.nop mai.nop mi.nop mk.nop ml.nop mn.nop mr.nop ms.nop my.nop nb.nop nds.nop ne.nop nl.nop nn.nop nso.nop oc.nop or.nop pa.nop pl.nop ps.nop pt.nop pt_BR.nop ro.nop ru.nop rw.nop si.nop sk.nop sl.nop sq.nop sr.nop sr@ije.nop sr@latin.nop sv.nop ta.nop te.nop tg.nop th.nop tk.nop tr.nop tt.nop ug.nop uk.nop ur.nop uz.nop uz@cyrillic.nop vi.nop wa.nop xh.nop yi.nop zh_CN.nop zh_HK.nop zh_TW.nop
DISTFILES.common = Makefile.in.in remove-potcdate.sin \
$(DISTFILES.common.extra1) $(DISTFILES.common.extra2) $(DISTFILES.common.extra3)
DISTFILES = $(DISTFILES.common) Makevars POTFILES.in \
$(POFILES) $(GMOFILES) \
$(DISTFILES.extra1) $(DISTFILES.extra2) $(DISTFILES.extra3)

POTFILES = \
     ../../../../gdk/broadway/gdkbroadway-server.c \
     ../../../../gdk/gdkapplaunchcontext.c \
     ../../../../gdk/gdk.c \
     ../../../../gdk/gdkcursor.c \
     ../../../../gdk/gdkdevice.c \
     ../../../../gdk/gdkdevicemanager.c \
     ../../../../gdk/gdkdisplaymanager.c \
     ../../../../gdk/gdkdnd.c \
     ../../../../gdk/gdkglcontext.c \
     ../../../../gdk/gdkpango.c \
     ../../../../gdk/gdkscreen.c \
     ../../../../gdk/gdkseat.c \
     ../../../../gdk/gdkwindow.c \
     ../../../../gdk/keyname-table.h \
     ../../../../gdk/mir/gdkmirglcontext.c \
     ../../../../gdk/mir/gdkmirwindowimpl.c \
     ../../../../gdk/quartz/gdkglcontext-quartz.c \
     ../../../../gdk/wayland/gdkglcontext-wayland.c \
     ../../../../gdk/win32/gdkglcontext-win32.c \
     ../../../../gdk/win32/gdkmain-win32.c \
     ../../../../gdk/x11/gdkapplaunchcontext-x11.c \
     ../../../../gdk/x11/gdkdevicemanager-xi2.c \
     ../../../../gdk/x11/gdkdevice-xi2.c \
     ../../../../gdk/x11/gdkglcontext-x11.c \
     ../../../../gdk/x11/gdkmain-x11.c \
     ../../../../gtk/a11y/gtkbooleancellaccessible.c \
     ../../../../gtk/a11y/gtkbuttonaccessible.c \
     ../../../../gtk/a11y/gtkcellaccessible.c \
     ../../../../gtk/a11y/gtkcolorswatchaccessible.c \
     ../../../../gtk/a11y/gtkcomboboxaccessible.c \
     ../../../../gtk/a11y/gtkentryaccessible.c \
     ../../../../gtk/a11y/gtkexpanderaccessible.c \
     ../../../../gtk/a11y/gtkimageaccessible.c \
     ../../../../gtk/a11y/gtkmenubuttonaccessible.c \
     ../../../../gtk/a11y/gtkmenuitemaccessible.c \
     ../../../../gtk/a11y/gtkrenderercellaccessible.c \
     ../../../../gtk/a11y/gtkscalebuttonaccessible.c \
     ../../../../gtk/a11y/gtkspinneraccessible.c \
     ../../../../gtk/a11y/gtkswitchaccessible.c \
     ../../../../gtk/deprecated/gtkaction.c \
     ../../../../gtk/deprecated/gtkactiongroup.c \
     ../../../../gtk/deprecated/gtkactivatable.c \
     ../../../../gtk/deprecated/gtkalignment.c \
     ../../../../gtk/deprecated/gtkarrow.c \
     ../../../../gtk/deprecated/gtkcolorsel.c \
     ../../../../gtk/deprecated/gtkcolorseldialog.c \
     ../../../../gtk/deprecated/gtkfontsel.c \
     ../../../../gtk/deprecated/gtkhandlebox.c \
     ../../../../gtk/deprecated/gtkhsv.c \
     ../../../../gtk/deprecated/gtkiconfactory.c \
     ../../../../gtk/deprecated/gtkimagemenuitem.c \
     ../../../../gtk/deprecated/gtkmisc.c \
     ../../../../gtk/deprecated/gtknumerableicon.c \
     ../../../../gtk/deprecated/gtkradioaction.c \
     ../../../../gtk/deprecated/gtkrecentaction.c \
     ../../../../gtk/deprecated/gtkstatusicon.c \
     ../../../../gtk/deprecated/gtkstock.c \
     ../../../../gtk/deprecated/gtkstyle.c \
     ../../../../gtk/deprecated/gtktable.c \
     ../../../../gtk/deprecated/gtkthemingengine.c \
     ../../../../gtk/deprecated/gtktoggleaction.c \
     ../../../../gtk/deprecated/gtktrayicon-x11.c \
     ../../../../gtk/deprecated/gtkuimanager.c \
     ../../../../gtk/encodesymbolic.c \
     ../../../../gtk/gtkaboutdialog.c \
     ../../../../gtk/gtkaccelgroup.c \
     ../../../../gtk/gtkaccellabel.c \
     ../../../../gtk/gtkaccelmap.c \
     ../../../../gtk/gtkaccessible.c \
     ../../../../gtk/gtkactionable.c \
     ../../../../gtk/gtkactionbar.c \
     ../../../../gtk/gtkactionmuxer.c \
     ../../../../gtk/gtkadjustment.c \
     ../../../../gtk/gtkappchooserbutton.c \
     ../../../../gtk/gtkappchooser.c \
     ../../../../gtk/gtkappchooserdialog.c \
     ../../../../gtk/gtkappchooserwidget.c \
     ../../../../gtk/gtkapplication.c \
     ../../../../gtk/gtkapplication-quartz.c \
     ../../../../gtk/gtkapplicationwindow.c \
     ../../../../gtk/gtkaspectframe.c \
     ../../../../gtk/gtkassistant.c \
     ../../../../gtk/gtkbbox.c \
     ../../../../gtk/gtkbin.c \
     ../../../../gtk/gtkbindings.c \
     ../../../../gtk/gtkbookmarksmanager.c \
     ../../../../gtk/gtkbox.c \
     ../../../../gtk/gtkbuildable.c \
     ../../../../gtk/gtkbuilder.c \
     ../../../../gtk/gtkbuilder-menus.c \
     ../../../../gtk/gtkbuilderparser.c \
     ../../../../gtk/gtk-builder-tool.c \
     ../../../../gtk/gtkbutton.c \
     ../../../../gtk/gtkcalendar.c \
     ../../../../gtk/gtkcellareabox.c \
     ../../../../gtk/gtkcellarea.c \
     ../../../../gtk/gtkcellareacontext.c \
     ../../../../gtk/gtkcelleditable.c \
     ../../../../gtk/gtkcelllayout.c \
     ../../../../gtk/gtkcellrendereraccel.c \
     ../../../../gtk/gtkcellrenderer.c \
     ../../../../gtk/gtkcellrenderercombo.c \
     ../../../../gtk/gtkcellrendererpixbuf.c \
     ../../../../gtk/gtkcellrendererprogress.c \
     ../../../../gtk/gtkcellrendererspin.c \
     ../../../../gtk/gtkcellrendererspinner.c \
     ../../../../gtk/gtkcellrenderertext.c \
     ../../../../gtk/gtkcellrenderertoggle.c \
     ../../../../gtk/gtkcellview.c \
     ../../../../gtk/gtkcheckbutton.c \
     ../../../../gtk/gtkcheckmenuitem.c \
     ../../../../gtk/gtkclipboard.c \
     ../../../../gtk/gtkclipboard-quartz.c \
     ../../../../gtk/gtkcolorbutton.c \
     ../../../../gtk/gtkcolorchooser.c \
     ../../../../gtk/gtkcolorchooserdialog.c \
     ../../../../gtk/gtkcolorchooserwidget.c \
     ../../../../gtk/gtkcoloreditor.c \
     ../../../../gtk/gtkcolorplane.c \
     ../../../../gtk/gtkcolorscale.c \
     ../../../../gtk/gtkcolorswatch.c \
     ../../../../gtk/gtkcombobox.c \
     ../../../../gtk/gtkcontainer.c \
     ../../../../gtk/gtkcssnode.c \
     ../../../../gtk/gtkcssprovider.c \
     ../../../../gtk/gtkcssshorthandproperty.c \
     ../../../../gtk/gtkcssstyleproperty.c \
     ../../../../gtk/gtkcustompaperunixdialog.c \
     ../../../../gtk/gtkdialog.c \
     ../../../../gtk/gtkdnd.c \
     ../../../../gtk/gtkdnd-quartz.c \
     ../../../../gtk/gtkdragdest.c \
     ../../../../gtk/gtkdragsource.c \
     ../../../../gtk/gtkdrawingarea.c \
     ../../../../gtk/gtkeditable.c \
     ../../../../gtk/gtkemojichooser.c \
     ../../../../gtk/gtkemojicompletion.c \
     ../../../../gtk/gtkentrybuffer.c \
     ../../../../gtk/gtkentry.c \
     ../../../../gtk/gtkentrycompletion.c \
     ../../../../gtk/gtkeventbox.c \
     ../../../../gtk/gtkeventcontroller.c \
     ../../../../gtk/gtkeventcontrollerkey.c \
     ../../../../gtk/gtkeventcontrollermotion.c \
     ../../../../gtk/gtkeventcontrollerscroll.c \
     ../../../../gtk/gtkexpander.c \
     ../../../../gtk/gtkfilechooserbutton.c \
     ../../../../gtk/gtkfilechooser.c \
     ../../../../gtk/gtkfilechooserdialog.c \
     ../../../../gtk/gtkfilechooserembed.c \
     ../../../../gtk/gtkfilechooserentry.c \
     ../../../../gtk/gtkfilechoosernative.c \
     ../../../../gtk/gtkfilechoosernativequartz.c \
     ../../../../gtk/gtkfilechooserutils.c \
     ../../../../gtk/gtkfilechooserwidget.c \
     ../../../../gtk/gtkfilefilter.c \
     ../../../../gtk/gtkfilesystem.c \
     ../../../../gtk/gtkfilesystemmodel.c \
     ../../../../gtk/gtkfixed.c \
     ../../../../gtk/gtkflowbox.c \
     ../../../../gtk/gtkfontbutton.c \
     ../../../../gtk/gtkfontchooser.c \
     ../../../../gtk/gtkfontchooserdialog.c \
     ../../../../gtk/gtkfontchooserwidget.c \
     ../../../../gtk/gtkframe.c \
     ../../../../gtk/gtkgesture.c \
     ../../../../gtk/gtkgesturedrag.c \
     ../../../../gtk/gtkgesturelongpress.c \
     ../../../../gtk/gtkgesturemultipress.c \
     ../../../../gtk/gtkgesturepan.c \
     ../../../../gtk/gtkgesturerotate.c \
     ../../../../gtk/gtkgesturesingle.c \
     ../../../../gtk/gtkgesturestylus.c \
     ../../../../gtk/gtkgestureswipe.c \
     ../../../../gtk/gtkgesturezoom.c \
     ../../../../gtk/gtkglarea.c \
     ../../../../gtk/gtkgrid.c \
     ../../../../gtk/gtkheaderbar.c \
     ../../../../gtk/gtkicontheme.c \
     ../../../../gtk/gtkiconview.c \
     ../../../../gtk/gtkimage.c \
     ../../../../gtk/gtkimcontext.c \
     ../../../../gtk/gtkimcontextsimple.c \
     ../../../../gtk/gtkimmodule.c \
     ../../../../gtk/gtkimmulticontext.c \
     ../../../../gtk/gtkinfobar.c \
     ../../../../gtk/gtkinvisible.c \
     ../../../../gtk/gtklabel.c \
     ../../../../gtk/gtk-launch.c \
     ../../../../gtk/gtklayout.c \
     ../../../../gtk/gtklevelbar.c \
     ../../../../gtk/gtklinkbutton.c \
     ../../../../gtk/gtklistbox.c \
     ../../../../gtk/gtkliststore.c \
     ../../../../gtk/gtklockbutton.c \
     ../../../../gtk/gtkmagnifier.c \
     ../../../../gtk/gtkmain.c \
     ../../../../gtk/gtkmenubar.c \
     ../../../../gtk/gtkmenubutton.c \
     ../../../../gtk/gtkmenu.c \
     ../../../../gtk/gtkmenuitem.c \
     ../../../../gtk/gtkmenushell.c \
     ../../../../gtk/gtkmenutoolbutton.c \
     ../../../../gtk/gtkmessagedialog.c \
     ../../../../gtk/gtkmodelbutton.c \
     ../../../../gtk/gtkmodifierstyle.c \
     ../../../../gtk/gtkmodules.c \
     ../../../../gtk/gtkmountoperation.c \
     ../../../../gtk/gtkmountoperation-stub.c \
     ../../../../gtk/gtkmountoperation-x11.c \
     ../../../../gtk/gtknativedialog.c \
     ../../../../gtk/gtknotebook.c \
     ../../../../gtk/gtkorientable.c \
     ../../../../gtk/gtkoverlay.c \
     ../../../../gtk/gtkpadcontroller.c \
     ../../../../gtk/gtkpagesetup.c \
     ../../../../gtk/gtkpagesetupunixdialog.c \
     ../../../../gtk/gtkpaned.c \
     ../../../../gtk/gtkpapersize.c \
     ../../../../gtk/gtkpathbar.c \
     ../../../../gtk/gtkplacessidebar.c \
     ../../../../gtk/gtkplacesview.c \
     ../../../../gtk/gtkplacesviewrow.c \
     ../../../../gtk/gtkplug.c \
     ../../../../gtk/gtkpopover.c \
     ../../../../gtk/gtkpopovermenu.c \
     ../../../../gtk/gtkprintbackend.c \
     ../../../../gtk/gtkprinter.c \
     ../../../../gtk/gtkprinteroption.c \
     ../../../../gtk/gtkprinteroptionset.c \
     ../../../../gtk/gtkprinteroptionwidget.c \
     ../../../../gtk/gtkprintjob.c \
     ../../../../gtk/gtkprintoperation.c \
     ../../../../gtk/gtkprintoperation-portal.c \
     ../../../../gtk/gtkprintoperationpreview.c \
     ../../../../gtk/gtkprintoperation-unix.c \
     ../../../../gtk/gtkprintoperation-win32.c \
     ../../../../gtk/gtkprintunixdialog.c \
     ../../../../gtk/gtkprogressbar.c \
     ../../../../gtk/gtkradiobutton.c \
     ../../../../gtk/gtkradiomenuitem.c \
     ../../../../gtk/gtkradiotoolbutton.c \
     ../../../../gtk/gtkrange.c \
     ../../../../gtk/gtkrecentchooser.c \
     ../../../../gtk/gtkrecentchooserdefault.c \
     ../../../../gtk/gtkrecentchoosermenu.c \
     ../../../../gtk/gtkrecentmanager.c \
     ../../../../gtk/gtkrevealer.c \
     ../../../../gtk/gtkscalebutton.c \
     ../../../../gtk/gtkscale.c \
     ../../../../gtk/gtkscrollable.c \
     ../../../../gtk/gtkscrollbar.c \
     ../../../../gtk/gtkscrolledwindow.c \
     ../../../../gtk/gtksearchbar.c \
     ../../../../gtk/gtksearchengine.c \
     ../../../../gtk/gtksearchentry.c \
     ../../../../gtk/gtkselection.c \
     ../../../../gtk/gtkseparator.c \
     ../../../../gtk/gtkseparatortoolitem.c \
     ../../../../gtk/gtksettings.c \
     ../../../../gtk/gtkshortcutlabel.c \
     ../../../../gtk/gtkshortcutsgroup.c \
     ../../../../gtk/gtkshortcutssection.c \
     ../../../../gtk/gtkshortcutsshortcut.c \
     ../../../../gtk/gtkshortcutswindow.c \
     ../../../../gtk/gtksizegroup.c \
     ../../../../gtk/gtksizerequest.c \
     ../../../../gtk/gtksocket.c \
     ../../../../gtk/gtkspinbutton.c \
     ../../../../gtk/gtkspinner.c \
     ../../../../gtk/gtkstack.c \
     ../../../../gtk/gtkstacksidebar.c \
     ../../../../gtk/gtkstackswitcher.c \
     ../../../../gtk/gtkstatusbar.c \
     ../../../../gtk/gtkstylecontext.c \
     ../../../../gtk/gtkstyleproperty.c \
     ../../../../gtk/gtkstyleprovider.c \
     ../../../../gtk/gtkstyleproviderprivate.c \
     ../../../../gtk/gtkswitch.c \
     ../../../../gtk/gtktextbuffer.c \
     ../../../../gtk/gtktextbufferrichtext.c \
     ../../../../gtk/gtktextbufferserialize.c \
     ../../../../gtk/gtktextchild.c \
     ../../../../gtk/gtktextdisplay.c \
     ../../../../gtk/gtktexthandle.c \
     ../../../../gtk/gtktextiter.c \
     ../../../../gtk/gtktextlayout.c \
     ../../../../gtk/gtktextmark.c \
     ../../../../gtk/gtktexttag.c \
     ../../../../gtk/gtktexttagtable.c \
     ../../../../gtk/gtktextutil.c \
     ../../../../gtk/gtktextview.c \
     ../../../../gtk/gtktogglebutton.c \
     ../../../../gtk/gtktoggletoolbutton.c \
     ../../../../gtk/gtktoolbar.c \
     ../../../../gtk/gtktoolbutton.c \
     ../../../../gtk/gtktoolitem.c \
     ../../../../gtk/gtktoolitemgroup.c \
     ../../../../gtk/gtktoolpalette.c \
     ../../../../gtk/gtktoolshell.c \
     ../../../../gtk/gtktooltipwindow.c \
     ../../../../gtk/gtktrashmonitor.c \
     ../../../../gtk/gtktreednd.c \
     ../../../../gtk/gtktreemenu.c \
     ../../../../gtk/gtktreemodel.c \
     ../../../../gtk/gtktreemodelfilter.c \
     ../../../../gtk/gtktreemodelsort.c \
     ../../../../gtk/gtktreeselection.c \
     ../../../../gtk/gtktreesortable.c \
     ../../../../gtk/gtktreestore.c \
     ../../../../gtk/gtktreeview.c \
     ../../../../gtk/gtktreeviewcolumn.c \
     ../../../../gtk/gtkviewport.c \
     ../../../../gtk/gtkvolumebutton.c \
     ../../../../gtk/gtkwidget.c \
     ../../../../gtk/gtkwindow.c \
     ../../../../gtk/inspector/action-editor.c \
     ../../../../gtk/inspector/actions.ui \
     ../../../../gtk/inspector/css-editor.c \
     ../../../../gtk/inspector/css-editor.ui \
     ../../../../gtk/inspector/css-node-tree.c \
     ../../../../gtk/inspector/css-node-tree.ui \
     ../../../../gtk/inspector/data-list.ui \
     ../../../../gtk/inspector/general.c \
     ../../../../gtk/inspector/general.ui \
     ../../../../gtk/inspector/gestures.c \
     ../../../../gtk/inspector/gtkstackcombo.c \
     ../../../../gtk/inspector/inspect-button.c \
     ../../../../gtk/inspector/magnifier.ui \
     ../../../../gtk/inspector/menu.c \
     ../../../../gtk/inspector/menu.ui \
     ../../../../gtk/inspector/misc-info.c \
     ../../../../gtk/inspector/misc-info.ui \
     ../../../../gtk/inspector/object-hierarchy.ui \
     ../../../../gtk/inspector/object-tree.ui \
     ../../../../gtk/inspector/prop-editor.c \
     ../../../../gtk/inspector/prop-list.ui \
     ../../../../gtk/inspector/resource-list.ui \
     ../../../../gtk/inspector/selector.ui \
     ../../../../gtk/inspector/signals-list.c \
     ../../../../gtk/inspector/signals-list.ui \
     ../../../../gtk/inspector/size-groups.c \
     ../../../../gtk/inspector/statistics.c \
     ../../../../gtk/inspector/statistics.ui \
     ../../../../gtk/inspector/visual.c \
     ../../../../gtk/inspector/visual.ui \
     ../../../../gtk/inspector/window.c \
     ../../../../gtk/inspector/window.ui \
     ../../../../gtk/open-type-layout.h \
     ../../../../gtk/paper_names_offsets.c \
     ../../../../gtk/script-names.c \
     ../../../../gtk/ui/gtkaboutdialog.ui \
     ../../../../gtk/ui/gtkappchooserdialog.ui \
     ../../../../gtk/ui/gtkappchooserwidget.ui \
     ../../../../gtk/ui/gtkapplication-quartz.ui \
     ../../../../gtk/ui/gtkassistant.ui \
     ../../../../gtk/ui/gtkcolorchooserdialog.ui \
     ../../../../gtk/ui/gtkcoloreditor.ui \
     ../../../../gtk/ui/gtkdialog.ui \
     ../../../../gtk/ui/gtkemojichooser.ui \
     ../../../../gtk/ui/gtkemojicompletion.ui \
     ../../../../gtk/ui/gtkfilechooserbutton.ui \
     ../../../../gtk/ui/gtkfilechooserdialog.ui \
     ../../../../gtk/ui/gtkfilechooserwidget.ui \
     ../../../../gtk/ui/gtkfontbutton.ui \
     ../../../../gtk/ui/gtkfontchooserdialog.ui \
     ../../../../gtk/ui/gtkfontchooserwidget.ui \
     ../../../../gtk/ui/gtkinfobar.ui \
     ../../../../gtk/ui/gtklockbutton.ui \
     ../../../../gtk/ui/gtkmessagedialog.ui \
     ../../../../gtk/ui/gtkpagesetupunixdialog.ui \
     ../../../../gtk/ui/gtkpathbar.ui \
     ../../../../gtk/ui/gtkplacesviewrow.ui \
     ../../../../gtk/ui/gtkplacesview.ui \
     ../../../../gtk/ui/gtkprintunixdialog.ui \
     ../../../../gtk/ui/gtkrecentchooserdefault.ui \
     ../../../../gtk/ui/gtkscalebutton.ui \
     ../../../../gtk/ui/gtksidebarrow.ui \
     ../../../../gtk/ui/gtkstatusbar.ui \
     ../../../../gtk/ui/gtkvolumebutton.ui \
     ../../../../gtk/updateiconcache.c \
     ../../../../modules/input/gtkimcontextxim.c \
     ../../../../modules/input/imam-et.c \
     ../../../../modules/input/imbroadway.c \
     ../../../../modules/input/imcedilla.c \
     ../../../../modules/input/imcyrillic-translit.c \
     ../../../../modules/input/imime.c \
     ../../../../modules/input/iminuktitut.c \
     ../../../../modules/input/imipa.c \
     ../../../../modules/input/immultipress.c \
     ../../../../modules/input/imquartz.c \
     ../../../../modules/input/imthai.c \
     ../../../../modules/input/imti-er.c \
     ../../../../modules/input/imti-et.c \
     ../../../../modules/input/imviqr.c \
     ../../../../modules/input/imwayland.c \
     ../../../../modules/input/imwaylandgtk.c \
     ../../../../modules/input/imxim.c \
     ../../../../modules/printbackends/cloudprint/gtkprintbackendcloudprint.c \
     ../../../../modules/printbackends/cloudprint/gtkprintercloudprint.c \
     ../../../../modules/printbackends/cups/gtkprintbackendcups.c \
     ../../../../modules/printbackends/cups/gtkprintercups.c \
     ../../../../modules/printbackends/file/gtkprintbackendfile.c \
     ../../../../modules/printbackends/lpr/gtkprintbackendlpr.c \
     ../../../../modules/printbackends/papi/gtkprintbackendpapi.c \
     ../../../../modules/printbackends/test/gtkprintbackendtest.c

CATALOGS =  af.gmo am.gmo an.gmo ang.gmo ar.gmo as.gmo ast.gmo az.gmo az_IR.gmo be.gmo be@latin.gmo bg.gmo bn.gmo bn_IN.gmo br.gmo bs.gmo ca.gmo ca@valencia.gmo crh.gmo cs.gmo cy.gmo da.gmo de.gmo dz.gmo el.gmo en.gmo en_CA.gmo en_GB.gmo en@shaw.gmo eo.gmo es.gmo et.gmo eu.gmo fa.gmo fi.gmo fr.gmo fur.gmo ga.gmo gd.gmo gl.gmo gu.gmo he.gmo hi.gmo hr.gmo hu.gmo hy.gmo ia.gmo id.gmo io.gmo is.gmo it.gmo ja.gmo ka.gmo kg.gmo kk.gmo km.gmo kn.gmo ko.gmo ku.gmo ky.gmo lg.gmo li.gmo lt.gmo lv.gmo mai.gmo mi.gmo mk.gmo ml.gmo mn.gmo mr.gmo ms.gmo my.gmo nb.gmo nds.gmo ne.gmo nl.gmo nn.gmo nso.gmo oc.gmo or.gmo pa.gmo pl.gmo ps.gmo pt.gmo pt_BR.gmo ro.gmo ru.gmo rw.gmo si.gmo sk.gmo sl.gmo sq.gmo sr.gmo sr@ije.gmo sr@latin.gmo sv.gmo ta.gmo te.gmo tg.gmo th.gmo tk.gmo tr.gmo tt.gmo ug.gmo uk.gmo ur.gmo uz.gmo uz@cyrillic.gmo vi.gmo wa.gmo xh.gmo yi.gmo zh_CN.gmo zh_HK.gmo zh_TW.gmo

POFILESDEPS_ = $(srcdir)/$(DOMAIN).pot
POFILESDEPS_yes = $(POFILESDEPS_)
POFILESDEPS_no =
POFILESDEPS = $(POFILESDEPS_$(PO_DEPENDS_ON_POT))

DISTFILESDEPS_ = update-po
DISTFILESDEPS_yes = $(DISTFILESDEPS_)
DISTFILESDEPS_no =
DISTFILESDEPS = $(DISTFILESDEPS_$(DIST_DEPENDS_ON_UPDATE_PO))

# Makevars gets inserted here. (Don't remove this line!)
# Makefile variables for PO directory in any package using GNU gettext.

# Usually the message domain is the same as the package name.
DOMAIN = gtk30

# These two variables depend on the location of this directory.
subdir = po
top_builddir = ..

# These options get passed to xgettext.
XGETTEXT_OPTIONS = --from-code=UTF-8 --keyword=_ --keyword=N_ --keyword=C_:1c,2 --keyword=NC_:1c,2 --keyword=g_dngettext:2,3 --add-comments

# This is the copyright holder that gets inserted into the header of the
# $(DOMAIN).pot file.  Set this to the copyright holder of the surrounding
# package.  (Note that the msgstr strings, extracted from the package's
# sources, belong to the copyright holder of the package.)  Translators are
# expected to transfer the copyright for their translations to this person
# or entity, or to disclaim their copyright.  The empty string stands for
# the public domain; in this case the translators are expected to disclaim
# their copyright.
COPYRIGHT_HOLDER = GTK+ Team and others. See AUTHORS

# This tells whether or not to prepend "GNU " prefix to the package
# name that gets inserted into the header of the $(DOMAIN).pot file.
# Possible values are "yes", "no", or empty.  If it is empty, try to
# detect it automatically by scanning the files in $(top_srcdir) for
# "GNU packagename" string.
PACKAGE_GNU = no

# This is the email address or URL to which the translators shall report
# bugs in the untranslated strings:
# - Strings which are not entire sentences, see the maintainer guidelines
#   in the GNU gettext documentation, section 'Preparing Strings'.
# - Strings which use unclear terms or require additional context to be
#   understood.
# - Strings which make invalid assumptions about notation of date, time or
#   money.
# - Pluralisation problems.
# - Incorrect English spelling.
# - Incorrect formatting.
# It can be your email address, or a mailing list address where translators
# can write to without being subscribed, or the URL of a web page through
# which the translators can contact you.
MSGID_BUGS_ADDRESS =

# This is the list of locale categories, beyond LC_MESSAGES, for which the
# message catalogs shall be used.  It is usually empty.
EXTRA_LOCALE_CATEGORIES =

# This tells whether the $(DOMAIN).pot file contains messages with an 'msgctxt'
# context.  Possible values are "yes" and "no".  Set this to yes if the
# package uses functions taking also a message context, like pgettext(), or
# if in $(XGETTEXT_OPTIONS) you define keywords with a context argument.
USE_MSGCTXT = yes

# These options get passed to msgmerge.
# Useful options are in particular:
#   --previous            to keep previous msgids of translated messages,
#   --quiet               to reduce the verbosity.
MSGMERGE_OPTIONS =

# These options get passed to msginit.
# If you want to disable line wrapping when writing PO files, add
# --no-wrap to MSGMERGE_OPTIONS, XGETTEXT_OPTIONS, and
# MSGINIT_OPTIONS.
MSGINIT_OPTIONS =

# This tells whether or not to regenerate a PO file when $(DOMAIN).pot
# has changed.  Possible values are "yes" and "no".  Set this to no if
# the POT file is checked in the repository and the version control
# program ignores timestamps.
PO_DEPENDS_ON_POT = no

# This tells whether or not to forcibly update $(DOMAIN).pot and
# regenerate PO files on "make dist".  Possible values are "yes" and
# "no".  Set this to no if the POT file and PO files are maintained
# externally.
DIST_DEPENDS_ON_UPDATE_PO = no

.SUFFIXES:
.SUFFIXES: .po .gmo .mo .sed .sin .nop .po-create .po-update

.po.mo:
	@echo "$(MSGFMT) -c -o $@ $<"; \
	$(MSGFMT) -c -o t-$@ $< && mv t-$@ $@

.po.gmo:
	@lang=`echo $* | sed -e 's,.*/,,'`; \
	test "$(srcdir)" = . && cdcmd="" || cdcmd="cd $(srcdir) && "; \
	echo "$${cdcmd}rm -f $${lang}.gmo && $(GMSGFMT) -c --statistics --verbose -o $${lang}.gmo $${lang}.po"; \
	cd $(srcdir) && rm -f $${lang}.gmo && $(GMSGFMT) -c --statistics --verbose -o t-$${lang}.gmo $${lang}.po && mv t-$${lang}.gmo $${lang}.gmo

.sin.sed:
	sed -e '/^#/d' $< > t-$@
	mv t-$@ $@


all: all-yes

all-yes: stamp-po
all-no:

# Ensure that the gettext macros and this Makefile.in.in are in sync.
CHECK_MACRO_VERSION = \
	test "$(GETTEXT_MACRO_VERSION)" = "0.19" \
	  || { echo "*** error: gettext infrastructure mismatch: using a Makefile.in.in from gettext version $(GETTEXT_MACRO_VERSION) but the autoconf macros are from gettext version 0.19" 1>&2; \
	       exit 1; \
	     }

# $(srcdir)/$(DOMAIN).pot is only created when needed. When xgettext finds no
# internationalized messages, no $(srcdir)/$(DOMAIN).pot is created (because
# we don't want to bother translators with empty POT files). We assume that
# LINGUAS is empty in this case, i.e. $(POFILES) and $(GMOFILES) are empty.
# In this case, stamp-po is a nop (i.e. a phony target).

# stamp-po is a timestamp denoting the last time at which the CATALOGS have
# been loosely updated. Its purpose is that when a developer or translator
# checks out the package via CVS, and the $(DOMAIN).pot file is not in CVS,
# "make" will update the $(DOMAIN).pot and the $(CATALOGS), but subsequent
# invocations of "make" will do nothing. This timestamp would not be necessary
# if updating the $(CATALOGS) would always touch them; however, the rule for
# $(POFILES) has been designed to not touch files that don't need to be
# changed.
stamp-po: $(srcdir)/$(DOMAIN).pot
	@$(CHECK_MACRO_VERSION)
	test ! -f $(srcdir)/$(DOMAIN).pot || \
	  test -z "$(GMOFILES)" || $(MAKE) $(GMOFILES)
	@test ! -f $(srcdir)/$(DOMAIN).pot || { \
	  echo "touch stamp-po" && \
	  echo timestamp > stamp-poT && \
	  mv stamp-poT stamp-po; \
	}

# Note: Target 'all' must not depend on target '$(DOMAIN).pot-update',
# otherwise packages like GCC can not be built if only parts of the source
# have been downloaded.

# This target rebuilds $(DOMAIN).pot; it is an expensive operation.
# Note that $(DOMAIN).pot is not touched if it doesn't need to be changed.
# The determination of whether the package xyz is a GNU one is based on the
# heuristic whether some file in the top level directory mentions "GNU xyz".
# If GNU 'find' is available, we avoid grepping through monster files.
$(DOMAIN).pot-update: $(POTFILES) $(srcdir)/POTFILES.in remove-potcdate.sed
	package_gnu="$(PACKAGE_GNU)"; \
	test -n "$$package_gnu" || { \
	  if { if (LC_ALL=C find --version) 2>/dev/null | grep GNU >/dev/null; then \
		 LC_ALL=C find -L $(top_srcdir) -maxdepth 1 -type f \
			       -size -10000000c -exec grep 'GNU gtk+' \
			       /dev/null '{}' ';' 2>/dev/null; \
	       else \
		 LC_ALL=C grep 'GNU gtk+' $(top_srcdir)/* 2>/dev/null; \
	       fi; \
	     } | grep -v 'libtool:' >/dev/null; then \
	     package_gnu=yes; \
	   else \
	     package_gnu=no; \
	   fi; \
	}; \
	if test "$$package_gnu" = "yes"; then \
	  package_prefix='GNU '; \
	else \
	  package_prefix=''; \
	fi; \
	if test -n '$(MSGID_BUGS_ADDRESS)' || test '$(PACKAGE_BUGREPORT)' = '@'PACKAGE_BUGREPORT'@'; then \
	  msgid_bugs_address='$(MSGID_BUGS_ADDRESS)'; \
	else \
	  msgid_bugs_address='$(PACKAGE_BUGREPORT)'; \
	fi; \
	case `$(XGETTEXT) --version | sed 1q | sed -e 's,^[^0-9]*,,'` in \
	  '' | 0.[0-9] | 0.[0-9].* | 0.1[0-5] | 0.1[0-5].* | 0.16 | 0.16.[0-1]*) \
	    $(XGETTEXT) --default-domain=$(DOMAIN) --directory=$(top_srcdir) \
	      --add-comments=TRANSLATORS: $(XGETTEXT_OPTIONS)  \
	      --files-from=$(srcdir)/POTFILES.in \
	      --copyright-holder='$(COPYRIGHT_HOLDER)' \
	      --msgid-bugs-address="$$msgid_bugs_address" \
	    ;; \
	  *) \
	    $(XGETTEXT) --default-domain=$(DOMAIN) --directory=$(top_srcdir) \
	      --add-comments=TRANSLATORS: $(XGETTEXT_OPTIONS)  \
	      --files-from=$(srcdir)/POTFILES.in \
	      --copyright-holder='$(COPYRIGHT_HOLDER)' \
	      --package-name="$${package_prefix}gtk+" \
	      --package-version='3.24.5' \
	      --msgid-bugs-address="$$msgid_bugs_address" \
	    ;; \
	esac
	test ! -f $(DOMAIN).po || { \
	  if test -f $(srcdir)/$(DOMAIN).pot-header; then \
	    sed -e '1,/^#$$/d' < $(DOMAIN).po > $(DOMAIN).1po && \
	    cat $(srcdir)/$(DOMAIN).pot-header $(DOMAIN).1po > $(DOMAIN).po; \
	    rm -f $(DOMAIN).1po; \
	  fi; \
	  if test -f $(srcdir)/$(DOMAIN).pot; then \
	    sed -f remove-potcdate.sed < $(srcdir)/$(DOMAIN).pot > $(DOMAIN).1po && \
	    sed -f remove-potcdate.sed < $(DOMAIN).po > $(DOMAIN).2po && \
	    if cmp $(DOMAIN).1po $(DOMAIN).2po >/dev/null 2>&1; then \
	      rm -f $(DOMAIN).1po $(DOMAIN).2po $(DOMAIN).po; \
	    else \
	      rm -f $(DOMAIN).1po $(DOMAIN).2po $(srcdir)/$(DOMAIN).pot && \
	      mv $(DOMAIN).po $(srcdir)/$(DOMAIN).pot; \
	    fi; \
	  else \
	    mv $(DOMAIN).po $(srcdir)/$(DOMAIN).pot; \
	  fi; \
	}

# This rule has no dependencies: we don't need to update $(DOMAIN).pot at
# every "make" invocation, only create it when it is missing.
# Only "make $(DOMAIN).pot-update" or "make dist" will force an update.
$(srcdir)/$(DOMAIN).pot:
	$(MAKE) $(DOMAIN).pot-update

# This target rebuilds a PO file if $(DOMAIN).pot has changed.
# Note that a PO file is not touched if it doesn't need to be changed.
$(POFILES): $(POFILESDEPS)
	@lang=`echo $@ | sed -e 's,.*/,,' -e 's/\.po$$//'`; \
	if test -f "$(srcdir)/$${lang}.po"; then \
	  test -f $(srcdir)/$(DOMAIN).pot || $(MAKE) $(srcdir)/$(DOMAIN).pot; \
	  test "$(srcdir)" = . && cdcmd="" || cdcmd="cd $(srcdir) && "; \
	  echo "$${cdcmd}$(MSGMERGE_UPDATE) $(MSGMERGE_OPTIONS) --lang=$${lang} $${lang}.po $(DOMAIN).pot"; \
	  cd $(srcdir) \
	    && { case `$(MSGMERGE) --version | sed 1q | sed -e 's,^[^0-9]*,,'` in \
	           '' | 0.[0-9] | 0.[0-9].* | 0.1[0-7] | 0.1[0-7].*) \
	             $(MSGMERGE_UPDATE) $(MSGMERGE_OPTIONS) $${lang}.po $(DOMAIN).pot;; \
	           *) \
	             $(MSGMERGE_UPDATE) $(MSGMERGE_OPTIONS) --lang=$${lang} $${lang}.po $(DOMAIN).pot;; \
	         esac; \
	       }; \
	else \
	  $(MAKE) $${lang}.po-create; \
	fi


install: install-exec install-data
install-exec:
install-data: install-data-yes
	if test "$(PACKAGE)" = "gettext-tools"; then \
	  $(mkdir_p) $(DESTDIR)$(gettextsrcdir); \
	  for file in $(DISTFILES.common) Makevars.template; do \
	    $(INSTALL_DATA) $(srcdir)/$$file \
			    $(DESTDIR)$(gettextsrcdir)/$$file; \
	  done; \
	  for file in Makevars; do \
	    rm -f $(DESTDIR)$(gettextsrcdir)/$$file; \
	  done; \
	else \
	  : ; \
	fi
install-data-no: all
install-data-yes: all
	@catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  lang=`echo $$cat | sed -e 's/\.gmo$$//'`; \
	  dir=$(localedir)/$$lang/LC_MESSAGES; \
	  $(mkdir_p) $(DESTDIR)$$dir; \
	  if test -r $$cat; then realcat=$$cat; else realcat=$(srcdir)/$$cat; fi; \
	  $(INSTALL_DATA) $$realcat $(DESTDIR)$$dir/$(DOMAIN).mo; \
	  echo "installing $$realcat as $(DESTDIR)$$dir/$(DOMAIN).mo"; \
	  for lc in '' $(EXTRA_LOCALE_CATEGORIES); do \
	    if test -n "$$lc"; then \
	      if (cd $(DESTDIR)$(localedir)/$$lang && LC_ALL=C ls -l -d $$lc 2>/dev/null) | grep ' -> ' >/dev/null; then \
	        link=`cd $(DESTDIR)$(localedir)/$$lang && LC_ALL=C ls -l -d $$lc | sed -e 's/^.* -> //'`; \
	        mv $(DESTDIR)$(localedir)/$$lang/$$lc $(DESTDIR)$(localedir)/$$lang/$$lc.old; \
	        mkdir $(DESTDIR)$(localedir)/$$lang/$$lc; \
	        (cd $(DESTDIR)$(localedir)/$$lang/$$lc.old && \
	         for file in *; do \
	           if test -f $$file; then \
	             ln -s ../$$link/$$file $(DESTDIR)$(localedir)/$$lang/$$lc/$$file; \
	           fi; \
	         done); \
	        rm -f $(DESTDIR)$(localedir)/$$lang/$$lc.old; \
	      else \
	        if test -d $(DESTDIR)$(localedir)/$$lang/$$lc; then \
	          :; \
	        else \
	          rm -f $(DESTDIR)$(localedir)/$$lang/$$lc; \
	          mkdir $(DESTDIR)$(localedir)/$$lang/$$lc; \
	        fi; \
	      fi; \
	      rm -f $(DESTDIR)$(localedir)/$$lang/$$lc/$(DOMAIN).mo; \
	      ln -s ../LC_MESSAGES/$(DOMAIN).mo $(DESTDIR)$(localedir)/$$lang/$$lc/$(DOMAIN).mo 2>/dev/null || \
	      ln $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/$(DOMAIN).mo $(DESTDIR)$(localedir)/$$lang/$$lc/$(DOMAIN).mo 2>/dev/null || \
	      cp -p $(DESTDIR)$(localedir)/$$lang/LC_MESSAGES/$(DOMAIN).mo $(DESTDIR)$(localedir)/$$lang/$$lc/$(DOMAIN).mo; \
	      echo "installing $$realcat link as $(DESTDIR)$(localedir)/$$lang/$$lc/$(DOMAIN).mo"; \
	    fi; \
	  done; \
	done

install-strip: install

installdirs: installdirs-exec installdirs-data
installdirs-exec:
installdirs-data: installdirs-data-yes
	if test "$(PACKAGE)" = "gettext-tools"; then \
	  $(mkdir_p) $(DESTDIR)$(gettextsrcdir); \
	else \
	  : ; \
	fi
installdirs-data-no:
installdirs-data-yes:
	@catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  lang=`echo $$cat | sed -e 's/\.gmo$$//'`; \
	  dir=$(localedir)/$$lang/LC_MESSAGES; \
	  $(mkdir_p) $(DESTDIR)$$dir; \
	  for lc in '' $(EXTRA_LOCALE_CATEGORIES); do \
	    if test -n "$$lc"; then \
	      if (cd $(DESTDIR)$(localedir)/$$lang && LC_ALL=C ls -l -d $$lc 2>/dev/null) | grep ' -> ' >/dev/null; then \
	        link=`cd $(DESTDIR)$(localedir)/$$lang && LC_ALL=C ls -l -d $$lc | sed -e 's/^.* -> //'`; \
	        mv $(DESTDIR)$(localedir)/$$lang/$$lc $(DESTDIR)$(localedir)/$$lang/$$lc.old; \
	        mkdir $(DESTDIR)$(localedir)/$$lang/$$lc; \
	        (cd $(DESTDIR)$(localedir)/$$lang/$$lc.old && \
	         for file in *; do \
	           if test -f $$file; then \
	             ln -s ../$$link/$$file $(DESTDIR)$(localedir)/$$lang/$$lc/$$file; \
	           fi; \
	         done); \
	        rm -f $(DESTDIR)$(localedir)/$$lang/$$lc.old; \
	      else \
	        if test -d $(DESTDIR)$(localedir)/$$lang/$$lc; then \
	          :; \
	        else \
	          rm -f $(DESTDIR)$(localedir)/$$lang/$$lc; \
	          mkdir $(DESTDIR)$(localedir)/$$lang/$$lc; \
	        fi; \
	      fi; \
	    fi; \
	  done; \
	done

# Define this as empty until I found a useful application.
installcheck:

uninstall: uninstall-exec uninstall-data
uninstall-exec:
uninstall-data: uninstall-data-yes
	if test "$(PACKAGE)" = "gettext-tools"; then \
	  for file in $(DISTFILES.common) Makevars.template; do \
	    rm -f $(DESTDIR)$(gettextsrcdir)/$$file; \
	  done; \
	else \
	  : ; \
	fi
uninstall-data-no:
uninstall-data-yes:
	catalogs='$(CATALOGS)'; \
	for cat in $$catalogs; do \
	  cat=`basename $$cat`; \
	  lang=`echo $$cat | sed -e 's/\.gmo$$//'`; \
	  for lc in LC_MESSAGES $(EXTRA_LOCALE_CATEGORIES); do \
	    rm -f $(DESTDIR)$(localedir)/$$lang/$$lc/$(DOMAIN).mo; \
	  done; \
	done

check: all

info dvi ps pdf html tags TAGS ctags CTAGS ID:

mostlyclean:
	rm -f remove-potcdate.sed
	rm -f stamp-poT
	rm -f core core.* $(DOMAIN).po $(DOMAIN).1po $(DOMAIN).2po *.new.po
	rm -fr *.o

clean: mostlyclean

distclean: clean
	rm -f Makefile Makefile.in POTFILES *.mo

maintainer-clean: distclean
	@echo "This command is intended for maintainers to use;"
	@echo "it deletes files that may require special tools to rebuild."
	rm -f stamp-po $(GMOFILES)

distdir = $(top_builddir)/$(PACKAGE)-$(VERSION)/$(subdir)
dist distdir:
	test -z "$(DISTFILESDEPS)" || $(MAKE) $(DISTFILESDEPS)
	@$(MAKE) dist2
# This is a separate target because 'update-po' must be executed before.
dist2: stamp-po $(DISTFILES)
	dists="$(DISTFILES)"; \
	if test "$(PACKAGE)" = "gettext-tools"; then \
	  dists="$$dists Makevars.template"; \
	fi; \
	if test -f $(srcdir)/$(DOMAIN).pot; then \
	  dists="$$dists $(DOMAIN).pot stamp-po"; \
	fi; \
	if test -f $(srcdir)/ChangeLog; then \
	  dists="$$dists ChangeLog"; \
	fi; \
	for i in 0 1 2 3 4 5 6 7 8 9; do \
	  if test -f $(srcdir)/ChangeLog.$$i; then \
	    dists="$$dists ChangeLog.$$i"; \
	  fi; \
	done; \
	if test -f $(srcdir)/LINGUAS; then dists="$$dists LINGUAS"; fi; \
	for file in $$dists; do \
	  if test -f $$file; then \
	    cp -p $$file $(distdir) || exit 1; \
	  else \
	    cp -p $(srcdir)/$$file $(distdir) || exit 1; \
	  fi; \
	done

update-po: Makefile
	$(MAKE) $(DOMAIN).pot-update
	test -z "$(UPDATEPOFILES)" || $(MAKE) $(UPDATEPOFILES)
	$(MAKE) update-gmo

# General rule for creating PO files.

.nop.po-create:
	@lang=`echo $@ | sed -e 's/\.po-create$$//'`; \
	echo "File $$lang.po does not exist. If you are a translator, you can create it through 'msginit'." 1>&2; \
	exit 1

# General rule for updating PO files.

.nop.po-update:
	@lang=`echo $@ | sed -e 's/\.po-update$$//'`; \
	if test "$(PACKAGE)" = "gettext-tools" && test "$(CROSS_COMPILING)" != "yes"; then PATH=`pwd`/../src:$$PATH; fi; \
	tmpdir=`pwd`; \
	echo "$$lang:"; \
	test "$(srcdir)" = . && cdcmd="" || cdcmd="cd $(srcdir) && "; \
	echo "$${cdcmd}$(MSGMERGE) $(MSGMERGE_OPTIONS) --lang=$$lang $$lang.po $(DOMAIN).pot -o $$lang.new.po"; \
	cd $(srcdir); \
	if { case `$(MSGMERGE) --version | sed 1q | sed -e 's,^[^0-9]*,,'` in \
	       '' | 0.[0-9] | 0.[0-9].* | 0.1[0-7] | 0.1[0-7].*) \
	         $(MSGMERGE) $(MSGMERGE_OPTIONS) -o $$tmpdir/$$lang.new.po $$lang.po $(DOMAIN).pot;; \
	       *) \
	         $(MSGMERGE) $(MSGMERGE_OPTIONS) --lang=$$lang -o $$tmpdir/$$lang.new.po $$lang.po $(DOMAIN).pot;; \
	     esac; \
	   }; then \
	  if cmp $$lang.po $$tmpdir/$$lang.new.po >/dev/null 2>&1; then \
	    rm -f $$tmpdir/$$lang.new.po; \
	  else \
	    if mv -f $$tmpdir/$$lang.new.po $$lang.po; then \
	      :; \
	    else \
	      echo "msgmerge for $$lang.po failed: cannot move $$tmpdir/$$lang.new.po to $$lang.po" 1>&2; \
	      exit 1; \
	    fi; \
	  fi; \
	else \
	  echo "msgmerge for $$lang.po failed!" 1>&2; \
	  rm -f $$tmpdir/$$lang.new.po; \
	fi

$(DUMMYPOFILES):

update-gmo: Makefile $(GMOFILES)
	@:

# Recreate Makefile by invoking config.status. Explicitly invoke the shell,
# because execution permission bits may not work on the current file system.
# Use /bin/bash, which is the shell determined by autoconf for the use by its
# scripts, not $(SHELL) which is hardwired to /bin/sh and may be deficient.
Makefile: Makefile.in.in Makevars $(top_builddir)/config.status POTFILES.in LINGUAS
	cd $(top_builddir) \
	  && /bin/bash ./config.status $(subdir)/$@.in po-directories

force:

# Tell versions [3.59,3.63) of GNU make not to export all variables.
# Otherwise a system limit (for SysV at least) may be exceeded.
.NOEXPORT:
# This file, Rules-quot, can be copied and used freely without restrictions.
# Special Makefile rules for English message catalogs with quotation marks.

DISTFILES.common.extra1 = quot.sed boldquot.sed en@quot.header en@boldquot.header insert-header.sin Rules-quot

.SUFFIXES: .insert-header .po-update-en

en@quot.po-create:
	$(MAKE) en@quot.po-update
en@boldquot.po-create:
	$(MAKE) en@boldquot.po-update

en@quot.po-update: en@quot.po-update-en
en@boldquot.po-update: en@boldquot.po-update-en

.insert-header.po-update-en:
	@lang=`echo $@ | sed -e 's/\.po-update-en$$//'`; \
	if test "$(PACKAGE)" = "gettext-tools" && test "$(CROSS_COMPILING)" != "yes"; then PATH=`pwd`/../src:$$PATH; GETTEXTLIBDIR=`cd $(top_srcdir)/src && pwd`; export GETTEXTLIBDIR; fi; \
	tmpdir=`pwd`; \
	echo "$$lang:"; \
	ll=`echo $$lang | sed -e 's/@.*//'`; \
	LC_ALL=C; export LC_ALL; \
	cd $(srcdir); \
	if $(MSGINIT) $(MSGINIT_OPTIONS) -i $(DOMAIN).pot --no-translator -l $$lang -o - 2>/dev/null \
	   | $(SED) -f $$tmpdir/$$lang.insert-header | $(MSGCONV) -t UTF-8 | \
	   { case `$(MSGFILTER) --version | sed 1q | sed -e 's,^[^0-9]*,,'` in \
	     '' | 0.[0-9] | 0.[0-9].* | 0.1[0-8] | 0.1[0-8].*) \
	       $(MSGFILTER) $(SED) -f `echo $$lang | sed -e 's/.*@//'`.sed \
	       ;; \
	     *) \
	       $(MSGFILTER) `echo $$lang | sed -e 's/.*@//'` \
	       ;; \
	     esac } 2>/dev/null > $$tmpdir/$$lang.new.po \
	     ; then \
	  if cmp $$lang.po $$tmpdir/$$lang.new.po >/dev/null 2>&1; then \
	    rm -f $$tmpdir/$$lang.new.po; \
	  else \
	    if mv -f $$tmpdir/$$lang.new.po $$lang.po; then \
	      :; \
	    else \
	      echo "creation of $$lang.po failed: cannot move $$tmpdir/$$lang.new.po to $$lang.po" 1>&2; \
	      exit 1; \
	    fi; \
	  fi; \
	else \
	  echo "creation of $$lang.po failed!" 1>&2; \
	  rm -f $$tmpdir/$$lang.new.po; \
	fi

en@quot.insert-header: insert-header.sin
	sed -e '/^#/d' -e 's/HEADER/en@quot.header/g' $(srcdir)/insert-header.sin > en@quot.insert-header

en@boldquot.insert-header: insert-header.sin
	sed -e '/^#/d' -e 's/HEADER/en@boldquot.header/g' $(srcdir)/insert-header.sin > en@boldquot.insert-header

mostlyclean: mostlyclean-quot
mostlyclean-quot:
	rm -f *.insert-header
