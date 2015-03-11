
# Install into the system root by default
GNUSTEP_INSTALLATION_DOMAIN=LOCAL

include $(GNUSTEP_MAKEFILES)/common.make

#
# Subprojects
#
SUBPROJECTS = 

#
# Main application
#

PACKAGE_NAME=Snapshot
APP_NAME=Snapshot
Snapshot_APPLICATION_ICON=Snapshot.tiff

#
# Resource files
#

Snapshot_RESOURCE_FILES= \
	Images/Snapshot.tiff

#
# Header files
#

Snapshot_HEADERS= \
	Snapshot.h \
	SnapshotController.h \
	ThumbnailCell.h \
	Constants.h

#
# Class files
#

Snapshot_OBJC_FILES= \
	main.m \
	Snapshot.m \
	SnapshotController.m \
	ThumbnailCell.m \
	Constants.m

#
# C files
#

Snapshot_C_FILES= 

Snapshot_PRINCIPAL_CLASS = Snapshot

Snapshot_LANGUAGES=English German
Snapshot_LOCALIZED_RESOURCE_FILES = \
	Snapshot.gorm \
	Localizable.strings

-include GNUmakefile.preamble
-include GNUmakefile.local
include $(GNUSTEP_MAKEFILES)/aggregate.make
include $(GNUSTEP_MAKEFILES)/application.make

-include GNUmakefile.postamble
