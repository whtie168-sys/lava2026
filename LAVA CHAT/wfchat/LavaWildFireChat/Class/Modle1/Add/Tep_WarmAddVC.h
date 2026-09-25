//
//  Tep_WarmAddVC.h
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tep_WarmAddVC : Tep_tobackVC
@property (weak, nonatomic) IBOutlet UIView *bigV;
@property (weak, nonatomic) IBOutlet UIView *saveV;
@property (weak, nonatomic) IBOutlet UIView *timeV;
@property (weak, nonatomic) IBOutlet UIView *nameV;
@property (weak, nonatomic) IBOutlet UIView *takerV;
@property (weak, nonatomic) IBOutlet UIView *pictureV;
@property (weak, nonatomic) IBOutlet UIView *commentV;
@property (weak, nonatomic) IBOutlet UIView *cancelV;
@property (weak, nonatomic) IBOutlet UIImageView *pictureImage;
@property (strong,nonatomic) UIImage * showImage;
@property (weak, nonatomic) IBOutlet UITextField *timeT;
@property (weak, nonatomic) IBOutlet UITextField *nameT;
@property (weak, nonatomic) IBOutlet UITextField *takerT;

@property (weak, nonatomic) IBOutlet UITextField *commentT;
@end

NS_ASSUME_NONNULL_END
