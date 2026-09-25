//
//  Tep_HeatingVC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_HeatingVC.h"

@interface Tep_HeatingVC ()

@end

@implementation Tep_HeatingVC

- (void)viewDidLoad {
    [super viewDidLoad];
//
    self.addBtnV.layer.cornerRadius = 10;
    self.bigV.layer.cornerRadius = 10;
    [self.bigV setRoundedCorners: UIRectCornerBottomLeft | UIRectCornerBottomRight radius:0];

}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self getData];
}

- (void)getData {
    NSMutableArray * allList = [[NSMutableArray alloc] initWithArray:[NSUserDefaults arrayForKey:@"HeatList"]];
    
    if ([NSUserDefaults arrayForKey:@"HeatList"] == nil) {
        
        allList =[[NSMutableArray alloc] initWithArray: @[
            @{
                @"date": @"2022.11.05",
                @"prop": @"Charcoal, brazier",
                @"content": @"Today, continue to raise a brazier for heating",
                @"executed": @"Casa",
            },
            @{
                @"date": @"2022.11.02",
                @"prop": @"Electric heater",
                @"content": @"It's better to use an electric heater for heating",
                @"executed": @"Casa",
            },
            
        ]];
    }
    
  self.list = allList;

  [self.tableView reloadData];
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
return self.list.count;
}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    Tep_HeatingCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Tep_HeatingCell"];
 
 [cell setData:self.list[indexPath.row]];
    return cell;
}

- (IBAction)clickAdd:(id)sender {
    [self.navigationController pushViewController:arriveVCName(@"Tep_HeatAddVC") animated:YES];
}
@end
