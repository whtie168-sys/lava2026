//
//  Tep_conserveNC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_conserveNC.h"

@interface Tep_conserveNC ()

@end

@implementation Tep_conserveNC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    UIColor * fontC = Color_HEX(0xffffff,1);
    UIColor * backC = Color_HEX(0x19c2dd,1);
    
    [self changeNavColorTitleColor:fontC BgColor:backC IsStatusChange:YES];
}

- (void)leftBarBtnClicked:(UIButton *)btn
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated{
    
    if (self.childViewControllers.count > 0) {
        Tep_tobackVC * vc = (Tep_tobackVC *)viewController;
        
        vc.hidesBottomBarWhenPushed = YES;
        UIImageView * i = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"lj3077"]];
        i.frame = CGRectMake(0, 10, 24, 24);
        
        UIButton * leftBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        leftBtn.frame = CGRectMake(0, 0, 44,44);
        
        [leftBtn setHidden:NO];
        [leftBtn addSubview:i];
        [leftBtn addTarget:vc action:@selector(goLast) forControlEvents:UIControlEventTouchUpInside];
        vc.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftBtn];
    }
    
    [super pushViewController:viewController animated:animated];
    
    
}


@end
