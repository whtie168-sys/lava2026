//
//  LaTabBarVC.m
//  LAVA
//
//  Created by Rubyuer on 9/28/23.
//

#import "LaTabBarVC.h"
#import "UIImage+ERCategory.h"

#import "LaConversationVC.h"
#import "LaContactsVC.h"
#import "LaCallosVC.h"
#import "LaProfileVC.h"
//#import "UNDJKWIOKDCommunityVC.h"
//#import "AIViewController.h"
#import "AppService.h"


@interface LaTabBarVC ()<UITabBarControllerDelegate>

@end

@implementation LaTabBarVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [UITabBar.appearance setUnselectedItemTintColor:RGBA(0xD0D0D0)];
    [UITabBar.appearance setTintColor:MAINCOLOR];
     
//    NSArray *ecgsoixVcs = @[LaConversationVC.new,
//                            LaContactsVC.new,
//                            UNDJKWIOKDCommunityVC.new,
//                            AIViewController.new,
//                            LaProfileVC.new];
    
    NSArray *ecgsoixVcs = @[LaConversationVC.new,
                            LaContactsVC.new,
                            LaProfileVC.new];
    
//    NSArray *titles = @[LLLLLL(@"Message"), LLLLLL(@"Contacts"), LLLLLL(@"Community"), LLLLLL(@"AI"), LLLLLL(@"Mine")];
    NSArray *titles = @[LLLLLL(@"Message"), LLLLLL(@"Contacts"), LLLLLL(@"Mine")];

    NSMutableArray *ecgsoixNvcs = NSMutableArray.new;
    for (NSInteger i = 0; i < ecgsoixVcs.count; i ++) {
        UINavigationController *ecgsoixNavi = [[UINavigationController alloc] initWithRootViewController:ecgsoixVcs[i]];
        ecgsoixNavi.tabBarItem = [[UITabBarItem alloc] initWithTitle:titles[i] image:[IMAGENAME(UNString(@"EGSIX%ldA", i)) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal] selectedImage:[IMAGENAME(UNString(@"EGSIX%ldAA", i)) imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
        [ecgsoixNvcs addObject:ecgsoixNavi];
    }
    self.viewControllers = ecgsoixNvcs;

    [self setTabbarBackGround];
    [self reportLaunchEvent];
    
}

- (void)setTabbarBackGround{
    if (@available(iOS 13.0, *)) {
        UITabBarAppearance *appearance = [self.tabBar.standardAppearance copy];
        appearance.backgroundImage = [UIImage imageWithColor:UIColor.clearColor size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 100.0)];
        appearance.shadowImage = [UIImage imageWithColor:UIColor.clearColor size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 100.0)];
        //下面这行代码最关键
        [appearance configureWithTransparentBackground];
        self.tabBar.standardAppearance = appearance;
    }else {
        [self.tabBar setBackgroundImage:[UIImage imageWithColor:UIColor.clearColor size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 100.0)]];
        [self.tabBar setShadowImage:[UIImage imageWithColor:UIColor.clearColor size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, 100.0)]];
//        self.tabBar.translucent =YES;
    }
}

- (void)onUnreadCommentStatusChanged:(NSNotification *)notification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self updateBadgeNumber];
    });
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateBadgeNumber];
}

- (void)updateBadgeNumber {
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
    [super traitCollectionDidChange:previousTraitCollection];
    if (@available(iOS 13.0, *)) {
        if ([self.traitCollection hasDifferentColorAppearanceComparedToTraitCollection:previousTraitCollection]) {
            if([[UIApplication sharedApplication].delegate respondsToSelector:@selector(setupNavBar)]) {
                [[UIApplication sharedApplication].delegate performSelector:@selector(setupNavBar)];
            }
            UIView *superView = self.view.superview;
            [self.view removeFromSuperview];
            [superView addSubview:self.view];
        }
    }
}

- (void)reportLaunchEvent {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ss";
    NSString *eventTime = [formatter stringFromDate:NSDate.date];
    
    NSString *appVersion = [NSBundle.mainBundle.infoDictionary objectForKey:@"CFBundleShortVersionString"] ?: @"";
    UIDevice *device = UIDevice.currentDevice;
    NSString *userId = WFCCNetworkService.sharedInstance.userId ?: @"";
    NSString *osType = [NSString stringWithFormat:@"iOS %@", device.systemVersion ?: @""];
    
    NSDictionary *params = @{
        @"eventName": @"use",
        @"content": @"app启动",
        @"eventTime": eventTime ?: @"",
        @"userId": userId,
        @"deviceInfo": device.model ?: @"",
        @"appVersion": appVersion,
        @"platform": @"iOS",
        @"osType": osType
    };
    
    [[AppService sharedAppService] eventReport:params success:^{
    } error:^(int errCode, NSString * _Nonnull message) {
    }];
}


@end
