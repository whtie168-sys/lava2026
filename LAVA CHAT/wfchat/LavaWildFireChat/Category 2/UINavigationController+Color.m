//
//  UINavigationController+Color.m
//  EarlySummerLove
//
//  Created by 廿七 on 8/7/22.
//

#import "UINavigationController+Color.h"


@implementation UINavigationController (Color)

-(void)changeNavColorTitleColor:(UIColor *)titleColor BgColor:(UIColor *)bgColor IsStatusChange:(bool)isStatusChange {
    // 设置导航条背景图
//    UIImage *bgImg = [UIImage imageWithColorOne:isStatusChange ? bgColor : UIColor.whiteColor SizeOne:CGSizeMake(Tep_SCREEN_WIDTH, Tep_StatusBarHeight) ColorTwo:bgColor SizeTwo:CGSizeMake(Tep_SCREEN_WIDTH, Tep_NavBarHeight - Tep_StatusBarHeight)]; // [UIImage imageWithColor: UIColor.clearColor Size:CGSizeMake(Rehuo_SCREEN_WIDTH, Rehuo_NavBarHeight)];
//    if (@available(iOS 13.0, *)) {
//        UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
//        [appearance configureWithOpaqueBackground];
//        appearance.backgroundImage = bgImg;
//        appearance.shadowImage = [UIImage imageWithColor: UIColor.clearColor Size:CGSizeMake(Tep_SCREEN_WIDTH, 1)];
//        appearance.titleTextAttributes = @{NSForegroundColorAttributeName:titleColor, NSFontAttributeName:[UIFont systemFontOfSize:17]};
//        self.navigationBar.standardAppearance = UINavigationBarAppearance;
//        self.navigationBar.scrollEdgeAppearance = 2;
//    }else{
//        self.navigationBar.shadowImage = [UIImage imageWithColor: UIColor.clearColor Size:CGSizeMake(Tep_SCREEN_WIDTH, 1)];
//        self.navigationBar.titleTextAttributes =
//        @{NSForegroundColorAttributeName:titleColor, NSFontAttributeName:[UIFont systemFontOfSize:17]};
//    }
//    [self.navigationBar setBackgroundImage:bgImg forBarMetrics:UIBarMetricsDefault];
}
@end
