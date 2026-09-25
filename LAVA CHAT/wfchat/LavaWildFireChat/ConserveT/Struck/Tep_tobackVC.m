//
//  Tep_tobackVC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_tobackVC.h"

@interface Tep_tobackVC ()

@end

@implementation Tep_tobackVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

-(void)toback {
    [self.navigationController popViewControllerAnimated:YES];
}

@end
