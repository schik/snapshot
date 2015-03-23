#include "GSGPhoto2.h"

#include <gphoto2.h>

@implementation GSGPhoto2

- (id) init
{
  [super init];

  [self reinit];

  return self;
}


- (void) reinit
{
  NSAutoreleasePool *pool;

  GPContext *context;
  CameraList *list;
  CameraAbilitiesList *al = NULL;
  GPPortInfoList *il = NULL;
  int count, i;

  pool = [NSAutoreleasePool new];

  context = gp_context_new();
  gp_list_new (&list);
  gp_abilities_list_new (&al);
  gp_abilities_list_load (al, context);
  gp_port_info_list_new (&il);
  gp_port_info_list_load (il);

  gp_abilities_list_detect (al, il, list, context);

  gp_abilities_list_free (al);
  gp_port_info_list_free (il);

  count = gp_list_count (list);

  theCameraList = [[NSMutableArray alloc] init];

  for (i = 0; i < count; i++)
    {
      Camera *camera;
      const char *name;
      const char *value;
      CameraAbilitiesList *abilities_list = NULL;
      CameraAbilities a;
      GPPortInfo info;
      GSCamera *cam;

      int m, p;

      gp_list_get_name  (list, i, &name);
      gp_list_get_value (list, i, &value);

      gp_camera_new(&camera);

      gp_abilities_list_new (&abilities_list);
      gp_abilities_list_load (abilities_list, context);
      gp_port_info_list_new (&il);
      gp_port_info_list_load (il);

      m = gp_abilities_list_lookup_model(abilities_list, name);
      gp_abilities_list_get_abilities (abilities_list, m, &a);
      gp_camera_set_abilities (camera, a);

      p = gp_port_info_list_lookup_path (il, value);
      gp_port_info_list_get_info (il, p, &info);
      gp_camera_set_port_info (camera, info);

      gp_setting_set ("campics", "model", (char *)name);
      gp_setting_set ("campics", "port", (char *)value);

      gp_port_info_list_free(il);

      cam = [[GSCamera alloc] initWithName: [NSString stringWithCString: name]
			      Port: [NSString stringWithCString: value]
			      Camera: camera];

      [theCameraList addObject: cam];
            
      RELEASE(cam);

//      free(name);
//      free(value);
    }

  RELEASE(pool);
}


- (void) dealloc
{
  RELEASE(theCameraList);
  [super dealloc];
}


- (unsigned) numberOfCameras
{
  return [theCameraList count];
}


- (NSString *) nameOfCameraAtIndex: (int) anIndex
{
  GSCamera *cam;
  cam = [theCameraList objectAtIndex: anIndex];
  return [cam name];
}


- (int) indexOfCameraNamed: (NSString *) aName
{
  return -1;
}


- (GSCamera *) cameraAtIndex: (int) anIndex
{
  return [theCameraList objectAtIndex: anIndex];
}

@end
