//
//  Tep_HeatingCell.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_HeatingCell.h"

@implementation Tep_HeatingCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.backgroundV.layer.cornerRadius = 10;
    self.circleV.layer.cornerRadius = 70;
   
   

}
-(void)setData:(NSDictionary*)data {

    self.dateL.text = data[@"date"];
    self.PropL.text = data[@"prop"];
    self.contentL.text = data[@"content"];
    self.executedL.text = data[@"executed"];
    

}

- (IBAction)clickblueBtn:(id)sender {
    [self.blueImage setHidden:YES];
    [self.redImage setHidden:NO];
    [self.blueBtn setHidden:YES];
    [self.redBtn setHidden:NO];
}
- (IBAction)clickredBtn:(id)sender {
    [self.blueImage setHidden:NO];
    [self.redImage setHidden:YES];
    [self.blueBtn setHidden:NO];
    [self.redBtn setHidden:YES];
}




@end
