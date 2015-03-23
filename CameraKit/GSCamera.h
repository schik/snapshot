#ifndef _GSCAMERA_H_
#define _GSCAMERA_H_

#include <gphoto2.h>
#include <Foundation/Foundation.h>
#include <AppKit/AppKit.h>

@interface GSCamera: NSObject
{
  NSString *theName;
  NSString *thePort;
  Camera *theCamera;
}

- (id) initWithName: (NSString *) aName
	       Port: (NSString *) aPort
	     Camera: (Camera *) aCamera;
- (void) dealloc;
- (NSString *) name;
- (NSString *) port;
- (NSArray *) filesInPath: (NSString *) aPath;
- (NSArray *) foldersInPath: (NSString *) aPath;
- (void) getFile: (NSString *)aFile from: (NSString *)srcPath to: (NSString *)destPath;
- (void) deleteFile: (NSString *)file from: (NSString *)path;
- (void) putFile: (NSString *)file from: (NSString *)srcPath to: (NSString *)destPath;
- (NSString *) description;
- (NSImage *) thumbnailForFile: (NSString *)file inPath: (NSString *)path;
- (NSDictionary *) exifdataForFile: (NSString *)file inPath: (NSString *)path;
- (NSDictionary *)infoForFile: (NSString *)file inPath: (NSString *)path;


@end

#endif
