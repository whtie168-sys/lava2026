//
//  Tep_ColdVC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_ColdVC.h"

@interface Tep_ColdVC ()

@end

@implementation Tep_ColdVC

- (void)viewDidLoad {
    [super viewDidLoad];
    UIImageView * i = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"cj"]];
    i.frame = CGRectMake(0, 10, 24, 24);
    
    UIButton * leftBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    leftBtn.frame = CGRectMake(0, 0, 44,44);
    
    [leftBtn setHidden:NO];
    [leftBtn addSubview:i];
    [leftBtn addTarget:self action:@selector(toAdd) forControlEvents:UIControlEventTouchUpInside];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithCustomView:leftBtn];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self getData];
}

- (void)getData {
    NSArray * allList = [NSUserDefaults arrayForKey:@"ColdList"];
    if (allList == nil) {
        allList = @[
            @{
                @"title": @"Wear one's hat",
                @"content": @"If you want to keep yourself warm, you must wear a hat and cover your ears. There are also many points on the head.Regular massage of the scalp can speed up blood circulation and warm",
                @"date": @"2022.11.05",
                @"imagename":UIImageJPEGRepresentation([UIImage imageNamed:@"tab3-1"],0.5f),
            },
       
            @{
                @"title": @"Soak feet before going to bed",
                @"content": @"The soles of shoes worn in winter shouId be higher than usual, so that they can isolate the cold from the cold ground;We should develop the habit of soaking our feet in hot water for at least",
                @"date": @"2022.11.04",
                @"imagename":UIImageJPEGRepresentation([UIImage imageNamed:@"tab3-2"],0.5f),
            },
        ];
    }

  self.list = allList;
  [self.tableView reloadData];
}


- (NSInteger)tableView:(nonnull UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
return self.list.count;

}
 
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    Tep_ColdCell* cell = [tableView dequeueReusableCellWithIdentifier:@"Tep_ColdCell"];
 [cell setData:self.list[indexPath.row]];
    return cell;
}

- (void)toAdd {
    [self.navigationController pushViewController:arriveVCName(@"Tep_ColdAddVC") animated:YES];
}
@end
