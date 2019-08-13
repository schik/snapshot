/*
 *    SnapshotIcon.m
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
#include <math.h>
#include "NSImage+Transform.h"
#include "SnapshotIcon.h"
#include "SnapshotIconView.h"


@implementation SnapshotIcon

- (void)dealloc
{
    RELEASE(icon);
    RELEASE(fileName);
    RELEASE(iconInfo);

    [super dealloc];
}

- (id) initWithIconImage: (NSImage *) img
                fileName: (NSString *) fname
            andContainer: (SnapshotIconView *) cont
{
    self = [super init];

    if (self) {
        container = cont;
        ASSIGN(fileName, fname);
        ASSIGN(icon, img);
        iconSize = [icon size];
        iconPoint = NSZeroPoint;
        iconBounds = NSMakeRect(0, 0, iconSize.width, iconSize.height);
        isSelected = NO;
    }
  
    return self;
}

- (void) setIconInfo: (NSDictionary *)info
{
    if (nil != iconInfo) {
        [iconInfo release];
        iconInfo = nil;
    }
    if (nil != info) {
        ASSIGN(iconInfo, info);
    }
}

- (NSDictionary *) iconInfo
{
    return iconInfo;
}

- (void) select
{
    if (isSelected) {
        return;
    }
    isSelected = YES;
  
    [container unselectOtherImages: self];
    [container selectionDidChange];	
    [self setNeedsDisplay: YES]; 
}

- (void) unselect
{
    if (isSelected == NO) {
        return;
    }
    isSelected = NO;
    [self setNeedsDisplay: YES];
}

- (BOOL) isSelected
{
    return isSelected;
}

- (NSString *) fileName
{
    return fileName;
}

- (NSImage *) icon
{
    return icon;
}

- (NSUInteger) fileSize
{
    if (nil != iconInfo) {
        return [[iconInfo objectForKey: @"size"] intValue];
    }
    return 0;
}

- (NSUInteger) height;
{
    if (nil != iconInfo) {
        return [[iconInfo objectForKey: @"height"] intValue];
    }
    return 0;
}

- (NSUInteger) width;
{
    if (nil != iconInfo) {
        return [[iconInfo objectForKey: @"width"] intValue];
    }
    return 0;
}

- (NSDate *) date;
{
    if (nil != iconInfo) {
        return [iconInfo objectForKey: @"mtime"];
    }
    return [NSDate dateWithTimeIntervalSince1970:0];
}

- (NSString *) exposureTime {
    return [iconInfo objectForKey: @"exptime"];
}

- (NSString *) fNumber
{
    return [iconInfo objectForKey: @"fnumber"];
}

- (NSSize) iconSize
{
    return iconSize;
}

- (NSRect) iconBounds
{
    return iconBounds;
}

- (void) tile
{
    NSRect rect = [self frame];

    iconPoint.x = floor((rect.size.width - iconSize.width) / 2 + 0.5);
    iconPoint.y = floor((rect.size.height - iconSize.height) / 2 + 0.5);
 
    iconBounds.origin.x = iconPoint.x;
    iconBounds.origin.y = iconPoint.y;
    iconBounds = NSIntegralRect(iconBounds);

    [self setNeedsDisplay: YES]; 
}

- (void) fixOrientation
{
    NSNumber *num = [iconInfo objectForKey: @"orientation"];
    if (nil != num) {
	NSImage *newIcon = nil;
        int o = [num intValue];
        switch (o) {
            case 3:
                newIcon = [icon imageRotatedByDegrees: 180];
                break;
            case 6:
                newIcon = [icon imageRotatedByDegrees: 270];
                break;
            case 8:
                newIcon = [icon imageRotatedByDegrees: 90];
                break;
        }
        if (nil != newIcon) {
            ASSIGN(icon, newIcon);
            iconSize = [icon size];
            iconPoint = NSZeroPoint;
            iconBounds = NSMakeRect(0, 0, iconSize.width, iconSize.height);
        }
    }
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint location = [theEvent locationInWindow];
    NSPoint selfloc = [self convertPoint: location fromView: nil];
    BOOL onself = NO;

    onself = ([self mouse: selfloc inRect: iconBounds]);

    if (onself) {
        if ([theEvent clickCount] == 1) {
            if (isSelected == NO) {
            }
            if ([theEvent modifierFlags] & NSShiftKeyMask) {
                [container setSelectionMask: SIMultipleSelectionMask];
                if (isSelected) {
                    if ([container selectionMask] == SIMultipleSelectionMask) {
                        [self unselect];
                        [container selectionDidChange];	
                        return;
                    }
                } else {
                    [self select];
                }
        
            } else {
                [container setSelectionMask: SISingleSelectionMask];
                if (isSelected == NO) {
                    [self select];
                }
            }
        } 
    } else {
        [container mouseDown: theEvent];
    }
    [self setNeedsDisplay: YES];  
}

- (void)mouseUp:(NSEvent *)theEvent
{
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent
{
    return YES;
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

- (void)drawRect: (NSRect)rect
{
    CGFloat frameWidth = 6.0;
    if (isSelected) {
        frameWidth = 8.0;
    }

    NSRect shadowRect = NSMakeRect(iconBounds.origin.x + frameWidth/2., iconBounds.origin.y - frameWidth/2.,
            iconBounds.size.width, iconBounds.size.height);
    NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect: shadowRect
                                                         xRadius: 0.5
                                                         yRadius: 0.5];
    [path setLineWidth: frameWidth+2.0];
    [[NSColor colorWithCalibratedRed: 0.17 green: 0.17 blue: 0.17 alpha: .1] set];
    [path stroke];
    [path setLineWidth: frameWidth];
    [[NSColor colorWithCalibratedRed: 0.17 green: 0.17 blue: 0.17 alpha: .5] set];
    [path stroke];
    [path setLineWidth: frameWidth-2.0];
    [[NSColor colorWithCalibratedRed: 0.17 green: 0.17 blue: 0.17 alpha: 1.] set];
    [path stroke];

    if (isSelected) {
        path = [NSBezierPath bezierPathWithRoundedRect: iconBounds
                                               xRadius: 0.5
                                               yRadius: 0.5];
        [path setLineWidth: frameWidth];
        [[NSColor colorWithCalibratedRed: 0.91 green: 0.6 blue: 0.15 alpha: 1.] set];
        [path stroke];
    } else {
        path = [NSBezierPath bezierPathWithRoundedRect: iconBounds
                                               xRadius: 0.5
                                               yRadius: 0.5];
        [path setLineWidth: frameWidth];
        [[NSColor colorWithCalibratedRed: 0.67 green: 0.67 blue: 0.67 alpha: 1.] set];
        [path stroke];
    }
    [icon compositeToPoint: iconPoint operation: NSCompositeSourceOver];
}

@end
































