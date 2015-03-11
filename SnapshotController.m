/*
 *    SnapshotController.m
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

#include <CameraKit/GSCamera.h>

#include "SnapshotController.h"
#include "ThumbnailCell.h"
#include "Constants.h"


static BOOL refreshRunning = NO;
static BOOL downloadRunning = NO;
static BOOL abortDownload = NO;
static NSString *deleteAction = @"Delete";
static NSString *saveAction = @"Save";

/**
 * This class represents the items stored in the OutlineView
 */
@interface OutlineItem: NSObject
{
@public
    GSCamera *camera;
    NSString *path;
    NSArray *subFolders;
}
@end

@implementation OutlineItem

- (void) dealloc
{
    // We expect that the values for ivars are retained
    // for us by our creator. 
    if (nil != subFolders) {
        [subFolders release];
    }
    if (nil != path) {
        [path release];
    }
    [super dealloc];
}

@end


/**
 * This class represents the items stored in the TableView
 */
@interface TableItem: NSObject
{
@public
    NSString *file;
    NSImage *image;
}
@end

@implementation TableItem

- (void) dealloc
{
    // We expect that the values for ivars are retained
    // for us by our creator. 
    if (nil != image) {
        [image release];
    }
    if (nil != file) {
        [file release];
    }
    [super dealloc];
}

@end

@interface SnapshotController (Private)

- (void) processSelectedImages: (NSString *) action;
- (NSString *) getDestination;
- (void) startProgressAnimationWithStatus: (NSString *) statusMsg;
- (void) stopProgressAnimation;

@end

@implementation SnapshotController (Private)

/**
 * Process the selected images.
 * This method only collects the data and then starts a thread
 * to do the actual job.
 */
- (void) processSelectedImages: (NSString *) action
{
    NSString *dest = nil;

    if ([action isEqualToString: deleteAction]) {
        if (NSRunAlertPanel(_(@"Delete images"),
                _(@"Please confirm that you wich to delete the sected images."),
                _(@"Do not delete"), _(@"Delete"), nil) == NSAlertDefaultReturn) {
            return;
        }
    } else {
        dest = [self getDestination];
    }

    NSMutableDictionary *threadParams = [NSMutableDictionary new];
    NSMutableArray * images = [NSMutableArray new];
    int idx = [cameraTree selectedRow];
    OutlineItem * camera = [cameraTree itemAtRow: idx];
    NSEnumerator *e = [fileList selectedRowEnumerator];
    NSNumber *n;

    while ((n = [e nextObject]) != nil) {
        TableItem *image = [files objectAtIndex: [n intValue]];
        [images addObject: image];
    }

    if ([action isEqualToString: saveAction]) {
        [threadParams setObject: dest forKey: DOWNLOAD_PATH];
    }
    [threadParams setObject: camera forKey: CAMERA];
    [threadParams setObject: images forKey: IMAGES];
    [threadParams setObject: action forKey: ACTION];

    // Set up the progress indicator to display the deletion
    // progress
    [progress setIndeterminate: NO];
    [progress setMaxValue: [images count]];
    [progress setDoubleValue: 0.];
    [progress setHidden: NO];
    [progress display];
    [abort setHidden: NO];
    [abort display];

    downloadRunning = YES;
    abortDownload = NO;

    // Start the worker
    [NSThread detachNewThreadSelector: @selector(processImages:)
                             toTarget: self
                           withObject: threadParams];

    [images release];
    [threadParams release];
}

/**
 * Opens the OpenPanel to ask for the destination directory.
 * Return the name of the selected directory or nil.
 */
- (NSString *) getDestination
{
    NSUserDefaults*  defs = [NSUserDefaults standardUserDefaults];
    NSString *dest = [defs stringForKey: LAST_SAVE_DIR];
    id panel;
    int answer;

    panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories: YES];
    [panel setCanChooseFiles: NO];
    [panel setAllowsMultipleSelection: NO];
    [panel setTitle: _(@"Set download destination")];

    answer = [panel runModalForDirectory: dest 
                                    file: nil
                                   types: nil];

    if (answer == NSOKButton) {
        dest = [[panel filenames] objectAtIndex: 0];
    	[defs setObject: dest forKey: LAST_SAVE_DIR];
        return dest;
    }
    return nil;
}

- (void) startProgressAnimationWithStatus: (NSString *) statusMsg
{
    [statusText setStringValue: statusMsg];
    [progress setIndeterminate: YES];
    [progress setMaxValue: 100.];
    [progress setDoubleValue: 0.];
    [progress setHidden: NO];
    [progress display];
    [progress startAnimation: self];
}

- (void) stopProgressAnimation
{
    [statusText setStringValue: @""];
    [progress stopAnimation: self];
    [progress setHidden: YES];
    [progress setDoubleValue: 0.];
}

@end


@implementation SnapshotController

//
// Initialization/Uninitialization
//

- (id) init
{
    self = [super init];
    if (self != nil) {
        photo2 = nil;
        files = nil;
    }
    return self;
}

- (void) dealloc
{
    if (nil != photo2) {
        [photo2 release];
    }
    if (nil != files) {
        [files release];
    }
    [super dealloc];
}

- (void) awakeFromNib
{
    // We do not need the Abort button all the time
    [abort setHidden: YES];
    // Move the indicator every 12th sec.
    [progress setAnimationDelay: 5./60.];
    [progress setControlTint: NSProgressIndicatorPreferredThickness];
    [progress setUsesThreadedAnimation: NO];

    // Use our image cell type for the outline
    NSCell *cell = [ThumbnailCell new];
    NSTableColumn *tableColumn = [fileList tableColumnWithIdentifier: @"column1"];
    [tableColumn setDataCell: cell];
    [cell release];
}

- (void) applicationDidFinishLaunching: (NSNotification*) notification
{
    // Load the UI with data
    [self refreshClicked: self];
}

- (BOOL) validateMenuItem: (id<NSMenuItem>)item
{
    if (downloadRunning) {
        return NO;
    }
    if (refreshRunning && (TAG_HIDE !=[item tag])) {
        return NO;
    }
    if (((TAG_SAVESEL == [item tag]) || (TAG_DELETE == [item tag]))
            && (0 == [fileList numberOfSelectedRows])) {
        return NO;
    }
    return YES;
}

/**
 * Downloads a thumbnail image for a particular file from
 * the selected camera.
 * The returned image will already be scaled appropriately
 */
- (NSImage *) getThumbnail: (GSCamera *)camera 
                   forFile: (NSString *)file
                    atPath: (NSString *)path
{
    NSImage *image = [camera thumbnailForFile: file inPath: path];
    if (image) {
        NSSize size = [image size];
	// scale the image to our tablerow height
        double factor = (ROW_HEIGHT_IMAGE-4) / size.height;
        size.width *= factor;
        size.height *= factor;
        [image setScalesWhenResized: YES];
        [image setSize: size];
    }
    return image;
}

//
// Actions
//

- (void) abortClicked: (id)sender
{
    abortDownload = YES;
}

- (void) deleteSelectedClicked: (id)sender
{
    [self processSelectedImages: deleteAction];
}

- (void) saveSelectedClicked: (id)sender
{
    [self processSelectedImages: saveAction];
}

/**
 * Reacts on clicking the Show Thumbnails button by
 * setting the row height for the table and then reloading
 * the table.
 */
- (void) showThumbsClicked: (id)sender
{
    if (0 != [showThumbs state]) {
        [fileList setRowHeight: ROW_HEIGHT_IMAGE];
    } else {
        [fileList setRowHeight: ROW_HEIGHT_TEXT];
    }
    [fileList reloadData];
}

- (void) processImages: (id) params
{
    id pool = [NSAutoreleasePool new];
    OutlineItem *camera = [params objectForKey: CAMERA];
    NSArray *images = [params objectForKey: IMAGES];
    NSString *action = [params objectForKey: ACTION];
    NSString *downloadPath = nil;
    int counter = 0;
    TableItem *image;
    NSString *statusString;

    if ([action isEqualToString: saveAction]) {
        downloadPath = [params objectForKey: DOWNLOAD_PATH];
        statusString = _(@"Deleting image %@");
    } else {
        statusString = _(@"Downloading image %@");
    }
    NSEnumerator *e = [images objectEnumerator];
    while (!abortDownload && (image = [e nextObject]) != nil) {
        [statusText setStringValue: [NSString stringWithFormat: statusString, image->file]];
        if ([action isEqualToString: saveAction]) {
            [camera->camera getFile: image->file from: camera->path to:downloadPath];
        } else {
            [camera->camera deleteFile: image->file from: camera->path];
            // Remove the object from our data cache
	    [files removeObject: image];
        }
	[progress setDoubleValue: ++counter];
    }

    // Update the UI
    if ([action isEqualToString: deleteAction]) {
        [fileList reloadData];
    }

    [statusText setStringValue: @""];
    [progress setHidden: YES];
    [progress setDoubleValue: 0.];
    [abort setHidden: YES];
    [menu update];

    [pool release];
    downloadRunning = NO;
    [NSThread exit];
}

/**
 * Starts a new background thread to refresh the camera list.
 */
- (void) refreshClicked: (id)sender
{
    if (nil != photo2) {
        [photo2 release];
    }
    // We do not know how long it will take. Hence use an
    // indeterminate progress bar here.
    [self startProgressAnimationWithStatus:  _(@"Searching for cameras")];

    refreshRunning = YES;

    [NSThread detachNewThreadSelector: @selector(refreshThread:)
                             toTarget: self
                           withObject: nil];

    [NSTimer scheduledTimerWithTimeInterval: 0.5
                                     target: self
                                   selector: @selector(updateRefreshStatus:)
                                   userInfo: nil
                                    repeats: NO];
}

- (void) updateRefreshStatus: (id)timer
{
    if (refreshRunning) {
        [NSTimer scheduledTimerWithTimeInterval: 0.5
                                         target: self
                                       selector: @selector(updateRefreshStatus:)
                                       userInfo: nil
                                        repeats: NO];
        return;
    }

    // Update the UI
    [self stopProgressAnimation];
    
    if (0 == [photo2 numberOfCameras]) {
        [statusText setStringValue: _(@"No cameras detected.")];
    }

    [cameraTree reloadData];
    [menu update];
}

/**
 * Thread method to refresh the camera list.
 */
- (void) refreshThread: (id)anObject
{
    id pool = [NSAutoreleasePool new];
    photo2 = [GSGPhoto2 new];
    
    [pool release];
    refreshRunning = NO;
    [NSThread exit];
}


//
// outline view delegate methods
//
BOOL loaderRunning = NO;

/**
 * Thread method to refresh the camera list.
 */
- (void) loadFoldersThread: (id)anObject
{
    id pool = [NSAutoreleasePool new];
    OutlineItem *camera = (OutlineItem *)anObject;

    camera->subFolders = [camera->camera foldersInPath: camera->path];
    loaderRunning = NO;
    [pool release];
    [NSThread exit];
}

/**
 * Generates the appropriate OutlineItem object for the
 * requested row.
 */
- (id) outlineView: (NSOutlineView *)outlineView
             child: (int)index
            ofItem: (id)item
{
    if (item == nil) {
        OutlineItem *camera = [[OutlineItem new] autorelease];
	camera->camera = [photo2 cameraAtIndex: index];
	camera->path = @"/";
	camera->subFolders = [camera->camera foldersInPath: camera->path];
        [self startProgressAnimationWithStatus: _(@"Loading image information from camera.")];

        loaderRunning = YES;
        [NSThread detachNewThreadSelector: @selector(loadFoldersThread:)
                                 toTarget: self
                               withObject: camera];
	while (YES == loaderRunning) {
	    [NSThread sleepForTimeInterval: 0.2];
	}

	[self stopProgressAnimation];
	return camera;
    }
    if ([item isKindOfClass: [OutlineItem class]]) {
        OutlineItem *parent = (OutlineItem*)item;
        OutlineItem *camera = [[OutlineItem new] autorelease];
        [self startProgressAnimationWithStatus: _(@"Loading image information from camera.")];
        camera->camera = parent->camera;
        camera->path = [[parent->path stringByAppendingPathComponent:
            [parent->subFolders objectAtIndex: index]] retain];

        loaderRunning = YES;
	NSRunLoop *theRL = [NSRunLoop currentRunLoop];

        [NSThread detachNewThreadSelector: @selector(loadFoldersThread:)
                                 toTarget: self
                               withObject: camera];
	while (loaderRunning && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]);

	[self stopProgressAnimation];
	return camera;
    }
    return nil;
}

- (BOOL) outlineView: (NSOutlineView *)outlineView
    isItemExpandable: (id) item
{
    return [self outlineView: outlineView numberOfChildrenOfItem: item] > 0;
}

- (int)     outlineView: (NSOutlineView *)outlineView 
 numberOfChildrenOfItem: (id)item
{
    if (nil == photo2) {
        return 0;
    }
    if (item == nil) {
        return [photo2 numberOfCameras];
    }
    if ([item isKindOfClass: [OutlineItem class]]) {
	return [((OutlineItem*)item)->subFolders count];
    }
    return 0;
}

- (id)         outlineView: (NSOutlineView *)outlineView 
 objectValueForTableColumn: (NSTableColumn *)tableColumn 
                    byItem: (id)item
{
    if ([[tableColumn identifier] isEqual: @"cameras"]) {
        // For root items display the camera name, otherwise
        // the path component.
        if ([@"/" isEqualToString: ((OutlineItem*)item)->path]) {
            return [((OutlineItem*)item)->camera name];
        } else {
            return [((OutlineItem*)item)->path lastPathComponent];
        }
    }

    return nil;
}

- (void) outlineViewSelectionDidChange: (NSNotification*) notification
{
    NSOutlineView *ol = [notification object];
    int row = [ol selectedRow];
    OutlineItem * camera = [ol itemAtRow: row];
    if (nil != files) {
        [files release];
	files = nil;
    }

    if (nil != camera) {
        [self startProgressAnimationWithStatus: _(@"Loading image information from camera.")];

        NSArray *ar = [camera->camera filesInPath: camera->path];
        files = [NSMutableArray new];
        int i;
        for (i = 0; i < [ar count]; i++) {
            TableItem *image = [TableItem new];
            image->file = [[ar objectAtIndex: i] retain];
            // We do not download thumbnails right now. This may take
	    // too much time. Instead they are loaded on demand when
	    // the item is displayed and the user wants it.
            image->image = nil;
            [files addObject: image];
            [image release];
        }
        [ar release];

        [self stopProgressAnimation];
    }

    [fileList reloadData];
}


//
// table view delegate methods
//
- (int) numberOfRowsInTableView: (NSTableView *) tableView
{
    if (nil != files) {
        return [files count];
    }
    return 0;
}

- (id)           tableView: (NSTableView *) tableView
 objectValueForTableColumn: (NSTableColumn *) tableColumn
                       row: (int) row
{
    if (nil != files) {
        TableItem *image = [files objectAtIndex: row];
	return image->file;
    }
    return nil;
}


- (void) tableView: (NSTableView *) tableView
   willDisplayCell: (id) aCell
    forTableColumn: (NSTableColumn *) tableColumn
               row: (int) row
{
    if (0 != [showThumbs state]) {
        TableItem *image = [files objectAtIndex: row];
        if (nil == image->image) {
            int idx = [cameraTree selectedRow];
            OutlineItem * camera = [cameraTree itemAtRow: idx];
            image->image = [self getThumbnail: camera->camera
                                      forFile: image->file
                                       atPath: camera->path];
        }
        if (image->image) {
            [aCell setImage: image->image];
        }
    } else {
        [aCell setImage: nil];
    }
}

- (void) tableViewSelectionDidChange: (NSNotification*) notification
{
    [menu update];
}

@end
