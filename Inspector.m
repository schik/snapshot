/* Inspector.m
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
#import <AppKit/AppKit.h>

#import "Inspector.h"
#import "ContentViewersProtocol.h"
#import "Attributes.h"

#define ATTRIBUTES   0

static NSString *nibName = @"InspectorWin";

@implementation Inspector

- (void)dealloc
{
  [nc removeObserver: self];
  RELEASE (inspectors);
  RELEASE (win);
   
  [super dealloc];
}

- (id)init
{
  self = [super init];
  
  if (self) {
    if ([NSBundle loadNibNamed: nibName owner: self] == NO) {
      NSLog(@"failed to load %@!", nibName);
      DESTROY (self);
      return self;
    } 
    
    [win setFrameUsingName: @"inspector"];
    [win setDelegate: self];
  
    inspectors = [NSMutableArray new];
    nc = [NSNotificationCenter defaultCenter];

    while ([[popUp itemArray] count] > 0) {
      [popUp removeItemAtIndex: 0];
    }

    currentInspector = [[Attributes alloc] initForInspector: self];
    [inspectors insertObject: currentInspector atIndex: ATTRIBUTES]; 
    [popUp insertItemWithTitle: NSLocalizedString(@"Attributes", @"") 
                       atIndex: ATTRIBUTES];
    [[popUp itemAtIndex: ATTRIBUTES] setKeyEquivalent: @"1"];
    DESTROY (currentInspector);

    [nc addObserver: self 
           selector: @selector(watcherNotification:) 
               name: @"GWFileWatcherFileDidChangeNotification"
             object: nil];    
  }
  
  return self;
}

- (void)activate
{
  [win makeKeyAndOrderFront: nil];

  if (currentInspector == nil) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    id entry = [defaults objectForKey: @"last_active_inspector"];
    int index = 0;
    
    if (entry) {
      index = [entry intValue];
      index = ((index < 0) ? 0 : index);
    }
    
    [popUp selectItemAtIndex: index];
    [self activateInspector: popUp];
  }
}

- (void)setCurrentSelection:(NSArray *)selection
{
  if (selection) {
//    ASSIGN (currentPaths, selection);
    if (currentInspector) {
//      [currentInspector activateForPaths: currentPaths];
    }
  }
}

- (BOOL)canDisplayDataOfType:(NSString *)type
{
  return [[self contents] canDisplayDataOfType: type];
}

- (void)showData:(NSData *)data 
          ofType:(NSString *)type
{
  [[self contents] showData: data ofType: type];
}

- (IBAction)activateInspector:(id)sender
{
  id insp = [inspectors objectAtIndex: [sender indexOfSelectedItem]];
  
	if (currentInspector != insp) {
    currentInspector = insp;
	  [win setTitle: [insp winname]];
	  [inspBox setContentView: [insp inspView]];	 
	}
  
//  if (currentPaths) {
//	  [insp activateForPaths: currentPaths];
//  }
}

- (void)showAttributes
{
  if ([win isVisible] == NO) {
    [self activate];
  }
  [popUp selectItemAtIndex: ATTRIBUTES];
  [self activateInspector: popUp];
}

- (id)attributes
{
  return [inspectors objectAtIndex: ATTRIBUTES];
}

- (NSWindow *)win
{
  return win;
}

- (void)updateDefaults
{
  NSNumber *index = [NSNumber numberWithInt: [popUp indexOfSelectedItem]];

  [[NSUserDefaults standardUserDefaults] setObject: index 
                                            forKey: @"last_active_inspector"];
  [[self attributes] updateDefaults];
  [win saveFrameUsingName: @"inspector"];
}

- (BOOL)windowShouldClose:(id)sender
{
  [win saveFrameUsingName: @"inspector"];
	return YES;
}

- (void)watcherNotification:(NSNotification *)notif
{
  NSDictionary *info = (NSDictionary *)[notif object];
  NSString *path = [info objectForKey: @"path"];
  
  if (watchedPath && [watchedPath isEqual: path]) {
    int i;

    for (i = 0; i < [inspectors count]; i++) {
      [[inspectors objectAtIndex: i] watchedPathDidChange: info];
    }
  }
}

@end


