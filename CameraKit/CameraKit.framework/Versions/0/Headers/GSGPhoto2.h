#ifndef _GSPHOTO2_H_
#define _GSPHOTO2_H_

#include <Foundation/Foundation.h>

#include "GSCamera.h"

@interface GSGPhoto2: NSObject
{
  id theCameraList;
}

- (id) init;
- (void) reinit;
- (void) dealloc;
- (unsigned) numberOfCameras;
- (NSString *) nameOfCameraAtIndex: (int) anIndex;
- (int) indexOfCameraNamed: (NSString *) aName;
- (GSCamera *) cameraAtIndex: (int) anIndex;

@end

#endif
