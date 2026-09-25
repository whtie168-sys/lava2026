//
//  Tep_ColdAddVC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_ColdAddVC.h"

@interface Tep_ColdAddVC ()<UIImagePickerControllerDelegate,
UINavigationControllerDelegate>
@property (nonatomic, strong) UIImagePickerController *ColdimageP;

@end

@implementation Tep_ColdAddVC

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView * i = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"xy1"]];
    i.frame = CGRectMake(0, 10, 24, 24);
    
    UIButton * leftBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    leftBtn.frame = CGRectMake(0, 0, 44,44);
    
    [leftBtn setHidden:NO];
    [leftBtn addSubview:i];
    [leftBtn addTarget:self action:@selector(goback) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftBtn];
    
    UIImageView * r = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"xy1"]];
    r.frame = CGRectMake(0, 10, 24, 24);
    
    UIButton * rightBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    rightBtn.frame = CGRectMake(0, 0, 44,44);
    
        [rightBtn setTitle:@"OK" forState:normal];
        [rightBtn setFont:[UIFont fontWithName:@"Helvetica-Bold" size:20]];
        [rightBtn setTitleColor:[UIColor whiteColor] forState:normal];
        [rightBtn sizeToFit];
        [rightBtn addTarget:self action:@selector(toSave) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:rightBtn];
    
    self.titleV.layer.cornerRadius = 10;
    self.dateV.layer.cornerRadius = 10;
    self.addImageV.layer.cornerRadius = 10;
    self.contentV.layer.cornerRadius = 10;
    
    self.titleT.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_titleT.placeholder attributes:@{NSForegroundColorAttributeName: Color_HEX(0x188de7, 1)}];
    self.dateT.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_dateT.placeholder attributes:@{NSForegroundColorAttributeName: Color_HEX(0xffffff, 1)}];
    self.contentT.attributedPlaceholder = [[NSAttributedString alloc] initWithString:_contentT.placeholder attributes:@{NSForegroundColorAttributeName: Color_HEX(0xffffff, 1)}];

    self.ColdDateP = [UIDatePicker new];
       if (@available(iOS 13.4, *)) {
           self.ColdDateP.preferredDatePickerStyle = UIDatePickerStyleWheels;
       }
    
       self.ColdDateP.minimumDate = [NSDate new];
       self.ColdDateP.date = [NSDate new];
       self.ColdDateP.datePickerMode = UIDatePickerModeDate;
       [self.ColdDateP addTarget:self action:@selector(dateChange:)forControlEvents:UIControlEventValueChanged];
       self.dateT.inputView = self.ColdDateP;
    
    [self.showimageA addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImage)]];

}

- (void)toSave {
    NSMutableDictionary* dic = [NSMutableDictionary new];
   
    if (self.dateT.text.length > 0) {
      
        dic[@"date"] = self.dateT.text;
    }else {
    
        [FHXHUD showErrorTime:2 showTitle:@"Please select a date"];
        return;
    }
    
    if (self.titleT.text.length > 0) {
        dic[@"title"] = self.titleT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter place"];
        return;
    }
    
    if (self.contentT.text.length > 0) {
        dic[@"content"] = self.contentT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter target"];
        return;
    }
    
    if (self.showImage != nil) {
                dic[@"imagename"] = UIImageJPEGRepresentation(self.showImage,0.5f);
             }else {
                 [FHXHUD showErrorTime:2 showTitle:@"Please select a image"];
                 return;
             }
    
    NSMutableArray * arr = [[NSMutableArray alloc] initWithArray:[NSUserDefaults arrayForKey:@"ColdList"]];
    [arr insertObject:dic atIndex:0];
    [NSUserDefaults setObject:arr forKey:@"ColdList"];
    [self toback];
    
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    return  false;
}

- (void)dateChange:(UIDatePicker*)change {
    NSDate *date = change.date;
    NSString *dateString = [NSDate stringWithDate:date format:@"yyyy.MM.dd"];
    self.dateT.text = dateString;
}


-(void)goback {
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)selectImage {
    // MARK: 添加图片第三步：初始化图片选择器并弹出
    self.ColdimageP = [[UIImagePickerController alloc] init];
    self.ColdimageP.delegate = self;
    self.ColdimageP.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.ColdimageP animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.showimageA.image = image;
    self.showImage = image;
}
    

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}





@end
