//
//  Tep_HeatAddVC.h
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tep_HeatAddVC : Tep_tobackVC<UITextFieldDelegate>
@property (weak, nonatomic) IBOutlet UIView *dateV;
@property (weak, nonatomic) IBOutlet UIView *propV;
@property (weak, nonatomic) IBOutlet UIView *excutedV;
@property (weak, nonatomic) IBOutlet UIView *contentV;
@property (weak, nonatomic) IBOutlet UIView *backV;
@property (weak, nonatomic) IBOutlet UIView *saveV;
@property (weak, nonatomic) IBOutlet UITextField *dateT;
@property (weak, nonatomic) IBOutlet UITextField *propT;
@property (weak, nonatomic) IBOutlet UITextField *excutedT;
@property (weak, nonatomic) IBOutlet UITextField *contentT;
@property (nonatomic, strong) UIDatePicker *HeatDateP;
@end

NS_ASSUME_NONNULL_END
