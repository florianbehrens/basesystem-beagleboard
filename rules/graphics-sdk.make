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
PACKAGES-$(PTXCONF_GRAPHICS_SDK) += graphics-sdk

#
# Paths and names
#
GRAPHICS_SDK_VERSION	:= 4.08.00.01
GRAPHICS_SDK_MD5		:= dd0d994a48ecc4293f272a1fddddf159
GRAPHICS_SDK		    := Graphics_SDK_setuplinux_4_08_00_01
GRAPHICS_SDK_SUFFIX     := bin
GRAPHICS_SDK_URL		:= http://software-dl.ti.com/dsps/dsps_public_sw/sdo_sb/targetcontent/gfxsdk/latest/exports/$(GRAPHICS_SDK).$(GRAPHICS_SDK_SUFFIX)
GRAPHICS_SDK_SOURCE     := $(SRCDIR)/$(GRAPHICS_SDK).$(GRAPHICS_SDK_SUFFIX)
GRAPHICS_SDK_DIR		:= $(BUILDDIR)/$(GRAPHICS_SDK)
GRAPHICS_SDK_LICENSE	:= unknown

ifdef PTXCONF_GRAPHICS_SDK
$(STATEDIR)/kernel.targetinstall.post: $(STATEDIR)/graphics-sdk.targetinstall
endif

# make options
GRAPHICS_SDK_SDK_VER=3.x

# Put 'BUILD=debug' here for debug build
GRAPHICS_SDK_MAKE_BASE_OPT= \
    BUILD=release \
    OMAPES=$(GRAPHICS_SDK_SDK_VER) \
    FBDEV=yes \
    SUPPORT_XORG=0 \
    EGLIMAGE=0 \
    CSTOOL_PREFIX=$(PTXCONF_GNU_TARGET)- \
    KERNEL_INSTALL_DIR=$(KERNEL_DIR) \
    TARGETFS_INSTALL_DIR=$(SYSROOT) \
    GRAPHICS_INSTALL_DIR=$(GRAPHICS_SDK_DIR)
GRAPHICS_SDK_MAKE_OPT=$(GRAPHICS_SDK_MAKE_BASE_OPT) all
GRAPHICS_SDK_INSTALL_OPT=$(GRAPHICS_SDK_MAKE_BASE_OPT) install

# ----------------------------------------------------------------------------
# Extract
# ----------------------------------------------------------------------------

# Extract rule: We deal with a self-extracting archive
$(STATEDIR)/graphics-sdk.extract:
	@$(call targetinfo)
	@$(call clean, $(GRAPHICS_SDK_DIR))
	echo -e "Y\\nqy" | $(GRAPHICS_SDK_SOURCE) --mode console --es$(GRAPHICS_SDK_SDK_VER) --sdk --prefix $(GRAPHICS_SDK_DIR)
	@$(call patchin, GRAPHICS_SDK)
	@$(call touch)

# ----------------------------------------------------------------------------
# Prepare
# ----------------------------------------------------------------------------

# No autoconf -> prepare stage is omitted
GRAPHICS_SDK_CONF_TOOL	:= NO

# ----------------------------------------------------------------------------
# Compile
# ----------------------------------------------------------------------------

$(STATEDIR)/graphics-sdk.compile: $(STATEDIR)/kernel.prepare
	@$(call targetinfo)
	cd $(GRAPHICS_SDK_DIR) && \
		$(GRAPHICS_SDK_PATH) $(GRAPHICS_SDK_MAKE_ENV) \
		$(MAKE) $(GRAPHICS_SDK_MAKE_OPT) $(GRAPHICS_SDK_MAKE_PAR)
	@$(call touch)

# ----------------------------------------------------------------------------
# Install
# ----------------------------------------------------------------------------

# We need to create a /etc/init.d directory in the root filesystem, if not yet available.
# Otherwise the installation will fail.
# We also need to install header files in sysroot-target.
$(STATEDIR)/graphics-sdk.install:
	@$(call targetinfo)
	@mkdir -p $(SYSROOT)/etc/init.d

	# Call make install on TI Graphics SDK which results in installation under /opt
	@cd $(GRAPHICS_SDK_DIR) && \
		$(GRAPHICS_SDK_PATH) $(GRAPHICS_SDK_MAKE_ENV) \
		$(MAKE) $(GRAPHICS_SDK_INSTALL_OPT)

	# Copy headers in $(SYSROOT) for use by applications
	mkdir -p $(SYSROOT)/usr/include
	cp -r $(GRAPHICS_SDK_DIR)/include/OGLES2/* $(SYSROOT)/usr/include

	# Copy shared objects to $(SYSROOT)/usr/lib for use by applications
	mkdir -p $(SYSROOT)/usr/lib
	cp $(SYSROOT)/opt/gfxlibraries/gfx_rel_es$(GRAPHICS_SDK_SDK_VER)/*.so $(SYSROOT)/usr/lib/

	@$(call touch)

# ----------------------------------------------------------------------------
# Target-Install
# ----------------------------------------------------------------------------

$(STATEDIR)/graphics-sdk.targetinstall:
	@$(call targetinfo)

	# Install kernel modules
	cd $(GRAPHICS_SDK_DIR)/GFX_Linux_KM && \
		$(MAKE) $(KERNEL_MAKEVARS) -C $(KERNEL_DIR) M=`pwd` modules_install

	# Install libraries stuff
	@$(call install_init, graphics-sdk)
	@$(call install_fixup, graphics-sdk,PRIORITY,optional)
	@$(call install_fixup, graphics-sdk,SECTION,base)
	@$(call install_fixup, graphics-sdk,AUTHOR,"Florian Behrens <flb@zuehlke.com>")
	@$(call install_fixup, graphics-sdk,DESCRIPTION,missing)

	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/etc/powervr.ini, /etc/powervr.ini)

	@$(call install_copy, graphics-sdk, 0, 0, 0755, /etc/init.d)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/etc/init.d/omap-demo, /etc/init.d/omap-demo)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/etc/init.d/devmem2, /etc/init.d/devmem2)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/etc/init.d/rc.pvr, /etc/init.d/rc.pvr)
	@$(call install_link, graphics-sdk, ../init.d/rc.pvr, /etc/rc.d/S30pvr)

	@$(call install_copy, graphics-sdk, 0, 0, 0755, /usr/local/bin)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/pvrsrvctl, /usr/local/bin/pvrsrvctl)

	@$(call install_copy, graphics-sdk, 0, 0, 0755, /usr/lib)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libGLES_CM.so, /usr/lib/libGLES_CM.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libusc.so, /usr/lib/libusc.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libGLESv2.so, /usr/lib/libGLESv2.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libglslcompiler.so, /usr/lib/libglslcompiler.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libIMGegl.so, /usr/lib/libIMGegl.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libEGL.so, /usr/lib/libEGL.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libpvr2d.so, /usr/lib/libpvr2d.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libpvrPVR2D_BLITWSEGL.so, /usr/lib/libpvrPVR2D_BLITWSEGL.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libpvrPVR2D_FLIPWSEGL.so, /usr/lib/libpvrPVR2D_FLIPWSEGL.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libpvrPVR2D_FRONTWSEGL.so, /usr/lib/libpvrPVR2D_FRONTWSEGL.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libpvrPVR2D_LINUXFBWSEGL.so, /usr/lib/libpvrPVR2D_LINUXFBWSEGL.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libpvrEWS_WSEGL.so, /usr/lib/libpvrEWS_WSEGL.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libsrv_um.so, /usr/lib/libsrv_um.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libsrv_init.so, /usr/lib/libsrv_init.so)
	@$(call install_copy, graphics-sdk, 0, 0, 0755, $(SYSROOT)/opt/gfxlibraries/gfx_rel_es3.x/libPVRScopeServices.so, /usr/lib/libPVRScopeServices.so)

	@$(call install_finish, graphics-sdk)
	@$(call touch)
