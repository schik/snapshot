/* Attributes.m
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

#include <math.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/stat.h>

#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import "Attributes.h"
#import "Inspector.h"

#define SINGLE 0
#define MULTIPLE 1

static NSString *nibName = @"Attributes";

@implementation Attributes

- (void)dealloc
{
  [nc removeObserver: self];  
  RELEASE (mainBox);

  [super dealloc];
}

- (id)initForInspector:(id)insp
{
  self = [super init];
  
  if (self) {
    NSBundle *bundle = [NSBundle bundleForClass: [insp class]];
    NSString *imagepath;

    if ([NSBundle loadNibNamed: nibName owner: self] == NO) {
      NSLog(@"failed to load %@!", nibName);
      DESTROY (self);
      return self;
    } 

    RETAIN (mainBox);
    RELEASE (win);

    inspector = insp;
    [iconView setInspector: inspector];

    nc = [NSNotificationCenter defaultCenter];
    
    /* Internationalization */
    [linkToLabel setStringValue: NSLocalizedString(@"Link to:", @"")];
    [sizeLabel setStringValue: NSLocalizedString(@"Size:", @"")];
    [calculateButt setTitle: NSLocalizedString(@"Calculate", @"")];
    [ownerLabel setStringValue: NSLocalizedString(@"Owner:", @"")];
    [groupLabel setStringValue: NSLocalizedString(@"Group:", @"")];
    [changedDateBox setTitle: NSLocalizedString(@"Changed", @"")];
    [permsBox setTitle: NSLocalizedString(@"Permissions", @"")];
    [readLabel setStringValue: NSLocalizedString(@"Read", @"")];
    [writeLabel setStringValue: NSLocalizedString(@"Write", @"")];
    [executeLabel setStringValue: NSLocalizedString(@"Execute", @"")];
    [uLabel setStringValue: NSLocalizedString(@"Owner", @"")];
    [gLabel setStringValue: NSLocalizedString(@"Group", @"")];
    [oLabel setStringValue: NSLocalizedString(@"Others", @"")];
    [insideButt setTitle: NSLocalizedString(@"also apply to files inside selection", @"")];
    [revertButt setTitle: NSLocalizedString(@"Revert", @"")];
    [okButt setTitle: NSLocalizedString(@"OK", @"")];
  } 
		
	return self;
}

- (NSView *)inspView
{
  return mainBox;
}

- (NSString *)winname
{
  return NSLocalizedString(@"Attributes Inspector", @"");
}

- (void)activateForPaths:(NSArray *)paths
{
  NSString *fpath;
  NSString *ftype;
  NSString *usr, *grp, *tmpusr, *tmpgrp;
  NSDate *date;
  NSCalendarDate *cdate;
  NSDictionary *attrs;
  unsigned long perms;
  BOOL sameOwner, sameGroup;
  int i;

  sizeStop = YES;

  if (paths == nil) {
    DESTROY (insppaths);
    return;
  }
  	
  attrs = [fm fileAttributesAtPath: [paths objectAtIndex: 0] traverseLink: NO];

  ASSIGN (insppaths, paths);
  pathscount = [insppaths count];	
  ASSIGN (currentPath, [paths objectAtIndex: 0]);		
  ASSIGN (attributes, attrs);	

  [revertButt setEnabled: NO];
  [okButt setEnabled: NO];
  	
  if (pathscount == 1)
    { /* Single Selection */

      FSNode *node = [FSNode nodeWithPath: currentPath];
      NSImage *icon = [[FSNodeRep sharedInstance] iconOfSize: ICNSIZE forNode: node];
      
      [iconView setImage: icon];
      [titleField setStringValue: [currentPath lastPathComponent]];
      
      usr = [attributes objectForKey: NSFileOwnerAccountName];
      grp = [attributes objectForKey: NSFileGroupOwnerAccountName];
      date = [attributes objectForKey: NSFileModificationDate];
      perms = [[attributes objectForKey: NSFilePosixPermissions] unsignedLongValue];			
      
#ifdef __WIN32__
      iamRoot = YES;
#else
      iamRoot = (geteuid() == 0);
#endif
      
      isMyFile = ([NSUserName() isEqual: usr]);
      
      [insideButt setState: NSOffState];
      
      ftype = [attributes objectForKey: NSFileType];
      if ([ftype isEqual: NSFileTypeDirectory] == NO)
        {	
          NSString *fsize = fsDescription([[attributes objectForKey: NSFileSize] unsignedLongLongValue]);
          [sizeField setStringValue: fsize]; 
          [calculateButt setEnabled: NO];
          [insideButt	setEnabled: NO];
        }
      else
        {
          [sizeField setStringValue: @"--"]; 
          
          if (autocalculate)
            {
              if (sizer == nil)
                [self startSizer];
              else
                [sizer computeSizeOfPaths: insppaths];
            }
          else
            {
              [calculateButt setEnabled: YES];
            }
          
          [insideButt	setEnabled: YES];
        }
      
                
      if ([ftype isEqual: NSFileTypeSymbolicLink])
        {
          NSString *s;

          s = [fm pathContentOfSymbolicLinkAtPath: currentPath];
          s = relativePathFit(linkToField, s);
          [linkToField setStringValue: s];
          [linkToLabel setTextColor: [NSColor blackColor]];		
          [linkToField setTextColor: [NSColor blackColor]];		      
        }
      else
        {
          [linkToField setStringValue: @""];
          [linkToLabel setTextColor: [NSColor darkGrayColor]];		
          [linkToField setTextColor: [NSColor darkGrayColor]];		
        }
      
      [ownerField setStringValue: usr]; 
      [groupField setStringValue: grp]; 
      
      [self setPermissions: perms isActive: (iamRoot || isMyFile)];
      
      cdate = [date dateWithCalendarFormat: nil timeZone: nil];	
      [timeDateView setDate: cdate];
      
    }
  else
    { /* Multiple Selection */
      NSImage *icon = [[FSNodeRep sharedInstance] multipleSelectionIconOfSize: ICNSIZE];
      NSString *items = NSLocalizedString(@"items", @"");
      
      items = [NSString stringWithFormat: @"%lu %@", (unsigned long)[paths count], items];
      [titleField setStringValue: items];  
      [iconView setImage: icon];
  
      [attributes objectForKey: NSFileType];
      
      [sizeField setStringValue: @"--"]; 
      
      if (autocalculate)
        {
          if (sizer == nil)
            [self startSizer];
          else
            [sizer computeSizeOfPaths: insppaths];
        }
      else
        {
          [calculateButt setEnabled: YES];
        }
    
      usr = [attributes objectForKey: NSFileOwnerAccountName];
      grp = [attributes objectForKey: NSFileGroupOwnerAccountName];
      date = [attributes objectForKey: NSFileModificationDate];		

      sameOwner = YES;
      sameGroup = YES;
		
      for (i = 0; i < [insppaths count]; i++)
        {
          fpath = [insppaths objectAtIndex: i];
          attrs = [fm fileAttributesAtPath: fpath traverseLink: NO];
          tmpusr = [attrs objectForKey: NSFileOwnerAccountName];
          if ([tmpusr isEqualToString: usr] == NO)
            sameOwner = NO;
          tmpgrp = [attrs objectForKey: NSFileGroupOwnerAccountName];
          if ([tmpgrp isEqualToString: grp] == NO)
            sameGroup = NO;
        }
      
      if(sameOwner == NO)
        usr = @"-";

      if(sameGroup == NO)
        grp = @"-";

      
#ifdef __WIN32__
      iamRoot = YES;
#else
      iamRoot = (geteuid() == 0);
#endif
                
      isMyFile = ([NSUserName() isEqualToString: usr]);	
				
      [linkToLabel setTextColor: [NSColor darkGrayColor]];		
      [linkToField setStringValue: @""];

      [ownerField setStringValue: usr]; 
      [groupField setStringValue: grp]; 
    
      [insideButt setEnabled: YES];
    
      [self setPermissions: 0 isActive: (iamRoot || isMyFile)];
		
      cdate = [date dateWithCalendarFormat: nil timeZone: nil];	
      [timeDateView setDate: cdate];
    }
	
  [mainBox setNeedsDisplay: YES];
}

- (void)watchedPathDidChange:(NSDictionary *)info
{
}

- (void)updateDefaults
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  [defaults setBool: autocalculate forKey: @"auto_calculate_sizes"];
}

@end
