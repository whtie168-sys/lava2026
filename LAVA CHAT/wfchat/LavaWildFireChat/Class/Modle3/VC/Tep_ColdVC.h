//
//  Tep_ColdVC.h
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface Tep_ColdVC : UIViewController
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property(nonatomic,strong)NSArray * list;

@end

NS_ASSUME_NONNULL_END
