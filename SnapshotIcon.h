/*
 *    SnapshotIcon.h
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

#ifndef SNAPSHOTICON_H_INC
#define SNAPSHOTICON_H_INC

#include <Foundation/Foundation.h>
#include <AppKit/NSView.h>

@class NSImage;
@class NSTextFieldCell;
@class SnapshotIconView;

@interface SnapshotIcon : NSView
{
    SnapshotIconView *container;
    NSImage *icon;
    NSString *fileName;
    NSSize iconSize;
    NSPoint iconPoint;
    NSRect iconBounds;
    NSDictionary *iconInfo;

    BOOL isSelected;
}

- (id) initWithIconImage: (NSImage *) img
                fileName: (NSString *) fname
            andContainer: (SnapshotIconView *) cont;

- (NSSize) iconSize;
- (NSRect) iconBounds;

- (void) tile;
 
- (void) select;

- (void) unselect;

- (BOOL) isSelected;

- (NSString *) fileName;

- (NSImage *) icon;

- (void) setIconInfo: (NSDictionary *)info;

- (NSUInteger) fileSize;
- (NSUInteger) height;
- (NSUInteger) width;
- (NSString *) date;

@end

#endif // SNAPSHOTICON_H_INC
