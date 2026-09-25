//
//  Tep_ColdCell.h
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tep_ColdCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UIView *backgroundV;
@property (weak, nonatomic) IBOutlet UIView *contentV;
@property (weak, nonatomic) IBOutlet UILabel *titleL;
@property (weak, nonatomic) IBOutlet UILabel *contentL;
@property (weak, nonatomic) IBOutlet UILabel *dateL;
@property (weak, nonatomic) IBOutlet UIImageView *bgImage;
-(void)setData:(NSDictionary*)data;

@end

NS_ASSUME_NONNULL_END
