/* Attributes.h
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

@interface Attributes : NSObject
{
    id window;
    id mainBox;
    id topBox;

    id dateField;
    id timeField;

    id exposureField;
    id sizeField;
    id imageSizeField;
  
    id iconView;
    id titleField;

//    id exifInfoTable;

//    NSDictionary *iconInfo;
    id inspector;
}

- (id) initForInspector: (id)insp;

- (NSView *) inspView;

- (NSString *) winname;

- (void) setImages: (NSArray *)images;

- (void) updateDefaults;

@end
