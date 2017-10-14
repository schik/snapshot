#
# GNUmakefile
#
# Compile the CameraKit Framework (part of ImageKits).
#
# Copyright (C) 2003 Nicolas SANCHEZ (nicolas.sanchez@evhr.net)
#
# This Makefile is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
# See the GNU General Public License for more details.
#

include $(GNUSTEP_MAKEFILES)/common.make

FRAMEWORK_NAME=CameraKit

CameraKit_HEADER_FILES = \
	GSGPhoto2.h \
	GSCamera.h

CameraKit_OBJC_FILES = \
	GSGPhoto2.m \
	GSCamera.m

CameraKit_RESOURCE_FILES =

ADDITIONAL_INCLUDE_DIRS = `pkg-config --cflags libgphoto2`
ADDITIONAL_OBJCFLAGS = -Wall
ADDITIONAL_LDFLAGS = `pkg-config --libs libgphoto2`

## chainjazz ##
ADDITIONAL_INCLUDE_DIRS += `-I/usr/local/include/libexif
## chainjazz ##

-include GNUmakefile.preamble

include $(GNUSTEP_MAKEFILES)/framework.make
include $(GNUSTEP_MAKEFILES)/aggregate.make

-include GNUmakefile.postamble
