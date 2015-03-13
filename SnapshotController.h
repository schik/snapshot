/*
 *    SnapshotController.h
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

#ifndef SNAPSHOTCONTROLLER_H_INC
#define SNAPSHOTCONTROLLER_H_INC


#include <AppKit/AppKit.h>

#include <CameraKit/GSGPhoto2.h>

@interface SnapshotController : NSObject
{
    id cameraTree;
    id fileList;
    id statusText;
    id progress;
    id menu;
    id abort;
    NSMutableArray *files;
    GSGPhoto2 *photo2;
}

- (void) refreshClicked: (id)sender;

@end


#endif
