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
#include "SnapshotIcon.h"
#include "SnapshotIconView.h"
#include "Constants.h"


// If set to YES a camera search is in progress
static BOOL refreshRunning = NO;

// Idicators for the currently performed action
static NSString *deleteAction = @"Delete";
static NSString *saveAction = @"Save";

// If set to YES an image download/deletion is in progress
static BOOL downloadRunning = NO;
// If set to YES the abort button was pressed
static BOOL abortDownload = NO;
// The name of the image that is currently downloaded
static NSString *downloadImage = @"";
// The counter for downloaded images
static int downloadCounter = 0;

// If set to YES subfolder information is loaded
BOOL loadingFolders = NO;
// If set to YES the thumbnails in the selected folder are loaded
BOOL loadingThumbnails = NO;


/**
 * This class represents the items stored in the OutlineView
 */
@interface OutlineItem: NSObject
{
@public
    GSCamera *camera;
    NSString *path;
    NSArray *subFolders;
    NSMutableArray *files;
}

- (id) init;

@end

@implementation OutlineItem

- (id) init
{
    self = [super init];
    if (self != nil) {
        camera = nil;
	path = nil;
	subFolders = nil;
        files = nil;
    }
    return self;
}

- (void) dealloc
{
    // We expect that the values for ivars are retained
    // for us by our creator. 
    if (nil != files) {
        [files release];
    }
    if (nil != subFolders) {
        [subFolders release];
    }
    if (nil != path) {
        [path release];
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
    NSMutableDictionary *threadParams = [NSMutableDictionary new];
    int idx = [cameraTree selectedRow];
    OutlineItem * camera = [cameraTree itemAtRow: idx];
    NSArray * images = [iconView selectedIcons];

    if ([action isEqualToString: deleteAction]) {
        if (NSRunAlertPanel(_(@"Delete images"),
                _(@"Please confirm that you wich to delete the sected images."),
                _(@"Do not delete"), _(@"Delete"), nil) == NSAlertDefaultReturn) {
            return;
        }
    } else {
        NSString *dest = [self getDestination];
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

    downloadImage = @"";
    downloadCounter = 0;
    downloadRunning = YES;
    abortDownload = NO;

    NSString *statusString;

    if ([action isEqualToString: saveAction]) {
        statusString = _(@"Downloading image %@");
    } else {
        statusString = _(@"Deleting image %@");
    }

    // Start the worker
    NSRunLoop *theRL = [NSRunLoop currentRunLoop];

    [NSThread detachNewThreadSelector: @selector(processImages:)
                             toTarget: self
                           withObject: threadParams];

    while (downloadRunning && [theRL runMode: NSDefaultRunLoopMode beforeDate: [NSDate distantFuture]]) {
        [statusText setStringValue: [NSString stringWithFormat: statusString, downloadImage]];
	[progress setDoubleValue: downloadCounter];
    }

    // Update the UI
    if ([action isEqualToString: deleteAction]) {
        [iconView removeAllIcons];
        unsigned i;
        for (i = 0; i < [camera->files count]; i++) {
            CREATE_AUTORELEASE_POOL(pool);
            SnapshotIcon *icon = [camera->files objectAtIndex: i];
            [iconView addIcon: icon];
            RELEASE (pool);
        }
        [iconView tile];
    }

    [statusText setStringValue: @""];
    [progress setHidden: YES];
    [progress setDoubleValue: 0.];
    [abort setHidden: YES];
    [menu update];

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
    }
    return self;
}

- (void) dealloc
{
    if (nil != photo2) {
        [photo2 release];
    }
    if (nil != inspector) {
        [inspector release];
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

    // We set our autosave window frame name and restore the one from the user's defaults.
    [[self window] setFrameAutosaveName: @"SnapshotWindow"];
    [[self window] setFrameUsingName: @"SnapshotWindow"];

    inspector = [Inspector new];
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
            && (0 == [[iconView selectedIcons] count])) {
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
	// scale the image to our tablerow width
	double factor = THUMBNAIL_WIDTH / size.width;
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

- (void) processImages: (id) params
{
    id pool = [NSAutoreleasePool new];
    OutlineItem *camera = [params objectForKey: CAMERA];
    NSArray *images = [params objectForKey: IMAGES];
    NSString *action = [params objectForKey: ACTION];
    NSString *downloadPath = nil;
    SnapshotIcon *image;

    if ([action isEqualToString: saveAction]) {
        downloadPath = [params objectForKey: DOWNLOAD_PATH];
    }
    NSEnumerator *e = [images objectEnumerator];
    while (!abortDownload && (image = [e nextObject]) != nil) {
	downloadImage = [image fileName];
        if ([action isEqualToString: saveAction]) {
            [camera->camera getFile: [image fileName] from: camera->path to: downloadPath];
        } else {
            [camera->camera deleteFile: [image fileName] from: camera->path];
            // Remove the object from our data cache
	    [camera->files removeObject: image];
        }
	downloadCounter++;
    }

    [pool release];
    downloadRunning = NO;
    [NSThread exit];
}

- (void) showInspector: (id)sender
{
    [inspector activate];
    [inspector updateDefaults];
}

- (void) showPropertyInspector: (id)sender
{
    [self showInspector: nil]; 
    [inspector showAttributes];
    [iconView selectionDidChange];
}

/**
 * Starts a new background thread to refresh the camera list.
 */
- (void) refreshClicked: (id)sender
{
    if (nil != photo2) {
        [photo2 release];
	photo2 = nil;
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

/**
 * Thread method to refresh the camera folder list.
 */
- (void) loadFoldersThread: (id)anObject
{
    id pool = [NSAutoreleasePool new];
    OutlineItem *camera = (OutlineItem *)anObject;

    camera->subFolders = [camera->camera foldersInPath: camera->path];
    loadingFolders = NO;
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
    OutlineItem *camera = nil;
    
    if (item == nil) {
        camera = [[OutlineItem new] autorelease];
	camera->camera = [photo2 cameraAtIndex: index];
	camera->path = @"/";
    }
    if ([item isKindOfClass: [OutlineItem class]]) {
        OutlineItem *parent = (OutlineItem*)item;
        camera = [[OutlineItem new] autorelease];
        camera->camera = parent->camera;
        camera->path = [[parent->path stringByAppendingPathComponent:
            [parent->subFolders objectAtIndex: index]] retain];
    }
    if (nil != camera) {
        [self startProgressAnimationWithStatus: _(@"Loading image information from camera.")];

        loadingFolders = YES;
	NSRunLoop *theRL = [NSRunLoop currentRunLoop];

        [NSThread detachNewThreadSelector: @selector(loadFoldersThread:)
                                 toTarget: self
                               withObject: camera];
	while (loadingFolders && [theRL runMode: NSDefaultRunLoopMode beforeDate: [NSDate distantFuture]]);

	[self stopProgressAnimation];
    }
    return camera;
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


/**
 * Thread method to refresh the image list.
 */
- (void) loadImagesThread: (id)anObject
{
    id pool = [NSAutoreleasePool new];

    OutlineItem *camera = (OutlineItem *)anObject;
    NSArray *ar = [camera->camera filesInPath: camera->path];
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle: NSDateFormatterLongStyle];
    [dateFormatter setTimeStyle: NSDateFormatterMediumStyle];
    int i;
    for (i = 0; i < [ar count]; i++) {
	NSString *fname = [ar objectAtIndex: i];
	NSImage *icon = [self getThumbnail: camera->camera
                                   forFile: fname
                                    atPath: camera->path];
        NSDictionary *info = [camera->camera infoForFile: fname inPath: camera->path];
	SnapshotIcon *image = [[SnapshotIcon alloc] initWithIconImage: icon
                                                             fileName: fname
                                                         andContainer: iconView];
	[image setIconInfo: info];
        [camera->files addObject: image];
        [image autorelease];
    }
    [ar release];
    [dateFormatter release];

    loadingThumbnails = NO;
    [pool release];
    [NSThread exit];
}

- (void) outlineViewSelectionDidChange: (NSNotification*) notification
{
    NSOutlineView *ol = [notification object];
    int row = [ol selectedRow];
    OutlineItem * camera = [ol itemAtRow: row];
    unsigned count = 0;

    [iconView removeAllIcons];
    if ((nil != camera) && (nil == camera->files)) {
        camera->files = [NSMutableArray new];
        [self startProgressAnimationWithStatus: _(@"Loading image information from camera")];

        loadingThumbnails = YES;
	NSRunLoop *theRL = [NSRunLoop currentRunLoop];

        [NSThread detachNewThreadSelector: @selector(loadImagesThread:)
                                 toTarget: self
                               withObject: camera];
        while (loadingThumbnails && [theRL runMode: NSDefaultRunLoopMode
                                        beforeDate: [NSDate distantFuture]]) {
            unsigned current = [camera->files count];
	    if ((current - count) >= 10) {
		unsigned i;
                for (i = count; i < current; i++) {
                    CREATE_AUTORELEASE_POOL(pool);
                    SnapshotIcon *icon = [camera->files objectAtIndex: i];
                    [iconView addIcon: icon];
                    RELEASE (pool);
                }
                [iconView tile];

		count = current;
            }
        }

	[self stopProgressAnimation];
    }

    // add remaining icons
    unsigned i;
    for (i = count; i < [camera->files count]; i++) {
        CREATE_AUTORELEASE_POOL(pool);
        SnapshotIcon *icon = [camera->files objectAtIndex: i];
        [iconView addIcon: icon];
        RELEASE (pool);
    }
    [iconView tile];
}


@end
