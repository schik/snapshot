/* Inspector.h
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

#ifndef INSPECTOR_H
#define INSPECTOR_H

#include <Foundation/Foundation.h>

@class Attributes;
@class NSPopUpButton;
@class NSWindow;

@interface Inspector : NSObject 
{
    id topBox;
    id iconView;
    id titleField;

    NSWindow *window;
    NSPopUpButton *popUp;
    NSBox *inspBox;

    NSMutableArray *inspectors;
    id currentInspector;
}

- (void)activate;

- (IBAction) activateInspector: (id)sender;

- (void) showAttributes;

- (id) attributes;

- (NSWindow *)window;

- (void)updateDefaults;

@end

#endif // INSPECTOR_H
