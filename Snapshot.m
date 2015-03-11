/* All Rights reserved */

#include <AppKit/AppKit.h>
#include "Snapshot.h"

@implementation Snapshot

- (id) init 
{
    self = [super init];
    if (self != nil) {
        // load the interface...
        if(![NSBundle loadNibNamed: @"Snapshot" owner: self]) {
            NSLog(@"Failed to load interface");
            exit(-1);
        }
    }
    return self;
}

- (BOOL) validateMenuItem: (id<NSMenuItem>)item
{
	return [[self delegate] validateMenuItem: item];
}

@end
