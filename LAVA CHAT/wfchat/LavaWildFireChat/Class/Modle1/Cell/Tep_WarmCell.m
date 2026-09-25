//
//  Tep_WarmCell.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_WarmCell.h"

@implementation Tep_WarmCell
- (void)awakeFromNib {
    [super awakeFromNib];
    self.allV.layer.cornerRadius = 10;
//    self.allV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
    self.allV.layer.borderWidth = 4;
    self.cottonV.layer.cornerRadius = 20;
//    self.cottonV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
    self.cottonV.layer.borderWidth = 2;
    self.usageV.layer.cornerRadius = 20;
//    self.usageV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
    self.usageV.layer.borderWidth = 2;
    self.recordedV.layer.cornerRadius = 20;
//    self.recordedV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
    self.recordedV.layer.borderWidth = 2;
    self.evaluationV.layer.cornerRadius = 10;
//    self.evaluationV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
    self.evaluationV.layer.borderWidth = 2;
    self.picImage.layer.cornerRadius = 10;
//    self.picImage.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
    self.picImage.layer.borderWidth = 4;
}

-(void)setWarmData:(NSDictionary*)data {
    self.picImage.image = [UIImage imageWithData:data[@"imagename"]];
    self.cottonL.text = data[@"cotton"];
    self.timeL.text = data[@"time"];
    self.nameL.text = data[@"name"];
    self.evaluationL.text = data[@"evaluation"];
}

@end
