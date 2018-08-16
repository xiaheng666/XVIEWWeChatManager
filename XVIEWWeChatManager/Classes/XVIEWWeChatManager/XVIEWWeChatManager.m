//
//  XVIEWWeChatManager.m
//  XVIEW2.0
//
//  Created by njxh on 16/11/26.
//  Copyright © 2016年 南京 夏恒. All rights reserved.
//

#import "XVIEWWeChatManager.h"
#import "WXApi.h"
#import "WXApiObject.h"
static NSString *kAuthScope = @"snsapi_userinfo";
static NSString *kAuthState = @"123";
@interface XVIEWWeChatManager () <WXApiDelegate>
@property (nonatomic, copy) void (^weixinCallbackBlock) (XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData);  //回调的状态码， 返回的数a据
@property (nonatomic, strong) NSString *appId;      //微信的AppID
@property (nonatomic, strong) NSString *appSecret;  //微信的密钥

@end

@implementation XVIEWWeChatManager {
    XVIEWSDKPlatfromType _type;
}
#pragma mark ==XVIEW微信单例类
+ (instancetype)shareXVIEWWeChatManager {
    static XVIEWWeChatManager *_instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[XVIEWWeChatManager alloc] init];
    });
    return _instance;
}
+ (BOOL)isWXAppInstalled {
    return [WXApi isWXAppInstalled];
}
- (instancetype)init {
    if (self = [super init]) {
        
    }
    return self;
}

#pragma mark ==微信结果的回调==
- (BOOL)XVIEWWeChatSDKCallbackUrl:(NSURL *)url {
    return [WXApi handleOpenURL:url delegate:self];
}
#pragma mrk ==微信注册应用的appid和appsecret
- (void)registerXViewWeChatAppId:(NSString *)appId
                   withAppSecret:(NSString *)appSecret {
    self.appId = appId;
    self.appSecret = appSecret;
    [WXApi registerApp:self.appId];
}
- (void)registerXViewWeChatAppSecret:(NSString *)appSecret {
    if (![appSecret isEqualToString:self.appSecret]) {
        self.appSecret = appSecret;
    }
}
#pragma mark ==微信分享、支付、登录
- (void)XVIEWSDKWeChatParameters:(NSDictionary *)parameters contentType:(XVIEWSDKPlatfromType)type callback:(void (^)(XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData))callbackBlock {
    self.weixinCallbackBlock = callbackBlock;
    if (![WXApi isWXAppInstalled]) {
        if (self.weixinCallbackBlock) {
            self.weixinCallbackBlock(XVIEWSDKCodeNULLWeChat, @{@"code":@"-1", @"data":@{@"result":@"没有安装微信客户端"}, @"message":@"没有安装微信客户端"});
        }
        return ;
    }
    if (type == XVIEWSDKTypeWeChatLogin) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self weixinLogin];
        });
    } else if (type == XVIEWSDKTypeWeChatPay) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self XVIEWWeChatPayParametersWithNoncestr:parameters[@"noncestr"] package:parameters[@"package"] partnerid:parameters[@"partnerid"] prepayid:parameters[@"prepayid"] sign:parameters[@"sign"] timestamp:parameters[@"timestamp"]];
        });
    }else if (type == XVIEWSDKTypeWeChatMiniProgram){
        dispatch_async(dispatch_get_main_queue(), ^{
            [self weixinToMiniproGram:parameters  type:type];
        });
    } else if (type == XVIEWSDKTypeWeChatShareFriend || type == XVIEWSDKTypeWeChatShareCircle || type == XVIEWSDKTypeWeChatShareFav || type == XVIEWSDKTypeWeChatMiniProgramShare) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self shareWithParameters:parameters type:type];
        });
    }
}
- (void)weixinToMiniproGram:(NSDictionary *)parameters type:(XVIEWSDKPlatfromType)type {
    WXLaunchMiniProgramReq *req = [WXLaunchMiniProgramReq object];
    req.userName = parameters[@"userName"];  //拉起的小程序的username
    if (parameters[@"path"]){
        req.path = parameters[@"path"];
    }
    switch ([parameters[@"miniProgramType"] intValue]) {
        case 0:
            req.miniProgramType = WXMiniProgramTypeRelease;
            break;
        case 1:
            req.miniProgramType = WXMiniProgramTypeTest;
            break;
        case 2:
            req.miniProgramType = WXMiniProgramTypePreview;
            break;
        default:
            break;
    }
    [WXApi sendReq:req];
}
- (void)shareWithParameters:(NSDictionary *)parameters type:(XVIEWSDKPlatfromType)type {
    _type = type;
    NSLog(@"parameters=======%@",parameters);
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    if (type == XVIEWSDKTypeWeChatShareFriend) {      //分享网页给微信好友
        req.scene = WXSceneSession;
    }
    else if (type == XVIEWSDKTypeWeChatShareCircle) { //分享网页给微信朋友圈
        req.scene = WXSceneTimeline;
    }
    else if (type == XVIEWSDKTypeWeChatShareFav) {    //分享网页给微信收藏
        req.scene = WXSceneFavorite;
    } else if (type == XVIEWSDKTypeWeChatMiniProgramShare){
        req.scene = WXSceneSession; //只支持会话
    }
    if ([parameters[@"sharetype"] isEqualToString:@"text"]) {
        req.text = parameters[@"text"];
        req.bText = YES;
    } else if ([parameters[@"sharetype"] isEqualToString:@"image"]) {
        WXMediaMessage *message = [WXMediaMessage message];
        [message setThumbImage:[UIImage imageWithData:parameters[@"thumburl"]]];
        
        WXImageObject *image = [WXImageObject object];
        image.imageData = parameters[@"imageurl"];
        message.mediaObject = image;
        
        req.bText = NO;
        req.message = message;
        NSLog(@"message=====%@",message);
    } else {
        WXMediaMessage *message = [WXMediaMessage message];
        message.title = parameters[@"title"];
        message.description = parameters[@"description"];
        if (parameters[@"thumburl"]){
            [message setThumbImage:[UIImage imageWithData:parameters[@"thumburl"]]];
        }
        req.bText = NO;
        req.message = message;
        if ([parameters[@"sharetype"] isEqualToString:@"web"]) {
            WXWebpageObject *webObject = [WXWebpageObject object];
            webObject.webpageUrl = parameters[@"shareurl"];
            
            message.mediaObject = webObject;
        } else if ([parameters[@"sharetype"] isEqualToString:@"audio"]) {
            WXMusicObject *audio = [WXMusicObject object];
            audio.musicUrl = parameters[@"shareurl"];
            audio.musicLowBandUrl = audio.musicUrl;
            audio.musicDataUrl = parameters[@"fileurl"];
            audio.musicLowBandDataUrl = audio.musicDataUrl;
            message.mediaObject = audio;
        } else if ([parameters[@"sharetype"] isEqualToString:@"video"]) {
            WXVideoObject *video = [WXVideoObject object];
            video.videoUrl = parameters[@"shareurl"];
            video.videoLowBandUrl = video.videoUrl;//低分辨率的视频url
            message.mediaObject = video;
        } else if (parameters[@"userName"]){
            WXMiniProgramObject *miniObjc = [[WXMiniProgramObject alloc]init];
            miniObjc.webpageUrl = parameters[@"webpageUrl"];
            miniObjc.userName = parameters[@"userName"];
            miniObjc.path = parameters[@"path"];
            miniObjc.hdImageData = parameters[@"thumbBmp"];//小程序节点高清大图，小于128K
            message.mediaObject = miniObjc;
            message.thumbData = nil;//兼容旧版本节点的图片，小于32K，新版本优先使用WXMiniProgramObject的hdImageData属性
        }
    }
    [WXApi sendReq:req];
}


/**
 *  设置微信支付参数
 *  @param noncestr         随机字符串,不长于32位
 *  @param package          扩展字段,暂填写固定值Sign=WXPay
 *  @param partnerid        商户号
 *  @param prepayid         预支付交易会话ID
 *  @param sign             签名
 *  @param timestamp        时间戳
 */
- (void)XVIEWWeChatPayParametersWithNoncestr:(NSString *)noncestr
                                     package:(NSString *)package
                                   partnerid:(NSString *)partnerid
                                    prepayid:(NSString *)prepayid
                                        sign:(NSString *)sign
                                   timestamp:(NSString *)timestamp {
    PayReq *req   = [[PayReq alloc] init];
    req.openID    = _appId;
    req.partnerId = partnerid;
    req.prepayId  = prepayid;
    req.package   = package;
    req.nonceStr  = noncestr;
    req.timeStamp = [timestamp intValue];
    req.sign      = sign;
    [WXApi sendReq:req];
}


#pragma mark - WXApiDelegate的代理
- (void)onResp:(BaseResp *)resp {
    //微信分享-发送消息
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        SendMessageToWXResp *resp1 = (SendMessageToWXResp *)resp;
        //分享成功
        if (resp1.errCode == WXSuccess) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeSuccess,  @{@"code":@"0", @"data":@{@"result":@"微信分享成功", @"type":_type ==  XVIEWSDKTypeWeChatShareFriend ? @"weixinShare" : @"weixinCircleShare"}, @"message":@"微信分享成功"});
            }
            return ;
        } else if(resp1.errCode == WXErrCodeUserCancel) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeCancel,  @{@"code":@"-1", @"data":@{@"result":@"用户点击取消并返回", @"type":_type ==  XVIEWSDKTypeWeChatShareFriend ? @"weixinShare" : @"weixinCircleShare"}, @"message":@"用户点击取消并返回"});
            }
            return ;
        } else {
            NSString *result;
            if(resp1.errCode == WXErrCodeSentFail) result = @"微信分享发送失败";
            else if(resp1.errCode == WXErrCodeAuthDeny) result = @"微信分享授权失败";
            else if(resp1.errCode == WXErrCodeUnsupport) result = @"微信不支持";
            else result = @"未知错误";
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeFail,  @{@"code":@"-1", @"data":@{@"result":result, @"type":_type ==  XVIEWSDKTypeWeChatShareFriend ? @"weixinShare" : @"weixinCircleShare"}, @"message":@"微信操作失败"});
            }
        }
    }
    //微信登陆
    else if ([resp isKindOfClass:[SendAuthResp class]]) {
        SendAuthResp *rep = (SendAuthResp *)resp;
        if (rep.errCode == WXSuccess) {
            [self weixinLoginSuccess:@{@"code":rep.code}];
        }
        else if(rep.errCode == -2) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeCancel, @{@"code":@"-1", @"data":@{@"result":@"用户取消登录", @"type":@"weixinLogin"}, @"message":@"微信登录失败"});
            }
        }
        else {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeCancel, @{@"code":@"-1", @"data":@{@"result":@"微信登录失败", @"type":@"weixinLogin"}, @"message":@"微信登录失败"});
            }
        }
    }
    //微信支付
    else if([resp isKindOfClass:[PayResp class]]){
        PayResp*response=(PayResp*)resp;  // 微信终端返回给第三方的关于支付结果的结构体
        if (response.errCode == WXSuccess) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeSuccess, @{@"code":@"0", @"data":@{@"result":@"微信支付成功", @"type":@"weixinPay"}, @"message":@"微信支付成功"});
            }
        }
        else if(response.errCode == -2) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeCancel,  @{@"code":@"-1", @"data":@{@"result":@"用户取消支付", @"type":@"weixinPay"}, @"message":@"微信支付失败"});
            }
        }
        else {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeFail,  @{@"code":@"-1", @"data":@{@"result":@"微信支付失败", @"type":@"weixinPay"}, @"message":@"微信支付失败"});
            }
        }
    }
    //小程序跳转回调
    if ([resp isKindOfClass:[WXLaunchMiniProgramResp class]]){
        WXLaunchMiniProgramResp*response=(WXLaunchMiniProgramResp*)resp;  // 小程序返回值
        if (response.errCode == WXSuccess){
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeSuccess, @{@"code":@"0", @"data":@{@"result":@"跳转成功", @"type":@"startMiniProgram",@"data":response.extMsg}, @"message":@"跳转成功"});
            }
        }
        else if(response.errCode == -2) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeCancel,  @{@"code":@"-1", @"data":@{@"result":@"用户取消跳转", @"type":@"startMiniProgram"}, @"message":@"用户取消跳转"});
            }
        }
        else {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeFail,  @{@"code":@"-1", @"data":@{@"result":@"跳转失败", @"type":@"startMiniProgram"}, @"message":@"跳转失败"});
            }
        }
    }
}

#pragma mark ==微信登陆成功之后回调信息==
- (void)weixinLoginSuccess:(NSDictionary *)dict {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code", self.appId, self.appSecret, dict[@"code"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeFail,  @{@"code":@"-1", @"data":@{@"result":error.localizedDescription, @"type":@"weixinLogin"}, @"message":@"微信登录失败"});
            }
            return ;
        }
        NSError *myerror;
        NSDictionary *mydict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&myerror];
        if (myerror) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeFail,  @{@"code":@"-1", @"data":@{@"result":myerror.localizedDescription, @"type":@"weixinLogin"}, @"message":@"微信登录失败"});
            }
            return ;
        }
        else {
            [self saveTokenAndRequireWXInfo:mydict];
        }
    }];
    [task resume];
}
- (void)saveTokenAndRequireWXInfo:(NSDictionary *)dict {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?openid=%@&access_token=%@", dict[@"openid"], dict[@"access_token"]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSessionTask *task = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeFail,  @{@"code":@"-1", @"data":@{@"result":error.localizedDescription, @"type":@"weixinLogin"}, @"message":@"微信登录失败"});
            }
            return ;
        }
        NSError *myerror;
        NSDictionary *mydict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&myerror];
        if (myerror) {
            if (self.weixinCallbackBlock) {
                self.weixinCallbackBlock(XVIEWSDKCodeFail,  @{@"code":@"-1", @"data":@{@"result":myerror.localizedDescription, @"type":@"weixinLogin"}, @"message":@"微信登录失败"});
            }
            return ;
        }
        else {
            if (self.weixinCallbackBlock) {
                NSDictionary *callbackDict = @{@"type":@"weixinLogin",
                                               @"openid":dict[@"openid"],
                                               @"unionid":mydict[@"unionid"],
                                               @"nickname":mydict[@"nickname"],
                                               @"headimgurl":mydict[@"headimgurl"],
                                               @"sex":[[NSString stringWithFormat:@"%@", mydict[@"sex"]] isEqual:@"1"] ? @"1" : @"0",
                                               @"access_token":dict[@"access_token"],
                                               @"refresh_token":dict[@"refresh_token"]};
                self.weixinCallbackBlock(XVIEWSDKCodeSuccess,  @{@"code":@"0", @"data":callbackDict, @"message":@"微信登录成功"});
            }
        }
    }];
    [task resume];
}




#pragma mark ================== 未使用该方法 ========================
/**
 *  设置微信分享参数
 *
 *  @param text         文本
 *  @param title        标题
 *  @param url          分享链接
 *  @param thumbImage   缩略图，可以为UIImage、NSString（图片路径）、NSURL（图片路径）
 *  @param image        图片，可以为UIImage、NSString（图片路径）、NSURL（图片路径）
 *  @param contentType  分享类型，支持XVIEWContentTypeText、XVIEWContentTypeImage、XVIEWContentTypeWebPage
 *  分享文本时：
 *  设置type为XVIEWContentTypeText, 并填入text参数
 *
 *  分享图片时：
 *  设置type为XVIEWContentTypeImage, 填入title和image参数
 *
 *  分享网页时：
 *  设置type为XVIEWContentTypeWebPage, 并设置text、title、url以及thumbImage参数
 
 - (void)XVIEWWeChatShareParametersWithText:(NSString *)text
 title:(NSString *)title
 url:(NSString *)url
 thumbImage:(UIImage *)thumbImage
 image:(id)image
 contentType:(XVIEWSDKPlatfromType)contentType {
 [self shareWebPageWithTitle:title withDescription:text withThumbImage:thumbImage withUrl:url withType:contentType];
 }
 */



#pragma mark =====旧的微信类实现方法=====
- (void)registerAppKey:(NSString *)appKey weixinType:(XVIEWSDKPlatfromType)type withParameter:(NSDictionary *)infoData callback:(void (^)(XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData))callbackBlock
{
    self.weixinCallbackBlock = callbackBlock;
    
    [self weixinType:type withParameter:infoData];
}
- (void)weixinType:(XVIEWSDKPlatfromType)type withParameter:(NSDictionary *)dict
{
    self.appId = dict[@"wxappid"];
    [WXApi registerApp:self.appId];
    //    [WXApi registerApp:self.appId withDescription:@"weixin"];  //老版sdk,已废弃
    if (![WXApi isWXAppInstalled]) {
        if (self.weixinCallbackBlock) {
            self.weixinCallbackBlock(XVIEWSDKCodeNULLWeChat, @{@"result":@"没有安装微信客户端"});
        }
        return;
    }
    if (type == XVIEWSDKTypeWeChatPay) {
        [self wxPay:dict];
    }
    else if (type == XVIEWSDKTypeWeChatLogin) {
        self.appSecret = dict[@"wxappsecret"];
        [self weixinLogin];
    }
    else if (type == XVIEWSDKTypeWeChatShareFriend) {
        [self shareToWeiXin:dict type:0];
    }
    else if (type == XVIEWSDKTypeWeChatShareCircle) {
        [self shareToWeiXin:dict type:1];
    }
    else if (type == XVIEWSDKTypeWeChatShareFav) {
        [self shareToWeiXin:dict type:2];
    }
    else {
        return;
    }
}
#pragma mark ==微信支付==
- (void)wxPay:(NSDictionary*)dict
{
    PayReq *req = [[PayReq alloc] init];
    req.partnerId = dict[@"partnerid"];
    req.openID = dict[@"wxappid"];
    req.prepayId= dict[@"prepayid"];
    req.package = dict[@"package"];
    req.nonceStr= dict[@"noncestr"];
    req.timeStamp= [dict[@"timestamp"] intValue];
    req.sign = dict[@"sign"];
    [WXApi sendReq:req];
}
#pragma mark ==微信登录==
- (BOOL)weixinLogin
{
    if ([WXApi isWXAppInstalled]) {
        SendAuthReq *req = [[SendAuthReq alloc] init];
        req.scope = kAuthScope;
        req.state = kAuthState;
        [WXApi sendReq:req];
        return YES;
    }
    else {
        return NO;
    }
}
#pragma mark ==分享到微信 num=0分享到好友，num=1分享到朋友圈==
- (void)shareToWeiXin:(NSDictionary *)dict type:(NSInteger)num
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = dict[@"title"];//@"测试把web分享到微信好友";
    message.description = dict[@"descrption"];
    [message setThumbImage:[UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:dict[@"picture"]]]]];
    
    WXWebpageObject *webObject = [WXWebpageObject object];
    webObject.webpageUrl = dict[@"url"];
    message.mediaObject = webObject;
    
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    if (num == 0) {
        //分享网页给微信好友
        req.scene = WXSceneSession;
    }
    else if (num == 1) {
        //分享网页给微信朋友圈
        req.scene = WXSceneTimeline;
    }
    else if (num == 2) {
        //分享网页给微信朋友圈
        req.scene = WXSceneFavorite;
    }
    [WXApi sendReq:req];
}

@end
///**
// *  微信结果的回调，用于AppDelegate里面设置回调以及代理
// *
// *  @param url AppDelegate的方法中的url
// */
//- (BOOL)XVIEWWeChatSDKCallbackUrl:(NSURL *)url;
//
///**
// *  设置微信(微信好友，微信朋友圈、微信收藏)应用信息
// *
// *  @param appId       应用标识
// *  @param appSecret   应用密钥
// */
//- (void)registerXViewWeChatAppId:(NSString *)appId
//withAppSecret:(NSString *)appSecret;
//
//- (void)XVIEWSDKWeChatParameters:(NSDictionary *)parameters contentType:(XVIEWSDKPlatfromType)type callback:(void (^)(XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData))callbackBlock;
//
///**
// *  设置微信登录参数
// */
//- (void)XVIEWWeChatLogin;
//
///**
// *  设置微信分享参数
// *
// *  @param text         文本
// *  @param title        标题
// *  @param url          分享链接
// *  @param thumbImage   缩略图，可以为UIImage-大小不能超过32k
// *  @param image        图片，可以为UIImage、NSString（图片路径） -大小不能超过10M
// *  @param contentType  分享类型，支持XVIEWContentTypeText、XVIEWContentTypeImage、XVIEWContentTypeWebPage
// *  分享文本时：
// *  设置type为XVIEWContentTypeText, 并填入text参数
// *
// *  分享图片时：
// *  设置type为XVIEWContentTypeImage, 填入title和image参数
// *
// *  分享网页时：
// *  设置type为XVIEWContentTypeWebPage, 并设置title、url以及thumbImage参数
// */
//- (void)XVIEWWeChatShareParametersWithText:(NSString *)text
//title:(NSString *)title
//url:(NSString *)url
//thumbImage:(UIImage *)thumbImage
//image:(id)image
//contentType:(XVIEWSDKPlatfromType)contentType;
//
///**
// *  设置微信支付参数
// *
// *  @param noncestr         随机字符串,不长于32位
// *  @param package          扩展字段,暂填写固定值Sign=WXPay
// *  @param partnerid        商户号
// *  @param prepayid         预支付交易会话ID
// *  @param sign             签名
// *  @param timestamp        时间戳
// */
//- (void)XVIEWWeChatPayParametersWithNoncestr:(NSString *)noncestr
//package:(NSString *)package
//partnerid:(NSString *)partnerid
//prepayid:(NSString *)prepayid
//sign:(NSString *)sign
//timestamp:(NSString *)timestamp;
///**
// *  调用微信支付、微信登陆、微信分享
// *  @param appKey        XVIEW注册的AppKey
// *  @param type          类型（支付、登录、分享(仅支持分享网页)）
// *  @param infoData      数据（支付的数据或者分享的数据）
// 支付时参infoData: @{"wxappid":"微信Appid","noncestr":"随机字符串","package":"","partnerid":"Sign=WXPay","partnerid":"商户号""prepayid":"预支付交易会话ID","sign":"签名","timestamp":"时间戳"}
// 登录时参数infoData:@{@"wxappid":@"微信appId", @"wxappsecret":@"微信appSecret"}
// 分享时参数infoData:@{@"title":@"", @"descrption":@"", @"picture":@"", @"url":@"", @"wxappid":@"wx59d5d49c9d5f47df"}
// *  @param callbackBlock 回调（支付、登陆、分享完成之后的回调）
// */
//- (void)registerAppKey:(NSString *)appKey weixinType:(XVIEWSDKPlatfromType)type withParameter:(NSDictionary *)infoData callback:(void (^)(XVIEWSDKResonseStatusCode statusCode, NSDictionary *responseData))callbackBlock;
