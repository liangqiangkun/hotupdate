//
//  CDVHotUpdate.m
//  codePushPlugin
//
//  Created by liangqiangkun on 2017/1/11.
//
//

#import "CDVHotUpdate.h"
#import "AFNetworking.h"
#import "UIKit+AFNetworking.h"
#import "SSZipArchive.h"
#import <Cordova/CDV.h>
#import "MBProgressHUD.h"

@implementation CDVHotUpdate
{
    NSString *_externalStoragePath;//www资源保存的外部路径
    MBProgressHUD *_hud;
}

#pragma mark---cordova api
-(void)pluginInitialize{
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask,YES) objectAtIndex:0];
    _externalStoragePath = [documentPath stringByAppendingString:@"/update"];
    //首先判断app的启动状态是否为app版本升级后的第一次运行，如果是，则删除旧版本的外部存储资源
    if ([self isAppFirstRunAfterUpdate]) {
        NSError *error = nil;
        if ([[NSFileManager defaultManager] fileExistsAtPath:_externalStoragePath]) {
            [[NSFileManager defaultManager] removeItemAtPath:_externalStoragePath error:&error];
            if (error) {
                NSLog(@"旧版本app的外部存储资源删除失败");
                return;
            }
        }
    }
    //重定向app加载index页面的路径
    [self resetIndexPageToExternalStorage];
    NSFileManager * fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:_externalStoragePath]) {
        //此时外部沙盒中没有www资源
        //拷贝appbundle下的资源到沙盒
        NSString *wwwPath = [[NSBundle mainBundle] pathForResource:@"www" ofType:@""];
        NSLog(@"-------wwwPath----------%@",wwwPath);
        NSLog(@"-------_externalStoragePath----------%@",_externalStoragePath);
        if([self copyUISouceFrom:wwwPath toDesPath:_externalStoragePath]){
            //此时将www资源拷贝至沙盒成功
            NSLog(@"成功将www资源拷贝至沙盒路径");
        }
    }
    
}

- (void)downLoadAndUpdateHTMLResouce:(CDVInvokedUrlCommand *)command{
    //首先获取下载的路径
    NSString *downLoadURL = [command argumentAtIndex:0];
    if (!downLoadURL) {
        
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"参数有误，请检查url"];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
        return;
    }
    //拼接外部存储路径,存储zip资源
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,  NSUserDomainMask,YES) objectAtIndex:0];
    NSString *zipTempPath = [documentPath stringByAppendingString:@"/update/zipResource/www.zip"];
    //判断是否存在文件夹，如果不存在，创建文件夹
    if (![[NSFileManager defaultManager] fileExistsAtPath:[zipTempPath stringByDeletingLastPathComponent]]) {
        //此时文件夹不存在
        NSError *error = nil;
        [[NSFileManager defaultManager] createDirectoryAtPath:[zipTempPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:&error];
        if (!error) {
            //此时文件夹创建成功
            [self downLoadZipFromURL:downLoadURL toPath:zipTempPath command:command];
        }else{
            NSLog(@"zip资源文件夹创建失败！");
        }
    }else{
        //此时存在该文件夹，直接下载zip资源即可
        [self downLoadZipFromURL:downLoadURL toPath:zipTempPath command:command];
    }
}


#pragma mark---私有api
//下载zip
-(void)downLoadZipFromURL:(NSString *)urlString toPath:(NSString *)zipTempPath command:(CDVInvokedUrlCommand *)command{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    //创建AFN的manager对象
    AFHTTPSessionManager *manager = [[AFHTTPSessionManager alloc] initWithSessionConfiguration:configuration];
    //构造URL对象
    NSURL *url = [NSURL URLWithString:urlString];
    //构造request对象
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    NSURLSessionDownloadTask *task = [manager downloadTaskWithRequest:request progress:^(NSProgress * _Nonnull downloadProgress) {
        [self setProgressViewWithProgress:downloadProgress];
    } destination:^NSURL * _Nonnull(NSURL * _Nonnull targetPath, NSURLResponse * _Nonnull response) {
        return [NSURL fileURLWithPath:zipTempPath];
    } completionHandler:^(NSURLResponse * _Nonnull response, NSURL * _Nullable filePath, NSError * _Nullable error) {
        [_hud hideAnimated:YES];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!error)
            {
                //解压下载的zip资源
                if (![[NSFileManager defaultManager] fileExistsAtPath:[_externalStoragePath stringByAppendingString:@"/www/"]]) {
                    NSError *error = nil;
                    [[NSFileManager defaultManager] createDirectoryAtPath:[_externalStoragePath stringByAppendingString:@"/www/"] withIntermediateDirectories:YES attributes:nil error:&error];
                    if (error) {
                        //此时创建文件夹失败
                        NSLog(@"创建保存www资源的文件夹失败");
                        return ;
                    }
                }
                if([self unzipUISouce:zipTempPath toDestinationFilePath:[_externalStoragePath stringByAppendingString:@"/www/"]]){
                    //此时已经解压成功，重定向app'的index页面
                    [self.viewController viewDidLoad];
                }
            }
        });
    }];
    [task resume];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!_hud) {
            _hud = [MBProgressHUD showHUDAddedTo:self.viewController.view animated:YES];
            // Set the determinate mode to show task progress.
            _hud.mode = MBProgressHUDModeDeterminateHorizontalBar;
            _hud.label.text = @"正在下载...";
        }
    });
}
//拷贝appbundle下的资源到沙盒
-(BOOL)copyUISouceFrom:(NSString *)soucePath toDesPath:(NSString *)desPath{
    NSURL *localWWWUrl = [NSURL fileURLWithPath:soucePath];
    NSURL *externalWWWUrl = [NSURL fileURLWithPath:[desPath stringByAppendingString:@"/www"]];
    NSError *error = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isWWWFolderExists = [fileManager fileExistsAtPath:desPath];
    if (isWWWFolderExists) {
        [fileManager removeItemAtURL:[externalWWWUrl URLByDeletingLastPathComponent] error:&error];
    }
    if ([fileManager createDirectoryAtPath:desPath withIntermediateDirectories:YES attributes:nil error:&error]) {
        
        [fileManager copyItemAtURL:localWWWUrl toURL:externalWWWUrl error:&error];
        if (error) {
            NSLog(@"拷贝资源出错 %@",error.localizedDescription);
            return NO;
        } else {
            return YES;
        }
    }else{
        return NO;
    }
}
//解压zip资源
-(BOOL)unzipUISouce:(NSString *)zipFullPath toDestinationFilePath:(NSString *)destinationFilePath{
    NSError *error = nil;
    NSLog(@"destinationFilePath---%@",destinationFilePath);
    if([SSZipArchive unzipFileAtPath:zipFullPath toDestination:destinationFilePath overwrite:YES password:nil error:&error]){
        NSLog(@"解压成功");
        //删除原来的zip资源
        [[NSFileManager defaultManager] removeItemAtPath:zipFullPath error:nil];
        return YES;
    }else{
        NSLog(@"解压失败");
        return NO;
    }
}
-(void)resetIndexPageToExternalStorage{
    //首先判断外部资源存储是否真正存在
    if ([[NSFileManager defaultManager] fileExistsAtPath:_externalStoragePath]) {
        //拼接外部www资源的路径
        NSString *wwwURLStr = [[@"file://" stringByAppendingString:_externalStoragePath] stringByAppendingString:@"/www"];
        //此时存在，加载外部资源
        if ([self.viewController isKindOfClass:[CDVViewController class]]) {
            ((CDVViewController *)self.viewController).wwwFolderName = wwwURLStr;
        }
    }
}
//判断app是否为升级后的第一次启动
- (BOOL) isAppFirstRunAfterUpdate{
    NSString *currentVersion = [[[NSBundle mainBundle] infoDictionary]
                                objectForKey:@"CFBundleShortVersionString"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSString *lastRunKey = [defaults objectForKey:@"last_run_version_key"];
    if (!lastRunKey) {
        [defaults setObject:currentVersion forKey:@"last_run_version_key"];
        return NO;
        //上次运行版本为空，说明程序第一次运行
    }
    else if (![lastRunKey isEqualToString:currentVersion]) {
        [defaults setObject:currentVersion forKey:@"last_run_version_key"];
        return YES;
        //有版本号，但是和当前版本号不同，说明程序已经更新了版本
    }
    return NO;
}
//创建进度条
- (void)setProgressViewWithProgress:(NSProgress *)progress{
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD HUDForView:self.viewController.view].progress = progress.fractionCompleted;
    });
}
//判断当前网络状态
@end





























