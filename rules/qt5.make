# -*-makefile-*-
#
# Copyright (C) 2013 by Florian Behrens <flb@zuehlke.com>
#
# See CREDITS for details about who has contributed to this project.
#
# For further information about the PTXdist project and license conditions
# see the README file.
#

#
# We provide this package
#
PACKAGES-$(PTXCONF_QT5) += qt5

#
# Paths and names
#
QT5_VERSION	:= 5.0.2
QT5_MD5	    := 87cae8ae2f82f41ba027c2db0ab639b7
QT5	        := qt-everywhere-opensource-src-$(QT5_VERSION)
QT5_SUFFIX  := tar.gz
QT5_URL	    := http://origin.releases.qt-project.org/qt5/$(QT5_VERSION)/single/$(QT5).$(QT5_SUFFIX)
QT5_SOURCE  := $(SRCDIR)/$(QT5).$(QT5_SUFFIX)
QT5_DIR	    := $(BUILDDIR)/$(QT5)
QT5_LICENSE	:= LGPL

# ----------------------------------------------------------------------------
# Extract
# ----------------------------------------------------------------------------

# We need a custom extract rule because we substitute some keywords (@...@) 
# after the patch step.
$(STATEDIR)/qt5.extract:
	@$(call targetinfo)
	@$(call clean, $(QT5_DIR))
	@$(call extract, QT5)
	@$(call patchin, QT5)
	for file in $(QT5_DIR)/qtbase/mkspecs/devices/linux-ptxdist-g++/*.in; do \
		sed -e "s,@SYSROOT@,$(SYSROOT),g" \
		    $$file > $${file%%.in}; \
	done
	@$(call touch)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

#
# autoconf
#
QT5_CONF_TOOL	:= autoconf
QT5_CONF_ENV    := # $(CROSS_ENV)

# Note that the host tools (e.g., moc etc) are also installed in 
# $(PTXDIST_SYSROOT_TARGET) since the CMake files provided by Qt seem not to be 
# cross-build aware.
QT5_CONF_OPT	:= \
    -confirm-license \
    -opensource \
    -device linux-ptxdist-g++ \
    -device-option CROSS_COMPILE=arm-cortexa8-linux-gnueabi- \
    -sysroot $(PTXDIST_SYSROOT_TARGET) -no-gcc-sysroot \
    -hostprefix $(PTXDIST_SYSROOT_TARGET)/usr/local/Qt-$(QT5_VERSION) \
    -nomake examples \
    -opengl es2 \
    -no-openssl \
    -no-iconv \
    -no-pkg-config \
    -no-pch \
    -no-nis \
    -no-cups \
    -no-icu \
    -no-dbus \
    -no-xcb \
    -no-directfb \
    -no-kms \
    -v

ifndef PTXCONF_QT5_WIDGETS
QT5_CONF_OPT += -no-widgets
endif

ifndef PTXCONF_QT5_QUICK1
QT5_CONF_OPT += -skip quick1
endif

ifndef PTXCONF_QT5_MULTIMEDIA
QT5_CONF_OPT += -skip multimedia
endif

ifndef PTXCONF_QT5_SVG
QT5_CONF_OPT += -skip svg
endif

ifndef PTXCONF_QT5_WEBKIT
QT5_CONF_OPT += -skip webkit -skip webkit-examples-and-demos
endif

$(STATEDIR)/qt5.prepare:
	@$(call targetinfo)
	@$(call clean, $(QT5_DIR)/config.cache)
	cd $(QT5_DIR)/$(QT5_SUBDIR) && \
		$(QT5_PATH) $(QT5_CONF_ENV) \
		./configure $(QT5_CONF_OPT)
	@$(call touch)

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

# Qt takes care for cross-compilation
QT5_MAKE_ENV :=

$(STATEDIR)/qt5.compile: $(STATEDIR)/graphics_sdk.targetinstall
	@$(call targetinfo)
	echo $(MAKESPEC)
	cd $(QT5_DIR) && \
		$(QT5_PATH) $(QT5_MAKE_ENV) \
		$(MAKE) $(MFLAGS) $(QT5_MAKE_OPT) $(QT5_MAKE_PAR)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

QT5_INSTALL_OPT := install

$(STATEDIR)/qt5.install:
	@$(call targetinfo)
	@cd $(QT5_DIR) && \
		$(QT5_PATH) $(QT5_MAKE_ENV) \
		$(MAKE) $(MFLAGS) $(QT5_INSTALL_OPT)
	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

QT5_MAJOR_VERSION=$(firstword $(subst ., ,$(QT5_VERSION)))

$(STATEDIR)/qt5.targetinstall:
	@$(call targetinfo)

	@$(call install_init, qt5)
	@$(call install_fixup, qt5,PRIORITY,optional)
	@$(call install_fixup, qt5,SECTION,base)
	@$(call install_fixup, qt5,AUTHOR,"Florian Behrens <flb@zuehlke.com>")
	@$(call install_fixup, qt5,DESCRIPTION,missing)

	# Install library files to /usr/lib
	@for f in $(SYSROOT)/usr/local/Qt-$(QT5_VERSION)/lib/libQt5*.so.$(QT5_VERSION); do \
		$(call install_copy, qt5, 0, 0, 0755, $$f, /usr/lib/`basename $$f`); \
		$(call install_link, qt5, `basename $$f`, /usr/lib/`basename $$f .$(QT5_VERSION)`); \
		$(call install_link, qt5, `basename $$f`, /usr/lib/`basename $$f .$(QT5_VERSION)`.$(QT5_MAJOR_VERSION)); \
	done

	# Install font files to /usr/local/Qt-5.0.1/lib/fonts
	$(call install_tree, qt5, 0, 0, $(SYSROOT)/usr/local/Qt-$(QT5_VERSION)/lib/fonts, /usr/local/Qt-$(QT5_VERSION)/lib/fonts)

	# Install qml modules to /usr/local/Qt-5.0.1/qml
	$(call install_tree, qt5, 0, 0, $(SYSROOT)/usr/local/Qt-$(QT5_VERSION)/qml, /usr/local/Qt-$(QT5_VERSION)/qml)

	# Install plugins to /usr/local/Qt-5.0.1/plugins
	$(call install_tree, qt5, 0, 0, $(SYSROOT)/usr/local/Qt-$(QT5_VERSION)/plugins, /usr/local/Qt-$(QT5_VERSION)/plugins)

	@$(call install_finish, qt5)
	@$(call touch)
