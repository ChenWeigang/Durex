//
//  VPUtil.h
//  ThirdParty
//
//  Created by Chen Weigang on 12-3-12.
//  Copyright (c) 2012年 Fugu Mobile Limited. All rights reserved.
//

#import <Foundation/Foundation.h>

// file managerment
NSString*       filePathAtDocument(NSString *filename);
NSString*       filePathAtMainBundle(NSString *filename);
NSURL*          fileURL(NSString *path);
bool            isFileExistAtPath(NSString *filePath);

// simple read & write plist file
NSArray*        arrayFromMainBundle(NSString *fileName);
NSDictionary*   dictionaryFromMainBundle(NSString *fileName);

NSArray*        loadArrayFromDocument(NSString *filename);
NSDictionary*   loadDictionaryFromDocument(NSString *filename);
BOOL            saveArrayToDocument(NSString *filename, NSArray *array);
BOOL            saveDictionaryToDocument(NSString *filename, NSDictionary *dictionary);

// encoding
NSString*       encodeURL(NSString *string);
NSString*       stringUsingEncodingUTF8(NSData *data);
NSString*       stringUsingEncoding(NSData *data, NSStringEncoding encoding);
NSData*         dataUsingEncodingUTF8(NSString *string);
NSData*         dataUsingEncoding(NSString *string, NSStringEncoding encoding);


// device
NSString*       deviceName(void);
NSString*       deviceModel(void);
NSString*       deviceSystemName(void);
NSString*       deviceSystemVersion(void);
double          systemVersion(void);
bool            isRetinaDisplay(void);
void            deviceInfo(void);
bool            isIPad(void);


// regular expressions
bool            isEmailFormat(NSString *email);
bool            isCountryCodeFormat(NSString *countryCode);
bool            isMobileFormat(NSString *mobile);
bool            isAccountFormat(NSString *account);
bool            isPasswordFormat(NSString *password);
bool            isFirstLetterNumber(NSString *number);

// open URL
void openURL(NSURL *url);
void openRateURL(NSString *appId);
void openTelURL(NSString *tel);


// others
void            showAlertBox(NSString *title, NSString *message);
NSString*       currTime(void);
void            localNotification(void);


// NSCoder
bool            archive(id object, NSString *path);
id              unarchive(NSString *path);

// camera
//#define DEVICE_CAMERA
//#ifdef DEVICE_CAMERA
//#import <MobileCoreServices/MobileCoreServices.h>
//bool            isCaptureAvailable(void);
//bool            isVideoRecordingAvailable(void);
//#endif

void addNotification(id observer, SEL sel, NSString *name, id obj);
void removeNotification(id observer, NSString *name, id obj);
void postNotification(NSString *name);

NSString* base64forData(NSData *theData);


void saveLog(NSString *log);

