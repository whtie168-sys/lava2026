//
//  Tep_HeatingVC.h
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tep_HeatingVC : UIViewController
@property (weak, nonatomic) IBOutlet UIView *addBtnV;
@property (weak, nonatomic) IBOutlet UIView *bigV;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic,strong)NSMutableArray * list;
@end

NS_ASSUME_NONNULL_END
