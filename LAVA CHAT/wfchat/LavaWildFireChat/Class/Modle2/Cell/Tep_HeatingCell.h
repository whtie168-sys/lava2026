//
//  Tep_HeatingCell.h
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tep_HeatingCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *backgroundV;
@property (weak, nonatomic) IBOutlet UIView *contentV;
@property (weak, nonatomic) IBOutlet UIView *circleV;
-(void)setData:(NSDictionary*)data;
@property (weak, nonatomic) IBOutlet UILabel *PropL;
@property (weak, nonatomic) IBOutlet UILabel *contentL;
@property (weak, nonatomic) IBOutlet UILabel *executedL;
@property (weak, nonatomic) IBOutlet UILabel *dateL;
@property (weak, nonatomic) IBOutlet UIImageView *blueImage;
@property (weak, nonatomic) IBOutlet UIImageView *redImage;
@property (weak, nonatomic) IBOutlet UIButton *blueBtn;
@property (weak, nonatomic) IBOutlet UIButton *redBtn;

@end

NS_ASSUME_NONNULL_END
