//
//  CDVHotUpdate.h
//  codePushPlugin
//
//  Created by liangqiangkun on 2017/1/11.
//
//

#import <Cordova/CDVPlugin.h>
#import "ZipArchive.h"

@interface CDVHotUpdate : CDVPlugin <SSZipArchiveDelegate>
- (void)downLoadAndUpdateHTMLResouce:(CDVInvokedUrlCommand *)command;
@end
