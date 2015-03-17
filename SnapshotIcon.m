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
#include "SnapshotIcon.h"
#include "SnapshotIconView.h"

static NSDictionary *fontAttr = nil;


@implementation SnapshotIcon

- (void)dealloc
{
    RELEASE (icon);
    RELEASE (label);
    RELEASE (fileName);

    [super dealloc];
}

+ (void)initialize
{
    static BOOL initialized = NO;

    if (initialized == NO) {
        NSFont *font = [NSFont systemFontOfSize: 10];

        ASSIGN (fontAttr, [NSDictionary dictionaryWithObject: font
                               forKey: NSFontAttributeName]);  
        initialized = YES;
    }
}

- (id) initWithIconImage: (NSImage *) img
                fileName: (NSString *) fname
            andContainer: (SnapshotIconView *) cont
{
    self = [super init];

    if (self) {
        labelRect = NSZeroRect;
    
        labelRect.size = [fname sizeWithAttributes: fontAttr];
        label = [NSTextFieldCell new];
        [label setStringValue: fname];
	[label setFont: [NSFont systemFontOfSize: 10]];
    
	container = cont;
        ASSIGN (fileName, fname);
        ASSIGN (icon, img);
        iconSize = [icon size];
        iconPoint = NSZeroPoint;
        iconBounds = NSMakeRect(0, 0, iconSize.width, iconSize.height);
        isSelected = NO;
    }
  
    return self;
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
    float yspace = 2.0;

    iconPoint.x = floor((rect.size.width - iconSize.width) / 2 + 0.5);
    iconPoint.y = floor(labelRect.size.height + 2*yspace + 0.5);
 
    iconBounds.origin.x = iconPoint.x;
    iconBounds.origin.y = iconPoint.y;
    iconBounds = NSIntegralRect(iconBounds);

    if (labelRect.size.width >= rect.size.width) {
        labelRect.origin.x = 0;
    } else {
        labelRect.origin.x = (rect.size.width - labelRect.size.width) / 2;
    }
  
    labelRect.origin.y = iconPoint.y - labelRect.size.height - yspace;
    labelRect = NSIntegralRect(labelRect);
 
    [self setNeedsDisplay: YES]; 
}

- (void)mouseDown:(NSEvent *)theEvent
{
    NSPoint location = [theEvent locationInWindow];
    NSPoint selfloc = [self convertPoint: location fromView: nil];
    BOOL onself = NO;

    onself = ([self mouse: selfloc inRect: iconBounds]
                        || [self mouse: selfloc inRect: labelRect]);

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
    if (isSelected) {
	[[NSColor selectedControlColor] set];
	NSRectFill(rect);
    } else {
	[[NSColor windowBackgroundColor] set];
	NSRectFill(rect);
    }
    [icon compositeToPoint: iconPoint operation: NSCompositeSourceOver];

    [label drawWithFrame: labelRect inView: self];
}

@end
































