//
//  Tep_ColdCell.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_ColdCell.h"

@implementation Tep_ColdCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundV.layer.cornerRadius = 10;
    self.contentV.layer.cornerRadius = 10;
    self.bgImage.layer.cornerRadius = 15;
}

-(void)setData:(NSDictionary*)data {
   self.bgImage.image = [UIImage imageWithData:data[@"imagename"]];
    self.titleL.text = data[@"title"];
    self.contentL.text = data[@"content"];
    self.dateL.text = data[@"date"];
}

@end
