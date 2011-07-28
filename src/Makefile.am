## Process this file with automake to produce Makefile.in

## Created by Anjuta


uidir = $(datadir)/toodledo/ui
ui_DATA = toodledo.ui


AM_CPPFLAGS = \
	-DPACKAGE_LOCALE_DIR=\""$(prefix)/$(DATADIRNAME)/locale"\" \
	-DPACKAGE_SRC_DIR=\""$(srcdir)"\" \
	-DPACKAGE_DATA_DIR=\""$(datadir)"\" \
	$(TOODLEDO_CFLAGS) \
	$(LIBSOUP_CFLAGS) \
	$(JSON_GLIB_CFLAGS) \
	$(SQLITE3_CFLAGS) \
	$(GEE_CFLAGS) \
	$(APPINDICATOR3_CFLAGS)

AM_CFLAGS =\
	 -Wall\
	 -g

VALAFLAGS =  \
	--pkg gee-1.0 --pkg sqlite3 --pkg json-glib-1.0 --pkg appindicator3-0.1 --pkg libsoup-2.4 --thread --pkg gtk+-3.0 --vapidir . --pkg config

bin_PROGRAMS = toodledo

toodledo_SOURCES = \
	toodledo.vala \
	folder.vala

toodledo_LDFLAGS = \
	-Wl,--export-dynamic

toodledo_LDADD = $(TOODLEDO_LIBS) \
		$(LIBSOUP_LIBS) \
		$(JSON_GLIB_LIBS) \
		$(SQLITE3_LIBS) \
		$(GEE_LIBS) \
		$(APPINDICATOR3_LIBS)


EXTRA_DIST = $(ui_DATA)

# Remove ui directory on uninstall
uninstall-local:
	-rm -r $(uidir)
	-rm -r $(datadir)/toodledo
