//
//  Tep_conserveTB.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_conserveTB.h"

@implementation Tep_conserveTB

- (instancetype)initWithFrame:(CGRect)frame{
    self = [super initWithFrame:frame];
    if(self) {
           [self addSubview:self.tabbarBgImage];
            [self setShadowImage:[UIImage new]];
    }
    return self;
}

- (void)layoutSubviews{
    [super layoutSubviews];
    

    CGFloat tabBarButtonW = Tep_SCREEN_WIDTH / 3;
    CGFloat tabBarButtonIndex = 0;
    for (UIView *child in self.subviews) {
        Class class = NSClassFromString(@"UITabBarButton");
        if ([child isKindOfClass:class]) {
            CGRect frame = CGRectMake(tabBarButtonIndex * tabBarButtonW, 0, tabBarButtonW, Tep_TabBarHeight - Tep_TabbarSafeBottomMargin);
            child.frame = frame;
            tabBarButtonIndex ++;
        }
    }
    
}

- (UIImageView *)tabbarBgImage {
    if (_tabbarBgImage == nil) {
        _tabbarBgImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, Tep_SCREEN_WIDTH, Tep_TabBarHeight)];
        _tabbarBgImage.image = [UIImage imageWithColor:Color_HEX(0xFFFFFF,1)];
    }
    return _tabbarBgImage;
}


@end
