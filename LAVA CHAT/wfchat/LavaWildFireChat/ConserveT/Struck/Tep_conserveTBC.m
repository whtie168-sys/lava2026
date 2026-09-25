//
//  Tep_conserveTBC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_conserveTBC.h"

@interface Tep_conserveTBC ()

@end

@implementation Tep_conserveTBC

- (void)viewDidLoad {
    [super viewDidLoad];
    Tep_conserveTB *tabBar = [[Tep_conserveTB alloc] init];
    [self setValue:tabBar forKey:@"tabBar"];
    
   
    Tep_WarmCVC * WarmCVC = arriveVCName(@"Tep_WarmCVC");
    [self setUpVC:WarmCVC image:[UIImage imageNamed:@"drwn0"] selectImage:[UIImage imageNamed:@"drwn"] title:@"Warm in winter"];
    Tep_HeatingVC * HeatingVC = arriveVCName(@"Tep_HeatingVC");
    [self setUpVC:HeatingVC image:[UIImage imageNamed:@"qnxd0"] selectImage:[UIImage imageNamed:@"qnxd"] title:@"Heating action"];
    Tep_ColdVC * ColdVC = arriveVCName(@"Tep_ColdVC");
    [self setUpVC:ColdVC image:[UIImage imageNamed:@"khsf0"] selectImage:[UIImage imageNamed:@"khsf"] title:@"Cold resistance"];
    
  
    [UITabBar appearance].barTintColor = Color_HEX(0xFFFFFF,1);
    self.tabBar.selectionIndicatorImage = [UIImage imageWithColor:Color_HEX(0xffffff,1) Size:CGSizeMake(Tep_SCREEN_WIDTH /3, Tep_TabBarHeight)];
    
 
    self.tabBar.tintColor = Color_HEX(0x181616, 1);
    self.tabBar.unselectedItemTintColor = Color_HEX(0x181616, 1);
     
}

- (void)setUpVC:(UIViewController *)vc image:(UIImage *)image selectImage:(UIImage *)selectImage title:(NSString *)title {
    Tep_conserveNC * NC = [[Tep_conserveNC alloc] initWithRootViewController:vc];
    NC.title = title;
    NC.tabBarItem.image = [[image resizedImage:CGSizeMake(30, 30) interpolationQuality:1] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    NC.tabBarItem.selectedImage = [[selectImage resizedImage:CGSizeMake(30, 30) interpolationQuality:1] imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
    
    vc.title = title;
    [self addChildViewController:NC];
}



@end
