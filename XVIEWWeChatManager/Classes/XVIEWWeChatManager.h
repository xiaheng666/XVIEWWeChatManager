//
//  XVIEWWeChatManager.h
//  XVIEWWeChatManager
//
//  Created by yyj on 2019/1/4.
//  Copyright © 2019 zd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface XVIEWWeChatManager : NSObject

/**
 *  单例
 */
+ (instancetype)sharedWeChatManager;

/**
 *  注册微信
 @param param    data    {appId  微信的appid}
 */
- (void)registerApp:(NSDictionary *)param;

/**
 *  是否安装微信
 @param param    callback:回调方法
 */
- (void)isInstallWechat:(NSDictionary *)param;

/**
 *  微信支付
 @param param     data:{appId:openid,partnerid:商户id,prepayid:预支付id,
                        package:包,noncestr:随机数,timestamp:时间戳,sign:签名}
                  callback:回调方法
 }
 */
- (void)wechatPay:(NSDictionary *)param;

/**
 *  微信登陆
 @param param    callback:回调方法
 }
 */
- (void)wechatLogin:(NSDictionary *)param;

/**
 *  微信分享
 @param param     data:{platform:分享的平台WEIXIN/WEIXIN_CIRCLE/WEIXIN_Favorite  好友/朋友圈/收藏,
                        shareData:分享类型,shareDataKey:分享类型的参数}
                  callback:回调方法
 }
 */
- (void)wechatShare:(NSDictionary *)param;

/**
 *  微信拉起小程序
 @param param     data:{userName:小程序名称,path:小程序打开路径,miniType:小程序类型  0/1/2 正式/测试/体验}
                  callback:回调方法
 */
- (void)wechatMiniProgram:(NSDictionary *)param;

/**
 *  微信返回回调
 @param param     data:{url:回调url}
                  callback:回调方法
 }
 */
- (BOOL)handleUrl:(NSDictionary *)param;

@end
