basesystem-beagleboard
======================

A ptxdist configuration for the Beagleboard-xM.

Prerequisites
-------------

To build the root file system you need ptxdist-2013.04.0 and a toolchain 
first. The former is available [here](http://www.ptxdist.org/software/ptxdist/download/ptxdist-2013.04.0.tar.bz2).
After downloading is must be installed with the usual 

	./configure
	make
	sudo makeinstall

sequence.

This project was tested using toolchain OSELAS.Toolchain-2012.12.0 available 
[here](http://www.ptxdist.org/oselas/toolchain/download/OSELAS.Toolchain-2012.12.0.tar.bz2).

Build instructions
------------------

To select the toolchain you want to use call:

	ptxdist-2013.04.0 toolchain /opt/OSELAS.Toolchain-2012.12.0/arm-cortexa8-linux-gnueabi/gcc-4.7.3-glibc-2.16.0-binutils-2.22-kernel-3.6-sanitized/bin

To start the build process call:

	ptxdist-2013.04.0 go

More information
----------------

More PTXdist related information can be found at http://www.pengutronix.de/software/ptxdist/index_en.html.
