//
//  Tep_WarmAddVC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_WarmAddVC.h"

@interface Tep_WarmAddVC ()<UIImagePickerControllerDelegate,
UINavigationControllerDelegate>
@property (nonatomic, strong) UIImagePickerController *WarmPicker;
@end

@implementation Tep_WarmAddVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bigV.layer.cornerRadius = 15;
    self.saveV.layer.cornerRadius = 20;
    self.timeV.layer.cornerRadius = 10;
    self.nameV.layer.cornerRadius = 10;
    self.takerV.layer.cornerRadius = 10;
    self.pictureV.layer.cornerRadius = 10;
    self.commentV.layer.cornerRadius = 10;
    self.cancelV.layer.cornerRadius = 20;
    
    [self.pictureImage addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectImage)]];

}

- (IBAction)back:(id)sender {

    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)clickSave:(id)sender {
    NSMutableDictionary* dic = [NSMutableDictionary new];
    if (self.timeT.text.length > 0) {
        dic[@"time"] = self.timeT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter Usage time"];
        return;
    }
    
    if (self.nameT.text.length > 0) {
        dic[@"cotton"] = self.nameT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter a Object name"];
        return;
    }
    
    if (self.takerT.text.length > 0) {
        dic[@"name"] = self.takerT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter Note-taker"];
        return;
    }
    
    if (self.commentT.text.length > 0) {
        dic[@"evaluation"] = self.commentT.text;
    }else {
        [FHXHUD showErrorTime:2 showTitle:@"Please enter Comments"];
        return;
    }
    
    if (self.showImage != nil) {
               dic[@"imagename"] = UIImageJPEGRepresentation(self.showImage,0.5f);
            }else {
                [FHXHUD showErrorTime:2 showTitle:@"Please select a image"];
                return;
            }

    NSMutableArray * arr = [[NSMutableArray alloc] initWithArray:[NSUserDefaults arrayForKey:@"WarmList"]];
    [arr insertObject:dic atIndex:0];
    [NSUserDefaults setObject:arr forKey:@"WarmList"];
    [self toback];
    
}

-(void)selectImage {
    self.WarmPicker = [[UIImagePickerController alloc] init];
    self.WarmPicker.delegate = self;
    self.WarmPicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    [self presentViewController:self.WarmPicker animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    self.pictureImage.image = image;
    self.showImage = image;
}
    
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}





@end
