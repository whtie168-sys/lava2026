//
//  Tep_HeatAddVC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_HeatAddVC.h"

@interface Tep_HeatAddVC ()

@end

@implementation Tep_HeatAddVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.dateV.layer.cornerRadius = 10;
    self.propV.layer.cornerRadius = 10;
    self.excutedV.layer.cornerRadius = 10;
    self.contentV.layer.cornerRadius = 10;
    self.backV.layer.cornerRadius = 10;
    self.saveV.layer.cornerRadius = 10;
    
    self.dateV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
       self.dateV.layer.borderWidth = 2;
    self.propV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
       self.propV.layer.borderWidth = 2;
    self.excutedV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
       self.excutedV.layer.borderWidth = 2;
    self.contentV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
       self.contentV.layer.borderWidth = 2;
    self.backV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
       self.backV.layer.borderWidth = 2;
    self.saveV.layer.borderColor = [Color_HEX(0xffffff, 1) CGColor];
       self.saveV.layer.borderWidth = 2;

    self.dateT.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_dateT.placeholder attributes:@{NSForegroundColorAttributeName: Color_HEX(0xffffff, 1)}];
    self.propT.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_propT.placeholder attributes:@{NSForegroundColorAttributeName: Color_HEX(0xffffff, 1)}];
    self.excutedT.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_excutedT.placeholder attributes:@{NSForegroundColorAttributeName: Color_HEX(0xffffff, 1)}];
    self.contentT.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_contentT.placeholder attributes:@{NSForegroundColorAttributeName: Color_HEX(0xffffff, 1)}];

    self.HeatDateP = [UIDatePicker new];
       if (@available(iOS 13.4, *)) {
           self.HeatDateP.preferredDatePickerStyle = UIDatePickerStyleWheels;
       }
       self.HeatDateP.minimumDate = [NSDate new];
       self.HeatDateP.date = [NSDate new];
       self.HeatDateP.datePickerMode = UIDatePickerModeDate;
       [self.HeatDateP addTarget:self action:@selector(dateChange:)forControlEvents:UIControlEventValueChanged];
       self.dateT.inputView = self.HeatDateP;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return  false;
}

- (void)dateChange:(UIDatePicker*)change {
    NSDate *date = change.date;
    NSString *dateString = [NSDate stringWithDate:date format:@"yyyy.MM.dd"];
    self.dateT.text = dateString;
}

- (IBAction)clickSave:(id)sender {
    NSMutableDictionary* dic = [NSMutableDictionary new];
 
    if (self.dateT.text.length > 0) {
        dic[@"date"] = self.dateT.text;
    }else {
    
        [FHXHUD showErrorTime:2 showTitle:@"Please select a date"];
        return;
    }
    
    if (self.propT.text.length > 0) {
        dic[@"prop"] = self.propT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter prop"];
        return;
    }
    
    if (self.excutedT.text.length > 0) {
        dic[@"executed"] = self.excutedT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter execute"];
        return;
    }
    
    if (self.contentT.text.length > 0) {
        dic[@"content"] = self.contentT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter content"];
        return;
    }
    
    NSMutableArray * arr = [[NSMutableArray alloc] initWithArray:[NSUserDefaults arrayForKey:@"HeatList"]];
    [arr insertObject:dic atIndex:0];
    [NSUserDefaults setObject:arr forKey:@"HeatList"];
    [self toback];
    
}


- (IBAction)goback:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}


@end
