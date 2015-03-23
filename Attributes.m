/* Attributes.m
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

#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Attributes.h"
#import "Inspector.h"
#import "SnapshotIcon.h"

#define SINGLE 0
#define MULTIPLE 1

static NSString *nibName = @"Attributes";
static NSDateFormatter* dateFormatter = nil;
static NSDateFormatter* timeFormatter = nil;

@implementation Attributes

+ (void)initialize
{
    static BOOL initialized = NO;

    if (initialized == NO) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle: NSDateFormatterLongStyle];
        timeFormatter = [[NSDateFormatter alloc] init];
        [timeFormatter setTimeStyle: NSDateFormatterMediumStyle];
        initialized = YES;
    }
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver: self
                            name: @"ImageSelectionChanged"
                          object: nil];

    RELEASE (mainBox);

    [super dealloc];
}

- (id) initForInspector: (id)insp
{
    self = [super init];
  
    if (self) {
        if ([NSBundle loadNibNamed: nibName owner: self] == NO) {
            NSLog(@"failed to load %@!", nibName);
            DESTROY (self);
            return self;
        } 

        RETAIN(mainBox);

        inspector = insp;

        [[NSNotificationCenter defaultCenter] addObserver: self
                                selector: @selector(imageChanged:)
                                    name: @"ImageSelectionChanged"
                                  object: nil];
    } 
		
    return self;
}

- (NSView *) inspView
{
    return mainBox;
}

- (NSString *) winname
{
    return _(@"Properties Inspector");
}

- (void) imageChanged: (id)notification
{
    [self setImages: [[notification userInfo] objectForKey: @"Images"]];
}

- (void) removeImages
{
    NSImage *fileIcon = [NSImage imageNamed: @"iconDelete.tiff"];
    [iconView setImage: fileIcon];

    [titleField setStringValue: _(@"No image selected")];
    [exposureField setStringValue: @""];
    [imageSizeField setStringValue: @""];
    [sizeField setStringValue: @""];
    [dateField setStringValue: @""];
}

- (void) setImages: (NSArray *)images
{
//    iconInfo = nil;

    if (!images || [images count] == 0) {
        [self removeImages];
        return;
    }
    if ([images count] > 1) {
        NSImage *fileIcon = [NSImage imageNamed: @"iconMultiSelection.tiff"];
        [iconView setImage: fileIcon];

        [titleField setStringValue:
	    [NSString stringWithFormat: _(@"%d Images selected"), [images count]]];
        [exposureField setStringValue: @""];
        [imageSizeField setStringValue: @""];
        [sizeField setStringValue: @""];
        [dateField setStringValue: @""];
	return;
    }

    SnapshotIcon *snIcon = [images objectAtIndex: 0];

//    NSDictionary *iconInfo = [snIcon iconInfo];

    [iconView setImage: [snIcon icon]];

    [titleField setStringValue: [snIcon fileName]];
    
    [exposureField setStringValue: [NSString stringWithFormat: @"%@, %@",
	[snIcon fNumber], [snIcon exposureTime]]];
    [imageSizeField setStringValue: [NSString stringWithFormat: @"%dx%d",
	[snIcon width], [snIcon height]]];
    [sizeField setStringValue: [NSString stringWithFormat: @"%d kB", [snIcon fileSize]]];
    [dateField setStringValue: [dateFormatter stringFromDate: [snIcon date]]];
    [timeField setStringValue: [timeFormatter stringFromDate: [snIcon date]]];

#if 0
    [exifInfoTable reloadData];
#endif
}


- (void)updateDefaults
{
}

#if 0
- (NSInteger) numberOfRowsInTableView: (NSTableView *)aTableView
{
    if (nil == iconInfo) {
	return 0;
    }
    return [[iconInfo allKeys] count];
}

- (id) tableView: (NSTableView *)aTableView
    objectValueForTableColumn: (NSTableColumn *)aTableColumn
                          row: (NSInteger)rowIndex
{
    NSString *identifier = [aTableColumn identifier];
    if ([identifier isEqual: @"tag"]) {
	return [[iconInfo allKeys] objectAtIndex: rowIndex];
    }
    if ([identifier isEqual: @"value"]) {
	NSObject *key = [[iconInfo allKeys] objectAtIndex: rowIndex];
	return [iconInfo objectForKey: key];
    }
    return nil;
}
#endif

@end
