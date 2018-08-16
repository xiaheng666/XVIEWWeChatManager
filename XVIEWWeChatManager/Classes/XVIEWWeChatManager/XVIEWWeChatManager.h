//
//  XVIEWWeChatManager.h
//  XVIEW2.0
//
//  Created by njxh on 16/11/26.
//  Copyright © 2016年 南京 夏恒. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "XVIEWSDKObject.h"

@interface XVIEWWeChatManager : NSObject
/*支持 WeChatSDK1.7.4版本
 SystemConfiguration.framework,
 libz.dylib,
 libsqlite3.0.dylib,
 libc++.dylib,
 Security.framework,
 CoreTelephony.framework,
 CFNetwork.framework。
 在工程配置中的”Other Linker Flags”中加入”-Objc -all_load”
 */

/**
 *  WeixinApiManager的单例类
 *
 *  @return 您可以通过此方法，获取WeixinApiManager的单例，访问对象中的属性和方法
 */
+ (instancetype)shareXVIEWWeChatManager;

+ (BOOL)isWXAppInstalled;

@end
