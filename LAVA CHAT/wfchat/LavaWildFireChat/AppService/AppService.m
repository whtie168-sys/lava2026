//
//  AppService.m
//  WildFireChat
//
//  Created by Heavyrain Lee on 2019/10/22.
//  Copyright © 2019 WildFireChat. All rights reserved.
//

#import "AppService.h"
#import <LavaWFChatClient/WFCChatClient.h>
#import "AFNetworking.h"
#import "WFCConfig.h"
#import "PCSessionViewController.h"
#import <WFChatUIKitLava/WFChatUIKit.h>
#import "SharePredefine.h"
#import <WebKit/WebKit.h>
#import "ProxyManager.h"
#import "KeyChainTool.h"
#import "MJExtension.h"

static AppService *sharedSingleton = nil;

#define WFC_APPSERVER_COOKIES @"WFC_APPSERVER_COOKIES"
#define WFC_APPSERVER_AUTH_TOKEN  @"WFC_APPSERVER_AUTH_TOKEN"

#define AUTHORIZATION_HEADER @"authToken"

static NSString *WFCJSONStringFromObject(id object) {
    if (!object || ![NSJSONSerialization isValidJSONObject:object]) {
        return @"";
    }
    NSData *data = [NSJSONSerialization dataWithJSONObject:object options:0 error:nil];
    return data.length ? [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] : @"";
}

@implementation AppService 
+ (AppService *)sharedAppService {
    if (sharedSingleton == nil) {
        @synchronized (self) {
            if (sharedSingleton == nil) {
                sharedSingleton = [[AppService alloc] init];
            }
        }
    }

    return sharedSingleton;
}

- (void)loginWithMobile:(NSString *)mobile verifyCode:(NSString *)verifyCode area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    int platform = Platform_iOS;
    //如果使用pad端类型，这里平台改成pad类型，另外app_callback.mm文件中把平台也改成ipad，请搜索"iPad"
    //if(当前设备是iPad)
    //platform = Platform_iPad
    WS(weakself)
    NSDictionary *params = @{@"mobile":mobile, @"code":verifyCode, @"area":area, @"clientId":[[WFCCNetworkService sharedInstance] getClientId], @"platform":@(platform), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name};
    [self post:@"/login" data:params isLogin:YES success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            [weakself respone:dict success:^(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode) {
                if (successBlock) successBlock(userId, token, newUser, resetCode);
            }];
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
- (void)respone:(NSDictionary *)dict success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock {
    NSString *userId = dict[@"result"][@"userId"];
    NSString *token = dict[@"result"][@"token"];
    BOOL newUser = [dict[@"result"][@"register"] boolValue];
    NSString *resetCode = dict[@"result"][@"resetCode"];
    
    NSString *hasPassword = dict[@"result"][@"hasPassword"];
    [[NSUserDefaults standardUserDefaults] setInteger:hasPassword.integerValue forKey:@"kHasPassword"];
    [[NSUserDefaults standardUserDefaults] setObject:userId forKey:@"savedUserId"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    NSInteger deviceLockStatus = [dict[@"result"][@"deviceLockStatus"] integerValue];
    [LockStatusManager.main reWriteLockInfo:@(deviceLockStatus) ForKey:@"status"];
    
    if (successBlock) successBlock(userId, token, newUser, resetCode);
}
- (void)loginWithMobile:(NSString *)mobile password:(NSString *)password area:(NSString *)area success:(void(^)(NSString *userId, NSString *token, BOOL newUser))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    int platform = Platform_iOS;
    //如果使用pad端类型，这里平台改成pad类型，另外app_callback.mm文件中把平台也改成ipad，请搜索"iPad"
    //if(当前设备是iPad)
    //platform = Platform_iPad
    WS(weakself)
    NSDictionary *params = @{@"mobile":mobile, @"password":password, @"area":area, @"clientId":[[WFCCNetworkService sharedInstance] getClientId],
                             @"platform":@(platform), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name};
    [self post:@"/login_pwd" data:params isLogin:YES success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            [weakself respone:dict success:^(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode) {
                if (successBlock) successBlock(userId, token, newUser);
            }];
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
/** 邮箱登录方式
 * type 0 密码登录   1 验证码登录
 * pswCode (type=0时)该字段为密码  否则为验证码
 */
- (void)loginWithEmail:(NSString *)email pswCode:(NSString *)pswCode type:(NSInteger)type success:(void(^)(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    WS(weakself)
    NSString *url = @"";
    NSDictionary *params = nil;
    if (type == 0) {
        url = @"/login_email_pwd";
        params = @{@"email":email, @"password":pswCode, @"clientId":WFCCNetworkService.sharedInstance.getClientId, @"platform":@(Platform_iOS), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name};
    }else {
        url = @"/login_email";
        params = @{@"email":email, @"code":pswCode, @"clientId":WFCCNetworkService.sharedInstance.getClientId, @"platform":@(Platform_iOS), @"deviceUId":[KeyChainTool readData:kUUIDStringValue], @"deviceType":UIDevice.currentDevice.name};
    }
    [self post:url data:params isLogin:YES success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            [weakself respone:dict success:^(NSString *userId, NSString *token, BOOL newUser, NSString *resetCode) {
                if (successBlock) successBlock(userId, token, newUser, resetCode);
            }];
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

// 1121
- (void)addAudioHistory:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/add_audio_history" data:params isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
- (void)queryAudioHistory:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/query_audio_history" data:params isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock(dict);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
- (void)deleteAudioHistory:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/delete_audio_history" data:params isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock(dict);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}
- (void)deleteMessage:(NSDictionary *)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/delete_message" data:params isLogin:YES success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock(dict);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)resetPassword:(NSString *)mobile code:(NSString *)code newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    NSDictionary *data;
    if (mobile.length) {
        data = @{@"mobile":mobile, @"resetCode":code, @"newPassword":newPassword};
    } else {
        data = @{@"resetCode":code, @"newPassword":newPassword};
    }
    [self post:@"/reset_pwd" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)changePassword:(NSString *)oldPassword newPassword:(NSString *)newPassword success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/change_pwd" data:@{@"oldPassword":oldPassword, @"newPassword":newPassword} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)sendLoginCode:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    [self post:@"/send_code" data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock(errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}

- (void)sendResetCode:(NSString *)phoneNumber success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    NSDictionary *data = @{};
    if (phoneNumber.length) {
        data = @{@"mobile":phoneNumber};
    }
    [self post:@"/send_reset_code" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock(errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}
- (void)sendForgetCode:(NSString *)mobile success:(void(^)(void))successBlock error:(void(^)(NSString *message))errorBlock {
    NSDictionary *data = @{};
    if (mobile.length) {
        data = @{@"mobile":mobile};
    }
    [self post:@"/send_forgot_password_code" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock(errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(error.localizedDescription);
    }];
}
- (void)setForgetPsw:(NSDictionary *)params success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/reset_forgot_password_pwd" data:params isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.description);
    }];
}

- (void)sendDestroyAccountCode:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/send_destroy_code" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)destroyAccount:(NSDictionary *)data success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/destroy" data:data isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
            if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pcScaned:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = [NSString stringWithFormat:@"/scan_pc/%@", sessionId];
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"Lỗi mạng";
            if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pcConfirmLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/confirm_pc";
    NSDictionary *param = @{@"token":sessionId, @"user_id":[WFCCNetworkService sharedInstance].userId, @"quick_login":@(1)};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"Lỗi mạng";
            if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pcCancelLogin:(NSString *)sessionId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSString *path = @"/cancel_pc";
    NSDictionary *param = @{@"token":sessionId};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"Lỗi mạng";
            if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getGroupAnnouncement:(NSString *)groupId
                     success:(void(^)(TREWQGroupAnnouncement *))successBlock
                      error:(void(^)(int error_code))errorBlock {
    if (successBlock) {
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
    
        TREWQGroupAnnouncement *an = [[TREWQGroupAnnouncement alloc] init];
        an.data = data;
        an.groupId = groupId;
        
        successBlock(an);
    }
    
    NSDictionary *param = @{@"groupId":groupId};
    [self post:@"/get_group_announcement" data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0 || [dict[@"code"] intValue] == 12) {
            TREWQGroupAnnouncement *an = [[TREWQGroupAnnouncement alloc] init];
            an.groupId = groupId;
            if ([dict[@"code"] intValue] == 0) {
                an.author = dict[@"result"][@"author"];
                an.text = dict[@"result"][@"text"];
                an.timestamp = [dict[@"result"][@"timestamp"] longValue];
            }
            
            [[NSUserDefaults standardUserDefaults] setValue:an.data forKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if(successBlock) successBlock(an);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)updateGroup:(NSString *)groupId announcement:(NSString *)announcement isNoti:(NSInteger)isNoti
            success:(void(^)(long timestamp))successBlock
              error:(void(^)(int error_code))errorBlock {
    
    NSDictionary *param = @{@"groupId":groupId, @"author":[WFCCNetworkService sharedInstance].userId, @"text":announcement, @"isNoti":@(isNoti)};
    [self post:@"/put_group_announcement" data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            TREWQGroupAnnouncement *an = [[TREWQGroupAnnouncement alloc] init];
            an.groupId = groupId;
            an.author = [WFCCNetworkService sharedInstance].userId;
            an.text = announcement;
            an.timestamp = [dict[@"result"][@"timestamp"] longValue];
            
            
            [[NSUserDefaults standardUserDefaults] setValue:an.data forKey:[NSString stringWithFormat:@"wfc_group_an_%@", groupId]];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            if(successBlock) successBlock(an.timestamp);
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)getGroupMembersForPortrait:(NSString *)groupId
                           success:(void(^)(NSArray<NSDictionary<NSString *, NSString *> *> *groupMembers))successBlock
                             error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/group/members_for_portrait";
    [self post:path data:@{@"groupId":groupId} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if([dict[@"result"] isKindOfClass:NSArray.class]) {
                NSArray *arr = (NSArray *)dict[@"result"];
                if(successBlock) successBlock(arr);
            }
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)post:(NSString *)path data:(id)data isLogin:(BOOL)isLogin success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSError * _Nonnull error))errorBlock {
#if TARGET_IPHONE_SIMULATOR//模拟器
    
#elif TARGET_OS_IPHONE//真机
//    Class pClassObj = NSClassFromString(@"ProxyManager");
//    NSString *proxy = objc_msgSend([pClassObj new], @selector(getProxyStatus));
    NSString *proxy = [ProxyManager.main getProxyStatus];
    if (proxy.length > 0 || proxy != nil) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"网络异常，请检查是否开启代理" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:cancelAction];
        [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }
#endif
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
    NSString *authToken = [self getAppServiceAuthToken];
    if(authToken.length) {
        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
    } else {
        NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
        if ([cookiesdata length]) {
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
            NSHTTPCookie *cookie;
            for (cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
        }
    }
    NSString *url = [NSString stringWithFormat:@"%@%@",APP_SERVER_ADDRESS, path];
//    NSString *url = [APP_SERVER_ADDRESS stringByAppendingPathComponent:path];
    NSLog(@"url==%@\ndata==%@",url, data);
    [manager POST:url
       parameters:data
         progress:nil
          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if (isLogin) { //鉴权信息
                NSString *appToken;
                if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                    NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                    appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
                }

                if (authToken.length) {
                    [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
                } else {
                    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                    [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
                }
            }
        
            NSDictionary *dict = responseObject;
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"responseObject==%@",responseObject),
              successBlock(dict);
            });
          }
          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
                // DNS 失败时用固定 IP 重试
                if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorDNSLookupFailed || error.code == NSURLErrorBadURL) {
                    NSLog(@"DNS 解析失败，使用固定IP重试");
                    
                    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                    manager.requestSerializer = [AFJSONRequestSerializer serializer];
                    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
                    
                    //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
                    NSString *authToken = [self getAppServiceAuthToken];
                    if(authToken.length) {
                        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
                    } else {
                        NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
                        if ([cookiesdata length]) {
                            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
                            NSHTTPCookie *cookie;
                            for (cookie in cookies) {
                                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                            }
                        }
                    }
                    NSString *url = [NSString stringWithFormat:@"%@%@",@"http://54.254.43.61", path];
                    NSLog(@"使用固定IP重试 url==%@\ndata==%@",url, data);
                    [manager POST:url
                       parameters:data
                         progress:nil
                          success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                            if (isLogin) { //鉴权信息
                                NSString *appToken;
                                if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                                    NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                                    appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
                                }

                                if (authToken.length) {
                                    [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
                                } else {
                                    NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                                    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                                    [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
                                }
                            }
                        
                            NSDictionary *dict = responseObject;
                            dispatch_async(dispatch_get_main_queue(), ^{
                                NSLog(@"responseObject==%@",responseObject),
                              successBlock(dict);
                            });
                          }
                          failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                                dispatch_async(dispatch_get_main_queue(), ^{
                                    NSLog(@"error==%@",error),
                                    errorBlock(error);
                                });

                          }];
                    
                } else {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSLog(@"error==%@",error),
                        errorBlock(error);
                    });
                }
        

          }];
}
- (void)get:(NSString *)path data:(id)data isLogin:(BOOL)isLogin success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(NSError * _Nonnull error))errorBlock {
#if TARGET_IPHONE_SIMULATOR//模拟器
    
#elif TARGET_OS_IPHONE//真机
//    Class pClassObj = NSClassFromString(@"ProxyManager");
//    NSString *proxy = objc_msgSend([pClassObj new], @selector(getProxyStatus));
    NSString *proxy = [ProxyManager.main getProxyStatus];
    if (proxy.length > 0 || proxy != nil) {
        
        NSLog(@"检测到了网络代理，可进行额外操作");
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle:@"网络异常，请检查是否开启代理" message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:LLLLLL(@"AlertButton") style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        [alertController addAction:cancelAction];
        [UIApplication.sharedApplication.delegate.window.rootViewController presentViewController:alertController animated:YES completion:nil];
        return;
    }
#endif
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    manager.requestSerializer = [AFJSONRequestSerializer serializer];
    manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
    
    //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
    NSString *authToken = [self getAppServiceAuthToken];
    if(authToken.length) {
        [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
    } else {
        NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
        if([cookiesdata length]) {
            NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
            NSHTTPCookie *cookie;
            for (cookie in cookies) {
                [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
            }
        }
    }
    NSString *url = [NSString stringWithFormat:@"%@%@",APP_SERVER_ADDRESS, path];
//    NSString *url = [APP_SERVER_ADDRESS stringByAppendingPathComponent:path];
    NSLog(@"%@\n%@",url, data);
    
    [manager GET:url parameters:data progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        if(isLogin) { //鉴权信息
            NSString *appToken;
            if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
            }

            if(appToken.length) {
                [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
            } else {
                NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
            }
        }
    
        NSDictionary *dict = responseObject;
        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"responseObject==%@",responseObject),
          successBlock(dict);
        });
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        
        // DNS 失败时用固定 IP 重试
        if (error.code == NSURLErrorCannotFindHost || error.code == NSURLErrorDNSLookupFailed || error.code == NSURLErrorBadURL) {
            NSLog(@"DNS 解析失败，使用固定IP重试");
            
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.requestSerializer = [AFJSONRequestSerializer serializer];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
            
            //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
            NSString *authToken = [self getAppServiceAuthToken];
            if(authToken.length) {
                [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
            } else {
                NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
                if([cookiesdata length]) {
                    NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
                    NSHTTPCookie *cookie;
                    for (cookie in cookies) {
                        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                    }
                }
            }
            
            NSString *url = [NSString stringWithFormat:@"%@%@",@"http://54.254.43.61", path];
            NSLog(@"使用固定IP重试 url==%@\ndata==%@",url, data);
            [manager GET:url parameters:data progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if(isLogin) { //鉴权信息
                    NSString *appToken;
                    if ([task.response isKindOfClass:[NSHTTPURLResponse class]]) {
                        NSHTTPURLResponse *r = (NSHTTPURLResponse *)task.response;
                        appToken = [r allHeaderFields][AUTHORIZATION_HEADER];
                    }

                    if(appToken.length) {
                        [[NSUserDefaults standardUserDefaults] setObject:appToken forKey:WFC_APPSERVER_AUTH_TOKEN];
                    } else {
                        NSArray *cookies = [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookiesForURL: [NSURL URLWithString:APP_SERVER_ADDRESS]];
                        NSData *data = [NSKeyedArchiver archivedDataWithRootObject:cookies];
                        [[NSUserDefaults standardUserDefaults] setObject:data forKey:WFC_APPSERVER_COOKIES];
                    }
                }
            
                NSDictionary *dict = responseObject;
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"responseObject==%@",responseObject),
                  successBlock(dict);
                });
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSLog(@"error==%@",error),
                    errorBlock(error);
                });
            }];

        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                NSLog(@"error==%@",error),
                errorBlock(error);
            });
        }

    }];
}
- (void)uploadLogs:(void(^)(void))successBlock error:(void(^)(NSString *errorMsg))errorBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        NSMutableArray<NSString *> *logFiles = [[WFCCNetworkService getLogFilesPath]  mutableCopy];
        
        NSMutableArray *uploadedFiles = [[[[NSUserDefaults standardUserDefaults] objectForKey:@"mars_uploaded_files"] sortedArrayUsingComparator:^NSComparisonResult(NSString *obj1, NSString *obj2) {
            return [obj1 compare:obj2];
        }] mutableCopy];
        
        //日志文件列表需要删除掉已上传记录，避免重复上传。
        //但需要上传最后一条已经上传日志，因为那个日志文件可能在上传之后继续写入了，所以需要继续上传
        if (uploadedFiles.count) {
            [uploadedFiles removeLastObject];
        } else {
            uploadedFiles = [[NSMutableArray alloc] init];
        }
        for (NSString *file in [logFiles copy]) {
            NSString *name = [file componentsSeparatedByString:@"/"].lastObject;
            if ([uploadedFiles containsObject:name]) {
                [logFiles removeObject:file];
            }
        }
        
        
        __block NSString *errorMsg = nil;
        
        for (NSString *logFile in logFiles) {
            AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
            manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
            
            NSString *url = [APP_SERVER_ADDRESS stringByAppendingFormat:@"/logs/%@/upload", [WFCCNetworkService sharedInstance].userId];
            
             dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            
            __block BOOL success = NO;

            [manager POST:url parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
                NSData *logData = [NSData dataWithContentsOfFile:logFile];
                if (!logData.length) {
                    logData = [@"empty" dataUsingEncoding:NSUTF8StringEncoding];
                }
                
                NSString *fileName = [[NSURL URLWithString:logFile] lastPathComponent];
                [formData appendPartWithFileData:logData name:@"file" fileName:fileName mimeType:@"application/octet-stream"];
            } progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
                if ([responseObject isKindOfClass:[NSDictionary class]]) {
                    NSDictionary *dict = (NSDictionary *)responseObject;
                    if([dict[@"code"] intValue] == 0) {
                        NSLog(@"上传成功");
                        success = YES;
                        NSString *name = [logFile componentsSeparatedByString:@"/"].lastObject;
                        [uploadedFiles removeObject:name];
                        [uploadedFiles addObject:name];
                        [[NSUserDefaults standardUserDefaults] setObject:uploadedFiles forKey:@"mars_uploaded_files"];
                        [[NSUserDefaults standardUserDefaults] synchronize];
                    }
                }
                if (!success) {
                    errorMsg = @"Lỗi phản hồi máy chủ";
                }
                dispatch_semaphore_signal(sema);
            } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                NSLog(@"上传失败：%@", error);
                dispatch_semaphore_signal(sema);
                errorMsg = error.localizedFailureReason;
            }];
            
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
            
            if (!success) {
                errorBlock(errorMsg);
                return;
            }
        }
        
        successBlock();
    });
    
}


- (void)getMyPrivateConferenceId:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/get_my_id" data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSString *conferenceId = dict[@"result"];
            successBlock(conferenceId);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)createConference:(RADCOConferenceInfo *)conferenceInfo success:(void(^)(NSString *conferenceId))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/create" data:[conferenceInfo toDictionary] isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSString *conferenceId = dict[@"result"];
            conferenceInfo.conferenceId = conferenceId;
            successBlock(conferenceId);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)updateConference:(RADCOConferenceInfo *)conferenceInfo success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/put_info" data:[conferenceInfo toDictionary] isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)recordConference:(NSString *)conferenceId record:(BOOL)record success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/recording/%@", conferenceId] data:@{@"recording":@(record)} isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)focusConference:(NSString *)conferenceId userId:(NSString *)focusUserId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/focus/%@", conferenceId] data:@{@"userId":(focusUserId?focusUserId:@"")} isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)queryConferenceInfo:(NSString *)conferenceId password:(NSString *)password success:(void(^)(RADCOConferenceInfo *conferenceInfo))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    NSDictionary *data;
    if(password.length) {
        data = @{@"conferenceId":conferenceId, @"password":password};
    } else {
        data = @{@"conferenceId":conferenceId};
    }
    
    [self post:@"/conference/info" data:data isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            RADCOConferenceInfo *info = [RADCOConferenceInfo fromDictionary:dict[@"result"]];
            successBlock(info);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)destroyConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/destroy/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kCONFERENCE_DESTROYED object:nil];
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)favConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/fav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)unfavConference:(NSString *)conferenceId success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/unfav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock();
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)isFavConference:(NSString *)conferenceId success:(void(^)(BOOL isFav))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:[NSString stringWithFormat:@"/conference/is_fav/%@", conferenceId] data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            successBlock(YES);
        } else if(code == 16) {
            successBlock(NO);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)getFavConferences:(void(^)(NSArray<RADCOConferenceInfo *> *))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/conference/fav_conferences" data:nil isLogin:NO success:^(NSDictionary *dict) {
        int code = [dict[@"code"] intValue];
        if(code == 0) {
            NSArray<NSDictionary *> *ls = dict[@"result"];
            NSMutableArray *output = [[NSMutableArray alloc] init];
            [ls enumerateObjectsUsingBlock:^(NSDictionary * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [output addObject:[RADCOConferenceInfo fromDictionary:obj]];
            }];
            successBlock(output);
        } else {
            errorBlock(code, dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        errorBlock(-1, error.localizedDescription);
    }];
}

- (void)changeName:(NSString *)newName success:(void(^)(void))successBlock error:(void(^)(int errorCode, NSString *message))errorBlock {
    [self post:@"/change_name" data:@{@"newName":newName} isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            NSString *errmsg;
            if ([dict[@"code"] intValue] == 17) {
                errmsg = @"用户名已经存在";
            } else {
                errmsg = @"网络错误";
            }
            if(errorBlock) errorBlock([dict[@"code"] intValue], errmsg);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)showPCSessionViewController:(UIViewController *)baseController pcClient:(WFCCPCOnlineInfo *)clientInfo {
    PCSessionViewController *vc = [[PCSessionViewController alloc] init];
    vc.pcClientInfo = clientInfo;
    vc.hidesBottomBarWhenPushed = YES;
    [baseController.navigationController pushViewController:vc animated:YES];
}

- (void)getFavoriteItems:(int )startId
                   count:(int)count
                 success:(void(^)(NSArray<QWERFavoriteItem *> *items, BOOL hasMore))successBlock
                   error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/fav/list";
    NSDictionary *param = @{@"id":@(startId), @"count":@(count)};
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            BOOL hasMore = [result[@"hasMore"] boolValue];
            NSArray<NSDictionary *> *arrs = (NSArray *)result[@"items"];
            NSMutableArray<QWERFavoriteItem *> *output = [[NSMutableArray alloc] init];
            for (NSDictionary *d in arrs) {
                QWERFavoriteItem *item = [[QWERFavoriteItem alloc] init];
                item.conversation = [WFCCConversation conversationWithType:[d[@"convType"] intValue] target:d[@"convTarget"] line:[d[@"convLine"] intValue]];
                item.favId = [d[@"id"] intValue];
                if(![d[@"messageUid"] isEqual:[NSNull null]])
                    item.messageUid = [d[@"messageUid"] longLongValue];
                item.timestamp = [d[@"timestamp"] longLongValue];
                item.url = d[@"url"];
                item.favType = [d[@"type"] intValue];
                item.title = d[@"title"];
                item.data = d[@"data"];
                item.origin = d[@"origin"];
                item.thumbUrl = d[@"thumbUrl"];
                item.sender = d[@"sender"];
                
                [output addObject:item];
            }
            if(successBlock) successBlock(output, hasMore);
        } else {
            errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)addFavoriteItem:(QWERFavoriteItem *)item
                success:(void(^)(void))successBlock
                  error:(void(^)(int error_code))errorBlock {
    NSString *path = @"/fav/add";
    NSDictionary *param = @{@"type":@(item.favType),
                            @"messageUid":@(item.messageUid),
                            @"convType":@(item.conversation.type),
                            @"convLine":@(item.conversation.line),
                            @"convTarget":item.conversation.target?item.conversation.target:@"",
                            @"origin":item.origin?item.origin:@"",
                            @"sender":item.sender?item.sender:@"",
                            @"title":item.title?item.title:@"",
                            @"url":item.url?item.url:@"",
                            @"thumbUrl":item.thumbUrl?item.thumbUrl:@"",
                            @"data":item.data?item.data:@""
    };
    
    [self post:path data:param isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (void)removeFavoriteItem:(int)favId
                   success:(void(^)(void))successBlock
                     error:(void(^)(int error_code))errorBlock {
    NSString *path = [NSString stringWithFormat:@"/fav/del/%d", favId];
    
    [self post:path data:nil isLogin:NO success:^(NSDictionary *dict) {
        if([dict[@"code"] intValue] == 0) {
            if(successBlock) successBlock();
        } else {
            if(errorBlock) errorBlock([dict[@"code"] intValue]);
        }
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1);
    }];
}

- (NSString *)userDefaultPortrait:(WFCCUserInfo *)userInfo {
    if(userInfo.portrait.length) {
        return userInfo.portrait;
    } else {
        return @"";
//        return [APP_SERVER_ADDRESS stringByAppendingFormat:@"/avatar?name=%@", userInfo.displayName];
    }
}

- (NSString *)groupDefaultPortrait:(WFCCGroupInfo *)groupInfo memberInfos:(NSArray<WFCCUserInfo *> *)memberInfos {
    if(groupInfo.portrait.length) {
        return groupInfo.portrait;
    }
    
    NSMutableArray *reqMembers = [[NSMutableArray alloc] init];
    [memberInfos enumerateObjectsUsingBlock:^(WFCCUserInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(obj.portrait.length && [obj.portrait rangeOfString:APP_SERVER_ADDRESS].location == NSNotFound) {
            [reqMembers addObject:@{@"avatarUrl" : obj.portrait}];
        } else {
            [reqMembers addObject:@{@"name" : obj.displayName}];
        }
    }];
    NSDictionary *request = @{@"members" : reqMembers};
    NSError * err;
    NSData * jsonData = [NSJSONSerialization  dataWithJSONObject:request options:0 error:&err];
    return [APP_SERVER_ADDRESS stringByAppendingFormat:@"/avatar/group?request=%@", [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding]];
}

- (NSData *)getAppServiceCookies {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_APPSERVER_COOKIES];
}

- (NSString *)getAppServiceAuthToken {
    return [[NSUserDefaults standardUserDefaults] objectForKey:WFC_APPSERVER_AUTH_TOKEN];
}

- (void)clearAppServiceAuthInfos {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_APPSERVER_COOKIES];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:WFC_APPSERVER_AUTH_TOKEN];
    
    NSUserDefaults *sharedDefaults = [[NSUserDefaults alloc] initWithSuiteName:WFC_SHARE_APP_GROUP_ID];//此处id要与开发者中心创建时一致
        
    [sharedDefaults removeObjectForKey:WFC_SHARE_APPSERVICE_AUTH_TOKEN];
    NSArray<NSHTTPCookie *> *cookies = [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] cookies];
    [cookies enumerateObjectsUsingBlock:^(NSHTTPCookie * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [[NSHTTPCookieStorage sharedCookieStorageForGroupContainerIdentifier:WFC_SHARE_APP_GROUP_ID] deleteCookie:obj];
    }];
    

    [[WKWebsiteDataStore defaultDataStore] fetchDataRecordsOfTypes:[WKWebsiteDataStore allWebsiteDataTypes] completionHandler:^(NSArray * __nonnull records) {
        for (WKWebsiteDataRecord *record in records) {
            [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:record.dataTypes forDataRecords:@[record] completionHandler:^{}];
        }
    }];
}





#pragma mark - 通用接口  1206新增

- (void)requestUrl:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:url data:params isLogin:YES success:^(NSDictionary *dict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([dict[@"code"] intValue] == 0) {
                if(successBlock) successBlock(dict);
            } else {
                NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
                if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
            }
        });
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)requestUrlNoLogin:(NSString *)url params:(id)params success:(void(^)(NSDictionary *dict))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:url data:params isLogin:NO success:^(NSDictionary *dict) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([dict[@"code"] intValue] == 0) {
                if(successBlock) successBlock(dict);
            } else {
                NSString *errorStr = dict[@"message"] ? dict[@"message"] : @"error";
                if(errorBlock) errorBlock([dict[@"code"] intValue], errorStr);
            }
        });
    } error:^(NSError * _Nonnull error) {
        if(errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}


- (void)uploadFile:(NSString *)url
            images:(NSArray<UIImage *> *)images
           progress:(void(^)(int sentcount, int total))progressBlock
            success:(void(^)(NSString *url))successBlock
             error:(void(^)(NSString *errorMsg))errorBlock {
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
        manager.responseSerializer.acceptableContentTypes = [NSSet setWithObject:@"application/json"];
        
        //在调用其他接口时需要把cookie传给后台，也就是设置cookie的过程
        NSString *authToken = [self getAppServiceAuthToken];
        if(authToken.length) {
            [manager.requestSerializer setValue:authToken forHTTPHeaderField:AUTHORIZATION_HEADER];
        } else {
            NSData *cookiesdata = [self getAppServiceCookies];//url和登录时传的url 是同一个
            if([cookiesdata length]) {
                NSArray *cookies = [NSKeyedUnarchiver unarchiveObjectWithData:cookiesdata];
                NSHTTPCookie *cookie;
                for (cookie in cookies) {
                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                }
            }
        }
        NSString *postUrl = [APP_SERVER_ADDRESS stringByAppendingFormat:@"%@", url];
        NSLog(@"url====%@",postUrl);
        [manager
         POST:postUrl
         parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData>  _Nonnull formData) {
            if (images.count <= 0) {
                return;
            }
            for (UIImage *img in images) {
                NSData *data = UIImageJPEGRepresentation(img, 0.3);
                [formData appendPartWithFileData:data name:@"file" fileName:@"image.png" mimeType:@"image/jpeg"];
            }
        } progress:^(NSProgress * progress) {
            if (progressBlock) {
                progressBlock((int)progress.completedUnitCount, (int)progress.totalUnitCount);
            }
        } success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
            if ([responseObject isKindOfClass:[NSDictionary class]]) {
                NSDictionary *dict = (NSDictionary *)responseObject;
                NSLog(@"responseObject==%@",responseObject);
                if ([dict[@"code"] intValue] == 0) {
                    NSDictionary *resultDic = dict[@"result"];
                    if (resultDic.count) {
                        successBlock(resultDic[@"url"]);
                        return;
                    }
                }
            }
            errorBlock(@"Lỗi phản hồi máy chủ");
        }
         failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
            NSLog(@"上传失败：%@", error);
            errorBlock(error.localizedFailureReason);
        }];
    });
}

#pragma mark - 上传

- (void)generateUploadFile:(NSString *)fileName
                   success:(void(^)(NSString *uploadUrl, NSString *requestUrl))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock {
    NSDictionary *param = @{@"fileName": fileName ?: @""};
    [self post:@"/generateUploadFile/json" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            NSDictionary *result = dict[@"result"];
            if (successBlock) successBlock(result[@"uploadUrl"], result[@"requestUrl"]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)uploadData:(NSData *)data
               url:(NSString *)url
         remoteUrl:(NSString *)remoteUrl
           success:(void(^)(NSString *remoteUrl))successBlock
          progress:(void(^)(long uploaded, long total))progressBlock
              fail:(void(^)(int errorCode))errorBlock {
    NSURL *presignedURL = [NSURL URLWithString:url ?: @""];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:presignedURL];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"PUT";
    [request setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionUploadTask *uploadTask = [[NSURLSession sessionWithConfiguration:NSURLSessionConfiguration.defaultSessionConfiguration] uploadTaskWithRequest:request fromData:data completionHandler:^(NSData * _Nullable responseData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if (errorBlock) errorBlock(-500);
                return;
            }
            NSInteger statusCode = [(NSHTTPURLResponse *)response statusCode];
            if (statusCode != 200) {
                if (errorBlock) errorBlock((int)statusCode);
                return;
            }
            if (successBlock) successBlock(remoteUrl);
        });
    }];
    [uploadTask resume];
}

#pragma mark - 埋点

- (void)eventReport:(NSDictionary *)param
            success:(void(^)(void))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/event/report" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock();
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)eventBatchReport:(NSArray *)param
                 success:(void(^)(void))successBlock
                   error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/event/batchReport" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock();
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - 联系人标签

- (void)friendTagList:(void(^)(NSArray<WFCCUserTag *> *tags))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/friend/tag/list" data:nil isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            NSMutableArray *tags = [NSMutableArray array];
            for (NSDictionary *item in dict[@"result"]) {
                [tags addObject:[WFCCUserTag mj_objectWithKeyValues:item]];
            }
            if (successBlock) successBlock(tags);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)friendTagRename:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/friend/tag/rename" data:param success:successBlock error:errorBlock];
}

- (void)friendTagMembersSet:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/friend/tag/members/set" data:param success:successBlock error:errorBlock];
}

- (void)friendTagMembersRemove:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/friend/tag/members/remove" data:param success:successBlock error:errorBlock];
}

- (void)friendTagMembersList:(NSDictionary *)param
                     success:(void(^)(NSArray<WFCCUserInfo *> *friends))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/friend/tag/members/list" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            NSMutableArray *friends = [NSMutableArray array];
            for (NSDictionary *item in dict[@"result"]) {
                WFCCUserInfo *user = [WFCCUserInfo mj_objectWithKeyValues:item];
                if ([item[@"userExtra"] isKindOfClass:[NSDictionary class]]) {
                    user.extra = WFCJSONStringFromObject(item[@"userExtra"]);
                }
                [friends addObject:user];
            }
            if (successBlock) successBlock(friends);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)friendTagMembersAdd:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/friend/tag/members/add" data:param success:successBlock error:errorBlock];
}

- (void)friendTagMembersAddMulti:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/friend/tag/members/add/multi" data:param success:successBlock error:errorBlock];
}

- (void)friendTagForFriend:(NSDictionary *)param
                   success:(void(^)(NSArray<WFCCUserTag *> *tags))successBlock
                     error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/friend/tag/for-friend" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            NSMutableArray *tags = [NSMutableArray array];
            for (NSDictionary *item in dict[@"result"]) {
                [tags addObject:[WFCCUserTag mj_objectWithKeyValues:item]];
            }
            if (successBlock) successBlock(tags);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)friendTagDelete:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/friend/tag/delete" data:param success:successBlock error:errorBlock];
}

- (void)friendTagDeleteBatch:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/friend/tag/delete/batch" data:param success:successBlock error:errorBlock];
}

- (void)friendTagCreate:(NSDictionary *)param
                success:(void(^)(WFCCUserTag *tag))successBlock
                  error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/friend/tag/create" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            WFCCUserTag *tag = [WFCCUserTag mj_objectWithKeyValues:dict[@"result"]];
            if (successBlock) successBlock(tag);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)groupListQuery:(void(^)(NSArray<WFCCGroupInfo *> *groups))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock {
    NSArray<NSString *> *groupIds = [[WFCCIMService sharedWFCIMService] getFavGroups];
    NSArray<WFCCGroupInfo *> *groups = [[WFCCIMService sharedWFCIMService] getGroupInfos:groupIds refresh:NO];
    if (successBlock) successBlock(groups ?: @[]);
}

#pragma mark - 社区

- (void)communityArticlePublishPermission:(void(^)(BOOL canPublish))successBlock
                                    error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/community/article/publish-permission" data:nil isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock([dict[@"result"][@"canPublish"] boolValue]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)communityArticleAuthors:(void(^)(NSArray<WFCCCommunityUser *> *members))successBlock
                          error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/community/article/authors" data:nil isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            NSMutableArray *authors = [NSMutableArray array];
            for (NSDictionary *item in dict[@"result"]) {
                [authors addObject:[WFCCCommunityUser mj_objectWithKeyValues:item]];
            }
            if (successBlock) successBlock(authors);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)communityArticleList:(NSDictionary *)param
                     success:(void(^)(WFCCCommunityList *list))successBlock
                       error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/community/article/list" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock([WFCCCommunityList mj_objectWithKeyValues:dict[@"result"]]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)communityArticleCreate:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/community/article/create" data:param success:successBlock error:errorBlock];
}

- (void)communityArticleUpdate:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/community/article/update" data:param success:successBlock error:errorBlock];
}

- (void)communityArticleDelete:(NSDictionary *)param success:(void(^)(void))successBlock error:(void(^)(int errCode, NSString *message))errorBlock {
    [self postSimplePath:@"/community/article/delete" data:param success:successBlock error:errorBlock];
}

- (void)communityArticleDetail:(NSDictionary *)param
                       success:(void(^)(WFCCCommunity *articleDetail))successBlock
                         error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/community/article/detail" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock([WFCCCommunity mj_objectWithKeyValues:dict[@"result"]]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - 签到

- (void)signSubmit:(NSDictionary *)param
           success:(void(^)(WFCCSign *sign))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/sign/submit" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock([WFCCSign mj_objectWithKeyValues:dict[@"result"]]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)signResign:(NSDictionary *)param
           success:(void(^)(WFCCResign *resign))successBlock
             error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/sign/re-sign" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock([WFCCResign mj_objectWithKeyValues:dict[@"result"]]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)signTasks:(void(^)(WFCCSignTasks *tasks))successBlock
            error:(void(^)(int errCode, NSString *message))errorBlock {
    [self get:@"/sign/tasks" data:nil isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock([WFCCSignTasks mj_objectWithKeyValues:dict[@"result"]]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)signHistory:(NSDictionary *)param
            success:(void(^)(WFCCSignHistory *history))successBlock
              error:(void(^)(int errCode, NSString *message))errorBlock {
    [self get:@"/sign/history" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock([WFCCSignHistory mj_objectWithKeyValues:dict[@"result"]]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)pointsHistory:(NSDictionary *)param
              success:(void(^)(WFCCPointsHistory *history))successBlock
                error:(void(^)(int errCode, NSString *message))errorBlock {
    [self get:@"/points/history" data:param isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock([WFCCPointsHistory mj_objectWithKeyValues:dict[@"result"]]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

#pragma mark - AI

- (void)aiUrl:(void(^)(NSString *url))successBlock
        error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:@"/ai/url" data:nil isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            NSDictionary *resultDic = dict[@"result"];
            if (successBlock) successBlock(resultDic[@"url"]);
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

- (void)postSimplePath:(NSString *)path
                  data:(NSDictionary *)data
               success:(void(^)(void))successBlock
                 error:(void(^)(int errCode, NSString *message))errorBlock {
    [self post:path data:data isLogin:NO success:^(NSDictionary *dict) {
        if ([dict[@"code"] intValue] == 0) {
            if (successBlock) successBlock();
        } else if (errorBlock) {
            errorBlock([dict[@"code"] intValue], dict[@"message"]);
        }
    } error:^(NSError * _Nonnull error) {
        if (errorBlock) errorBlock(-1, error.localizedDescription);
    }];
}

@end
