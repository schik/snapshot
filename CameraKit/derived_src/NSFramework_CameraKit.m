#include <Foundation/NSString.h>
@interface NSFramework_CameraKit : NSObject
+ (NSString *)frameworkEnv;
+ (NSString *)frameworkPath;
+ (NSString *)frameworkVersion;
+ (NSString *const*)frameworkClasses;
@end
@implementation NSFramework_CameraKit
+ (NSString *)frameworkEnv { return nil; }
+ (NSString *)frameworkPath { return @"/usr/local/lib/GNUstep/Frameworks"; }
+ (NSString *)frameworkVersion { return @"0"; }
static NSString *allClasses[] = {@"GSGPhoto2", @"GSCamera", NULL};
+ (NSString *const*)frameworkClasses { return allClasses; }
@end
