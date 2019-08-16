#include <exif-data.h>

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
    [self getFile: aFile from: srcPath toFile: nil at: destPath];
}

- (void) getFile: (NSString *)aFile from: (NSString *)srcPath toFile: (NSString *)newFile at: (NSString *)destPath
{
  CameraFile *file;
  GPContext *context;
  NSAutoreleasePool *pool = [NSAutoreleasePool new];

  if ((nil == newFile) || ([newFile length] == 0)) {
      newFile = aFile;
  }

  context = gp_context_new();
  gp_file_new(&file);

  gp_camera_file_get(theCamera, [srcPath cString], [aFile cString],
		     GP_FILE_TYPE_NORMAL, file, context);
  gp_file_save(file, [[NSString stringWithFormat: @"%@/%@", destPath, newFile] cString]);

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
  return [image autorelease];
}

- (NSString *) getStringValue: (ExifEntry *) ee
{
    char v[1024];
    exif_entry_get_value(ee, v, sizeof(v));
    NSString *value = [NSString stringWithFormat: @"%s", v];
    return value;
}

- (NSDictionary *) exifdataForFile: (NSString *)file inPath: (NSString *)path
{
  NSMutableDictionary *dict = [[NSMutableDictionary new] autorelease];
  CameraFile *cfile;
  gp_file_new(&cfile);
  int result = gp_camera_file_get (theCamera, [path cString],
                  [file cString], GP_FILE_TYPE_EXIF, cfile, NULL);

  if (result >= 0) {
    const char *data;
    unsigned long size;
    gp_file_get_data_and_size(cfile, &data, &size);
    ExifData *edata = exif_data_new_from_data((const unsigned char *)data, size);
    unsigned int i;
    unsigned int j;

    if (edata) {
	  for (i = 0; i < EXIF_IFD_COUNT; i++) {
        if (edata->ifd[i]) {
          for (j = 0; j < edata->ifd[i]->count; j++) {
            ExifEntry *ee = edata->ifd[i]->entries[j];

			NSString *name = [NSString stringWithFormat: @"%s",
                exif_tag_get_name_in_ifd(ee->tag, exif_entry_get_ifd(ee))];

	        NSString *value = [self getStringValue: ee];
	        [dict setObject: value forKey: name];
		  }
        }
	  }
      exif_data_free(edata);
    }
  }	
  gp_file_unref(cfile);
  return [[NSDictionary alloc] initWithDictionary: dict];
}

- (NSDictionary *) infoForFile: (NSString *)file inPath: (NSString *)path
{
  NSMutableDictionary *dict = [[NSMutableDictionary new] autorelease];
  [dict setDictionary: [self exifdataForFile: file inPath: path]];

  CameraFileInfo info;
  int result = gp_camera_file_get_info (theCamera, [path cString],
                  [file cString], &info, NULL);
  if (result >= 0) {
    if (info.file.fields & GP_FILE_INFO_SIZE) {
      [dict setObject: [NSNumber numberWithInteger: info.file.size] forKey: @"FileSize"];
    }
    if (info.file.fields & GP_FILE_INFO_MTIME) {
      [dict setObject: [NSDate dateWithTimeIntervalSince1970: info.file.mtime] forKey: @"Mtime"];
    }
    if (info.file.fields & GP_FILE_INFO_TYPE) {
      [dict setObject: [NSString stringWithCString: info.file.type] forKey: @"MimeType"];
    }
  } 

  CameraFile *cfile;

  gp_file_new(&cfile);
  result = gp_camera_file_get (theCamera, [path cString],
                  [file cString], GP_FILE_TYPE_EXIF, cfile, NULL);
  if (result >= 0) {
    const char *data;
    unsigned long size;
    gp_file_get_data_and_size(cfile, &data, &size);
  
    ExifData *edata = exif_data_new_from_data((const unsigned char *)data, size);
    if (edata) {
      ExifByteOrder byteOrder = exif_data_get_byte_order(edata);
      ExifEntry *ee = exif_data_get_entry(edata, EXIF_TAG_ORIENTATION);
	  if (ee) {
        int orientation = exif_get_short(ee->data, byteOrder);
        [dict setObject: [NSNumber numberWithInt: orientation] forKey: @"OrientationNum"];
	  }
      ee = exif_data_get_entry(edata, EXIF_TAG_DATE_TIME);
      if (!ee) {
        ee = exif_data_get_entry(edata, EXIF_TAG_DATE_TIME_ORIGINAL);
	  } 
	  if (ee) {
        NSDateFormatter *df = [[NSDateFormatter new] autorelease];
        [df setDateFormat: @"yyyy:MM:dd HH:mm:ss"];
        [dict setObject: [df dateFromString: [self getStringValue: ee]] forKey: @"Mtime"];
      }
      exif_data_free(edata);
    }
  }
  gp_file_unref(cfile);
  return [[NSDictionary alloc] initWithDictionary: dict];
}

@end
