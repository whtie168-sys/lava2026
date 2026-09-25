//
//  Tep_WarmCell.h
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tep_WarmCell : UICollectionViewCell
@property (weak, nonatomic) IBOutlet UIView *allV;
@property (weak, nonatomic) IBOutlet UIView *cottonV;
@property (weak, nonatomic) IBOutlet UIView *usageV;
@property (weak, nonatomic) IBOutlet UIView *recordedV;
@property (weak, nonatomic) IBOutlet UIView *evaluationV;
@property (weak, nonatomic) IBOutlet UIImageView *picImage;
@property (weak, nonatomic) IBOutlet UILabel *cottonL;
@property (weak, nonatomic) IBOutlet UILabel *timeL;
@property (weak, nonatomic) IBOutlet UILabel *nameL;
@property (weak, nonatomic) IBOutlet UILabel *evaluationL;
-(void)setWarmData:(NSDictionary*)data;

@end

NS_ASSUME_NONNULL_END
