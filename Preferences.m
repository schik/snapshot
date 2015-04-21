/* vim: set ft=objc ts=4 nowrap: */
/*
 *    Preferences.m
 *
 *    Copyright (c) 2015
 *
 *    Author: Andreas Schik <andreas@schik.de>
 *
 *    This program is free software; you can redistribute it and/or modify
 *    it under the terms of the GNU General Public License as published by
 *    the Free Software Foundation; either version 2 of the License, or
 *    (at your option) any later version.
 *
 *    This program is distributed in the hope that it will be useful,
 *    but WITHOUT ANY WARRANTY; without even the implied warranty of
 *    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.    See the
 *    GNU General Public License for more details.
 *
 *    You should have received a copy of the GNU General Public License
 *    along with this program; if not, write to the Free Software
 *    Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 */

#include <AppKit/AppKit.h>

#ifndef NOFREEDESKTOP
#include <FreeDesktopKit/FDUserdirsFile.h>
#endif

#include "Constants.h"
#include "Preferences.h"

static NSString *nibName = @"Preferences";
static Preferences *singleInstance = nil;


@interface Preferences (Private)

- (void) initializeFromDefaults;

@end


@implementation Preferences(Private)

- (void) initializeFromDefaults
{
	static BOOL initialized = NO;
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *value;
	int useTsDir;

	if (!initialized) {
		value = [defaults stringForKey: @"ImportDirectory"];
		if ((nil == value) || ([value length] == 0)) {
#ifndef NOFREEDESKTOP
			FDUserdirsFile * udf = [FDUserdirsFile defaultUserdirsFile];
			value = [udf getUserdir: @"PICTURES"];
#else
			value = NSHomeDirectory();
#endif
		}
		[importFolderText setStringValue: value];

		useTsDir = [defaults integerForKey: @"UseTimestampDirectory"];
		[timestampSubfolderCheckBox setState: useTsDir];

		value = [defaults stringForKey: TIMESTAMP_PATH_FORMAT];
		[timestampFormatText setStringValue: value];

		if (!useTsDir) {
			[timestampFormatText setEnabled: NO];
		}
		initialized = YES;
	}
}

@end

@implementation Preferences

+ (id) singleInstance
{
    if (singleInstance == nil) {
        singleInstance = [[Preferences alloc] init];
    }
  
    return singleInstance;
}


- (id) init
{
    self = [super init];
  
    if (self) {
        if ([NSBundle loadNibNamed: nibName owner: self] == NO) {
            NSLog(@"failed to load %@!", nibName);
            DESTROY (self);
            return self;
        } 
    
        [window setFrameUsingName: @"preferences"];
        [window setDelegate: self];
    }
  
    return self;
}

- (void) awakeFromNib
{
    [window setFrameAutosaveName: @"PreferencesWindow"];
    [window setFrameUsingName: @"PreferencesWindow"];

    [self initializeFromDefaults];
}

- (void) showPanel: (id) sender
{
    [NSApp runModalForWindow: window];
}


- (void) browseAction: (id)sender
{
    id panel;
    int answer;

    panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories: YES];
    [panel setCanChooseFiles: NO];
    [panel setAllowsMultipleSelection: NO];
    [panel setTitle: _(@"Set download destination")];

	NSString *dest = [importFolderText stringValue];

    answer = [panel runModalForDirectory: dest 
                                    file: nil
                                   types: nil];

    if (answer == NSOKButton) {
        dest = [[panel filenames] objectAtIndex: 0];
    	[importFolderText setStringValue: dest];
    }
}


- (void) toggleTimestampAction: (id)sender
{
	int useTsDir = [timestampSubfolderCheckBox state];

	[timestampFormatText setEnabled: useTsDir];
}


- (void) saveAction: (id)sender
{
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSString *value = [importFolderText stringValue];
	[defaults setObject: value forKey: @"ImportDirectory"];

	int useTsDir = [timestampSubfolderCheckBox state];
	[defaults setInteger: useTsDir forKey: @"UseTimestampDirectory"];

	if (useTsDir) {
		value = [timestampFormatText stringValue];
		[defaults setObject: value forKey: TIMESTAMP_PATH_FORMAT];
	}
	[defaults synchronize];
}

@end
