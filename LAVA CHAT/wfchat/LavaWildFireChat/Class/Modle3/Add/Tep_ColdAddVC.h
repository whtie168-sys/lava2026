//
//  Tep_ColdAddVC.h
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tep_ColdAddVC : Tep_tobackVC<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *titleV;
@property (weak, nonatomic) IBOutlet UITextField *titleT;
@property (weak, nonatomic) IBOutlet UIView *dateV;
@property (weak, nonatomic) IBOutlet UITextField *dateT;
@property (weak, nonatomic) IBOutlet UIView *addImageV;
@property (weak, nonatomic) IBOutlet UIImageView *showimageA;
@property (weak, nonatomic) IBOutlet UIView *contentV;
@property (weak, nonatomic) IBOutlet UITextField *contentT;
@property (nonatomic, strong) UIDatePicker *ColdDateP;

@property (strong,nonatomic) UIImage * showImage;

@end

NS_ASSUME_NONNULL_END
