/* Inspector.m
 *  
 * Copyright (C) 2015
 *
 * Author: Andreas Schik <andreas@schik.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 * 
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 * 
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA 02111 USA.
 */

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>

#import "Inspector.h"
#import "Attributes.h"
#import "SnapshotIcon.h"

#define ATTRIBUTES   0

static NSString *nibName = @"InspectorWin";

@implementation Inspector

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                           name: @"ImageSelectionChanged"
                         object: nil];
    RELEASE (inspectors);
    RELEASE (window);
   
    [super dealloc];
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
    
      [window setFrameUsingName: @"inspector"];
      [window setDelegate: self];
  
      inspectors = [NSMutableArray new];

      while ([[popUp itemArray] count] > 0) {
          [popUp removeItemAtIndex: 0];
      }

      [[NSNotificationCenter defaultCenter] addObserver: self
                              selector: @selector(imageChanged:)
                                  name: @"ImageSelectionChanged"
                                object: nil];

      currentInspector = [[Attributes alloc] initForInspector: self];
      [inspectors insertObject: currentInspector atIndex: ATTRIBUTES]; 
      [popUp insertItemWithTitle: NSLocalizedString(@"Attributes", @"") 
                         atIndex: ATTRIBUTES];
      [[popUp itemAtIndex: ATTRIBUTES] setKeyEquivalent: @"1"];
      DESTROY (currentInspector);
    }
  
    return self;
}

- (void) awakeFromNib
{
    [window setFrameAutosaveName: @"InspectorsWindow"];
    [window setFrameUsingName: @"InspectorsWindow"];
}

- (void)activate
{
    [window makeKeyAndOrderFront: nil];

    if (currentInspector == nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        id entry = [defaults objectForKey: @"last_active_inspector"];
        int index = 0;
    
        if (entry) {
            index = [entry intValue];
            index = ((index < 0) ? 0 : index);
        }
    
        [popUp selectItemAtIndex: index];
        [self activateInspector: popUp];
    }
}

- (IBAction) activateInspector: (id)sender
{
    id insp = [inspectors objectAtIndex: [sender indexOfSelectedItem]];
  
    if (currentInspector != insp) {
        currentInspector = insp;
        [window setTitle: [insp winname]];
        [inspBox setContentView: [insp inspView]];	 
    }
}

- (void) imageChanged: (id)notification
{
    NSArray *images = [[notification userInfo] objectForKey: @"Images"];

    if (!images || [images count] == 0) {
        NSImage *fileIcon = [NSImage imageNamed: @"iconDelete.tiff"];
        [iconView setImage: fileIcon];
        [titleField setStringValue: _(@"No image selected")];
        return;
    }

    if ([images count] > 1) {
        NSImage *fileIcon = [NSImage imageNamed: @"iconMultiSelection.tiff"];
        [iconView setImage: fileIcon];
        [titleField setStringValue:
	    [NSString stringWithFormat: _(@"%d Images selected"), [images count]]];
	return;
    }

    SnapshotIcon *snIcon = [images objectAtIndex: 0];
    [iconView setImage: [snIcon icon]];
    [titleField setStringValue: [snIcon fileName]];
}

- (void) showAttributes
{
    if ([window isVisible] == NO) {
        [self activate];
    }
    [popUp selectItemAtIndex: ATTRIBUTES];
    [self activateInspector: popUp];
}

- (id) attributes
{
    return [inspectors objectAtIndex: ATTRIBUTES];
}

- (NSWindow *)window
{
    return window;
}

- (void)updateDefaults
{
    NSNumber *index = [NSNumber numberWithInt: [popUp indexOfSelectedItem]];

    [[NSUserDefaults standardUserDefaults] setObject: index 
                                              forKey: @"last_active_inspector"];
    [[self attributes] updateDefaults];
}

- (BOOL)windowShouldClose:(id)sender
{
    return YES;
}

@end


