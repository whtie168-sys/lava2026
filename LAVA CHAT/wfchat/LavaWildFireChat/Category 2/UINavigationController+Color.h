//
//  UINavigationController+Color.h
//  EarlySummerLove
//
//  Created by 廿七 on 8/7/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface UINavigationController (Color)
///修改导航栏颜色
-(void)changeNavColorTitleColor:(UIColor *)titleColor BgColor:(UIColor *)bgColor IsStatusChange:(bool)isStatusChange;
@end

NS_ASSUME_NONNULL_END
