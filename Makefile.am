## Process this file with automake to produce Makefile.in
## Created by Anjuta

SUBDIRS = src 

toodledodocdir = ${prefix}/doc/toodledo
toodledodoc_DATA = \
	README\
	COPYING\
	AUTHORS\
	ChangeLog\
	INSTALL\
	NEWS


EXTRA_DIST = $(toodledodoc_DATA)


# Remove doc directory on uninstall
uninstall-local:
	-rm -r $(toodledodocdir)
