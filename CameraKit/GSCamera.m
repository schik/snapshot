#include "GSCamera.h"

@implementation GSCamera

- (id) initWithName: (NSString *) aName
	       Port: (NSString *) aPort
	     Camera: (Camera *) aCamera
{
  [super init];

  theName = [[NSString alloc] initWithString: aName];
  thePort = [[NSString alloc] initWithString: aPort];
  theCamera = aCamera;

  return self;
}


- (void) dealloc
{
  RELEASE(theName);
  RELEASE(thePort);
  if (theCamera != NULL) {
    gp_camera_exit(theCamera, NULL);
    free(theCamera);
  }
  [super dealloc];
}


- (NSString *) name
{
  return theName;
}


- (NSString *) port
{
  return thePort;
}


- (NSArray *) filesInPath: (NSString *) aPath
{
  CameraList *list;
  GPContext *context;
  int i, count;
  NSMutableArray *ar = [[NSMutableArray alloc] init];

  context = gp_context_new();
  gp_list_new(&list);
  gp_camera_folder_list_files(theCamera, [aPath cString], list, context);
  
  count = gp_list_count (list);
  
  for (i=0; i<count; i++)
    {
      const char *cname;
      NSString *name;
      gp_list_get_name  (list, i, &cname);
      name = [[NSString alloc] initWithCString: cname];
      [ar addObject: name];
      RELEASE(name);
    }

  gp_list_free(list);
  free(context);

  return ar;
}


- (NSArray *) foldersInPath: (NSString *) aPath
{
  CameraList *list;
  GPContext *context;
  int i, count;
  NSMutableArray *ar = [[NSMutableArray alloc] init];

  context = gp_context_new();
  gp_list_new(&list);
  gp_camera_folder_list_folders(theCamera, [aPath cString], list, context);
  
  count = gp_list_count (list);
  for (i=0; i<count; i++)
    {
      const char *cname;
      NSString *name;
      gp_list_get_name  (list, i, &cname);
      name = [[NSString alloc] initWithCString: cname];
      [ar addObject: name];
      RELEASE(name);
    }

  gp_list_free(list);
  free(context);

  return ar;
}

- (void) getFile: (NSString *)aFile from: (NSString *)srcPath to: (NSString *)destPath
{
  CameraFile *file;
  GPContext *context;
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  context = gp_context_new();
  gp_file_new(&file);

  gp_camera_file_get(theCamera, [srcPath cString], [aFile cString],
		     GP_FILE_TYPE_NORMAL, file, context);
  gp_file_save(file, [[NSString stringWithFormat: @"%@/%@", destPath, aFile] cString]);

  gp_file_unref(file);

  RELEASE(pool);
}


- (void) deleteFile: (NSString *)file from: (NSString *)path
{
  GPContext *context;
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  context = gp_context_new();

  gp_camera_file_delete(theCamera, [path cString], [file cString], context);

  RELEASE(pool);
}


- (void) putFile: (NSString *)file from: (NSString *)srcPath to: (NSString *)destPath
{

}


- (NSString *) description
{
  return [self name];
}

- (NSImage *) thumbnailForFile: (NSString *)file inPath: (NSString *)path
{
  NSImage *image = nil;
  CameraFile *cfile;
  gp_file_new(&cfile);
  int result = gp_camera_file_get (theCamera, [path cString],
                  [file cString], GP_FILE_TYPE_PREVIEW, cfile, NULL);
  if (result >= 0) {
      const char *fd;
      unsigned long fs;

      gp_file_get_data_and_size (cfile, &fd, &fs);

      NSData *data = [NSData dataWithBytes: fd length: fs];
      image = [[NSImage alloc] initWithData: data];
  } 
	
  gp_file_unref (cfile);
  return image;
}

- (NSDictionary *) infoForFile: (NSString *)file inPath: (NSString *)path
{
  NSMutableDictionary *dict = [[NSMutableDictionary new] autorelease];
  CameraFileInfo info;
  int result = gp_camera_file_get_info (theCamera, [path cString],
                  [file cString], &info, NULL);
  if (result >= 0) {
      if (info.file.fields & GP_FILE_INFO_SIZE) {
	  [dict setObject: [NSNumber numberWithInteger: info.file.size] forKey: @"size"];
      }
      if (info.file.fields & GP_FILE_INFO_WIDTH) {
	  [dict setObject: [NSNumber numberWithInteger: info.file.width] forKey: @"width"];
      }
      if (info.file.fields & GP_FILE_INFO_HEIGHT) {
	  [dict setObject: [NSNumber numberWithInteger: info.file.height] forKey: @"height"];
      }
      if (info.file.fields & GP_FILE_INFO_MTIME) {
	  [dict setObject: [NSDate dateWithTimeIntervalSince1970: info.file.mtime] forKey: @"mtime"];
      }
  } 
	
  return [[NSDictionary alloc] initWithDictionary: dict];
}

@end
