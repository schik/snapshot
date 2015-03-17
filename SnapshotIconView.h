/*
 *    SnapshotIconView.h
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

#ifndef SNAPSHOTICONVIEW_H_INC
#define SNAPSHOTICONVIEW_H_INC

#include <Foundation/Foundation.h>
#include <AppKit/NSView.h>

@class SnapshotIcon;

typedef enum SISelectionMask {
    SISingleSelectionMask = 0,
    SIMultipleSelectionMask = 1,
    SICreatingSelectionMask = 2
} SISelectionMask;

@interface SnapshotIconView : NSView
{
    NSMutableArray *icons;
    SISelectionMask selectionMask;
}

- (void) setSelectionMask: (SISelectionMask)mask;
- (SISelectionMask) selectionMask;

- (void) addIcon: (SnapshotIcon *)icon;
- (void) removeAllIcons;
- (NSArray *) selectedIcons;

- (void) unselectOtherImages: (id)anIcon;
- (void) selectionDidChange;

- (void) tile;

- (void) mouseUp: (NSEvent *)theEvent;
- (void) mouseDown: (NSEvent *)theEvent;

@end

#endif // SNAPSHOTICONVIEW_H_INC
