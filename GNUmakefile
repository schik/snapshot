
# Install into the system root by default
GNUSTEP_INSTALLATION_DOMAIN=LOCAL

include $(GNUSTEP_MAKEFILES)/common.make

#
# Subprojects
#
SUBPROJECTS = CameraKit

#
# Main application
#

PACKAGE_NAME=Snapshot
APP_NAME=Snapshot
Snapshot_APPLICATION_ICON=Snapshot.tiff

ifeq ($(freedesktop), no)
  Snapshot_OBJCFLAGS += -DNOFREEDESKTOP
endif

#
# Resource files
#

Snapshot_RESOURCE_FILES= \
	Images/Snapshot.tiff \
	Images/iconDelete.tiff \
	Images/iconMultiSelection.tiff

#
# Header files
#

Snapshot_HEADERS= \
	Snapshot.h \
	SnapshotController.h \
	SnapshotIcon.h \
	SnapshotIconView.h \
	Inspector.h \
	Attributes.h \
	Preferences.h \
	NSImage+Transform.h \
	Constants.h

#
# Class files
#

Snapshot_OBJC_FILES= \
	main.m \
	Snapshot.m \
	SnapshotController.m \
	SnapshotIcon.m \
	SnapshotIconView.m \
	Inspector.m \
	Attributes.m \
	Preferences.m \
	NSImage+Transform.m \
	Constants.m

#
# C files
#

Snapshot_C_FILES= 

Snapshot_PRINCIPAL_CLASS = Snapshot

Snapshot_LANGUAGES=English German
Snapshot_LOCALIZED_RESOURCE_FILES = \
	Snapshot.gorm \
	InspectorWin.gorm \
	Attributes.gorm \
	Preferences.gorm \
	Localizable.strings

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
