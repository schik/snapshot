/*
 *    SnapshotIconView.m
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

#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <AppKit/AppKit.h>
#include "SnapshotIconView.h"
#include "SnapshotIcon.h"
#include "Constants.h"

#define MARGIN 20

#ifndef max
  #define max(a,b) ((a) >= (b) ? (a):(b))
#endif

#ifndef min
  #define min(a,b) ((a) <= (b) ? (a):(b))
#endif


@implementation SnapshotIconView

- (void)dealloc
{
    RELEASE(icons);
  
    [super dealloc];
}

- (id) initWithFrame: (NSRect)rect
{
    self = [super initWithFrame: rect];

    if (self) {
        icons = [NSMutableArray new];
    }
  
    return self;
}

- (void) setSelectionMask: (SISelectionMask)mask
{
    selectionMask = mask;
}

- (SISelectionMask) selectionMask
{
    return selectionMask;
}

- (void) addIcon: (SnapshotIcon *) icon
{
    [icon fixOrientation];
    [icons addObject: icon];
    [self addSubview: icon];
}

- (void) removeAllIcons
{
    unsigned i;
    for (i = [icons count]; i > 0; i--) {
        NSView *subview = [[self subviews] objectAtIndex: i-1];
        [subview removeFromSuperview];
    }
    [icons removeAllObjects];
    [self tile];
}

- (NSArray *) selectedIcons
{
    NSMutableArray *selectedIcons = [NSMutableArray array];
    NSUInteger i;
  
    for (i = 0; i < [icons count]; i++) {
        SnapshotIcon *icon = [icons objectAtIndex: i];

        if ([icon isSelected]) {
            [selectedIcons addObject: icon];
        }
    }

    return [selectedIcons makeImmutableCopyOnFail: NO];
}

- (void) unselectOtherImages: (id)anIcon
{
    NSUInteger i;

    if (selectionMask & SIMultipleSelectionMask) {
        return;
    }
    for (i = 0; i < [icons count]; i++) {
        SnapshotIcon *icon = [icons objectAtIndex: i];

        if (icon != anIcon) {
            [icon unselect];
        }
    }
}

- (void) tile
{
    NSRect rect = [[self superview] frame];

    int xcount = rect.size.width / (THUMBNAIL_WIDTH + MARGIN);
    int ycount = [icons count] / xcount + 1;
    rect = NSMakeRect(rect.origin.x, -ycount * (THUMBNAIL_WIDTH + MARGIN),
	   rect.size.width, ycount * (THUMBNAIL_WIDTH + MARGIN));
    [super setFrame: rect];

    int xpos = 0;
    int ypos = rect.size.height - THUMBNAIL_WIDTH - MARGIN;
    unsigned i;

    for (i = 0; i < [icons count]; i++) {
        NSRect r = NSMakeRect(xpos, ypos, THUMBNAIL_WIDTH + MARGIN, THUMBNAIL_WIDTH + MARGIN);
  
        [[icons objectAtIndex: i] setFrame: r];
    
        xpos += THUMBNAIL_WIDTH + MARGIN;
    
        if (xpos > (rect.size.width - (THUMBNAIL_WIDTH + MARGIN))) {
            xpos = 0;
            ypos -= (THUMBNAIL_WIDTH + MARGIN);
        }
    }
         
    [self setNeedsDisplay: YES]; 
}

- (void)setFrame:(NSRect)frameRect
{
    [super setFrame: frameRect];
  
    if ([self superview]) {
        [self tile];
    }
}

- (void)resizeWithOldSuperviewSize:(NSSize)oldBoundsSize
{
    [self tile];
}

- (void)drawRect:(NSRect)rect
{
    if ([self superview]) {
        [[(NSScrollView *)[self superview] backgroundColor] setFill];
        NSRectFill(rect);
    }
    [super drawRect: rect];
}

- (void) selectionDidChange
{
    if (!(selectionMask & SICreatingSelectionMask)) {
        NSArray *selection = [self selectedIcons];
        [[NSNotificationCenter defaultCenter]
            postNotificationName: @"ImageSelectionChanged"
            object: nil
            userInfo: [NSDictionary dictionaryWithObject: selection forKey: @"Images"]];
    }
}

- (void) mouseUp: (NSEvent *)theEvent
{
    [self setSelectionMask: SISingleSelectionMask];        
}

- (void) mouseDown: (NSEvent *)theEvent
{
    if ([theEvent modifierFlags] != NSShiftKeyMask) {
        selectionMask = SISingleSelectionMask;
        selectionMask |= SICreatingSelectionMask;
        [self unselectOtherImages: nil];
        selectionMask = SISingleSelectionMask;
        [self selectionDidChange];
    }
}

- (void)mouseDragged:(NSEvent *)theEvent
{
    unsigned int eventMask = NSLeftMouseUpMask | NSLeftMouseDraggedMask | NSPeriodicMask;
    NSDate *future = [NSDate distantFuture];
    NSPoint sp;
    NSPoint p, pp;
    NSRect visibleRect;
    NSRect oldRect; 
    NSRect r;
    NSRect selrect;
    float x, y, w, h;
    NSUInteger i;

    pp = NSMakePoint(0,0);

#define scrollPointToVisible(p) \
{ \
NSRect sr; \
sr.origin = p; \
sr.size.width = sr.size.height = 1.0; \
[self scrollRectToVisible: sr]; \
}

#define CONVERT_CHECK \
{ \
NSRect br = [self bounds]; \
pp = [self convertPoint: p fromView: nil]; \
if (pp.x < 1) \
pp.x = 1; \
if (pp.x >= NSMaxX(br)) \
pp.x = NSMaxX(br) - 1; \
if (pp.y < 0) \
pp.y = -1; \
if (pp.y > NSMaxY(br)) \
pp.y = NSMaxY(br) + 1; \
}

    p = [theEvent locationInWindow];
    sp = [self convertPoint: p  fromView: nil];
  
    oldRect = NSZeroRect;  

    [[self window] disableFlushWindow];

    [NSEvent startPeriodicEventsAfterDelay: 0.02 withPeriod: 0.05];

    while ([theEvent type] != NSLeftMouseUp) {
        CREATE_AUTORELEASE_POOL (arp);

        theEvent = [NSApp nextEventMatchingMask: eventMask
                                      untilDate: future
                                         inMode: NSEventTrackingRunLoopMode
                                        dequeue: YES];

        if ([theEvent type] != NSPeriodic) {
            p = [theEvent locationInWindow];
        }
    
        CONVERT_CHECK;
    
        visibleRect = [self visibleRect];
    
        if ([self mouse: pp inRect: visibleRect] == NO) {
            scrollPointToVisible(pp);
            CONVERT_CHECK;
        }

        x = min(sp.x, pp.x);
        y = min(sp.y, pp.y);
        w = max(1, max(pp.x, sp.x) - min(pp.x, sp.x));
        h = max(1, max(pp.y, sp.y) - min(pp.y, sp.y));

        r = NSMakeRect(x, y, w, h);
    
        // Erase the previous rect
        [self setNeedsDisplayInRect: oldRect];
        [[self window] displayIfNeeded];
 
        // Draw the new rect
        [self lockFocus];

        [[NSColor darkGrayColor] set];
        NSFrameRect(r);
        [[[NSColor darkGrayColor] colorWithAlphaComponent: 0.33] set];
        NSRectFillUsingOperation(r, NSCompositeSourceOver);
     
        [self unlockFocus];

        oldRect = r;

        [[self window] enableFlushWindow];
        [[self window] flushWindow];
        [[self window] disableFlushWindow];

        DESTROY (arp);
    }
  
    [NSEvent stopPeriodicEvents];
    [[self window] postEvent: theEvent atStart: NO];

    // Erase the previous rect
    [self setNeedsDisplayInRect: oldRect];
    [[self window] displayIfNeeded];
  
    [[self window] enableFlushWindow];
    [[self window] flushWindow];

    selectionMask = SIMultipleSelectionMask;
    selectionMask |= SICreatingSelectionMask;

    x = min(sp.x, pp.x);
    y = min(sp.y, pp.y);
    w = max(1, max(pp.x, sp.x) - min(pp.x, sp.x));
    h = max(1, max(pp.y, sp.y) - min(pp.y, sp.y));

    selrect = NSMakeRect(x, y, w, h);
  
    for (i = 0; i < [icons count]; i++) {
        SnapshotIcon *icon = [icons objectAtIndex: i];
        NSRect iconBounds = [self convertRect: [icon iconBounds] fromView: icon];

        if (NSIntersectsRect(selrect, iconBounds)) {
          [icon select];
        } 
    }  
  
    selectionMask = SISingleSelectionMask;
  
    [self selectionDidChange];
}

@end
































