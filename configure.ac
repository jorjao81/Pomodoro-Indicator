dnl Process this file with autoconf to produce a configure script.
dnl Created by Anjuta application wizard.

AC_INIT(toodledo, 0.1)
m4_ifdef([AM_SILENT_RULES],[AM_SILENT_RULES([yes])])

AM_INIT_AUTOMAKE(AC_PACKAGE_NAME, AC_PACKAGE_VERSION)
AC_CONFIG_HEADERS([config.h])
AM_MAINTAINER_MODE

AC_PROG_CC


AM_PROG_LIBTOOL


dnl Check for vala
AM_PROG_VALAC([0.10.0])


PKG_CHECK_MODULES(APPINDICATOR3,appindicator3-0.1)

PKG_CHECK_MODULES(GEE,gee-1.0)

PKG_CHECK_MODULES(SQLITE3,sqlite3)

PKG_CHECK_MODULES(JSON_GLIB,json-glib-1.0)

PKG_CHECK_MODULES(LIBSOUP,libsoup-2.4)

PKG_CHECK_MODULES(TOODLEDO, gtk+-3.0)


AC_OUTPUT([
Makefile
src/Makefile

])
