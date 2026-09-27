//
//  AppService.h
//  WildFireChat
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WFChatUIKitLava/WFChatUIKit.h>
#import <LavaWFChatClient/WFCChatClient.h>

NS_ASSUME_NONNULL_BEGIN

@interface AppService : NSObject <QWERAppServiceProvider, WFCCDefaultPortraitProvider>
+ (AppService *)sharedAppService;

- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;


/** 邮箱登录方式
 * type 0 密码登录   1 验证码登录
 * pswCode (type=0时)该字段为密码  否则为验证码
 */
- (void)loginWithEmail:(NSString *)email pswCode:(NSString *)pswCode type:(NSInteger)type success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)resetPassword:(NSString *)mobile code:(NSString *)code newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)changePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

//- (void)sendLoginCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
- (void)sendLoginCode:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;

- (void)sendResetCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
// 1127 忘记密码 发送验证码
- (void)sendForgetCode:(NSString *)mobile success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
// 1127 设置忘记密码
- (void)setForgetPsw:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

//发送删除账号验证码
- (void)sendDestroyAccountCode:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)destroyAccount:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcScaned:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcConfirmLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)pcCancelLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock;

- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock;

- (void)showPCSessionViewController:(UIViewController *)baseController pcClient:(WFCCPCOnlineInfo *)clientInfo;

- (NSData *)getAppServiceCookies;
- (NSString *)getAppServiceAuthToken;

//清除应用服务认证cookies和认证token
- (void)clearAppServiceAuthInfos;


#pragma mark - 通用接口  1206新增

- (void)requestUrl:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
- (void)requestUrlNoLogin:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;

// 0109新增
- (void)uploadFile:(NSString *)url
            images:(NSArray<UIImage *> *)images
           progress:(void(^)(int sentcount, int total))progressBlock
            success:(void(^)(NSString *url))successBlock
               error:(void(^)(NSString *errorMsg))errorBlock;

- (void)generateUploadFile:(NSString *)fileName
                   success:(void(^)(NSString *uploadUrl, NSString *requestUrl))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)uploadData:(NSData *)data
               url:(NSString *)url
         remoteUrl:(NSString *)remoteUrl
           success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
              fail:(void(^)(int errorCode))errorBlock;

#pragma mark - 埋点

- (void)eventReport:(NSDictionary *)param
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)eventBatchReport:(NSArray *)param
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock;

#pragma mark - 联系人标签

- (void)friendTagList:(void(^)(NSArray<WFCCUserTag *> *tags))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagRename:(NSDictionary *)param
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagMembersSet:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagMembersRemove:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagMembersList:(NSDictionary *)param
                     success:(void(^)(NSArray<WFCCUserInfo *> *friends))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagMembersAdd:(NSDictionary *)param
                    success:(void(^)(void))successBlock
                      error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagMembersAddMulti:(NSDictionary *)param
                         success:(void(^)(void))successBlock
                           error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagForFriend:(NSDictionary *)param
                   success:(void(^)(NSArray<WFCCUserTag *> *tags))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagDelete:(NSDictionary *)param
                success:(void(^)(void))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagDeleteBatch:(NSDictionary *)param
                     success:(void(^)(void))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)friendTagCreate:(NSDictionary *)param
                success:(void(^)(WFCCUserTag *tag))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)groupListQuery:(void(^)(NSArray<WFCCGroupInfo *> *groups))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock;

#pragma mark - 社区

- (void)communityArticlePublishPermission:(void(^)(BOOL canPublish))successBlock
                                    error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)communityArticleAuthors:(void(^)(NSArray<WFCCCommunityUser *> *members))successBlock
                          error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)communityArticleList:(NSDictionary *)param
                     success:(void(^)(WFCCCommunityList *list))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)communityArticleCreate:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)communityArticleUpdate:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)communityArticleDelete:(NSDictionary *)param
                       success:(void(^)(void))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)communityArticleDetail:(NSDictionary *)param
                       success:(void(^)(WFCCCommunity *articleDetail))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock;

#pragma mark - 签到

- (void)signSubmit:(NSDictionary *)param
           success:(void(^)(WFCCSign *sign))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)signResign:(NSDictionary *)param
           success:(void(^)(WFCCResign *resign))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)signTasks:(void(^)(WFCCSignTasks *tasks))successBlock
            error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)signHistory:(NSDictionary *)param
            success:(void(^)(WFCCSignHistory *history))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock;

- (void)pointsHistory:(NSDictionary *)param
              success:(void(^)(WFCCPointsHistory *history))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock;

#pragma mark - AI

- (void)aiUrl:(void(^)(NSString *url))successBlock
        error:(void(^)(int errCode, NSString *message))errorBlock;

#pragma mark - 安全锁相关接口

//// 设置设备锁状态(必须登录)
//- (void)lock_set_status:(BOOL)status success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
//// 获取设备锁状态
//- (void)lock_get_info:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock;
//// 修改设备锁数字密码
//- (void)lock_update_device_number:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
//// 修改设备锁数字密码根据手机短信
//- (void)lock_reset_device_number:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;
//// 发送设备锁验证码   什么都不需要发送我会根据登录的用户查找到注册的手机号
//- (void)send_reset_device_code:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock;



@end

NS_ASSUME_NONNULL_END
