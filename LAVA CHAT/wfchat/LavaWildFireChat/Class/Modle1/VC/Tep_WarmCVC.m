//
//  Tep_WarmCVC.m
//  ConserveTepidity
//
//  Created by meng on 2022/11/8.
//

#import "Tep_WarmCVC.h"

@interface Tep_WarmCVC ()

@end

@implementation Tep_WarmCVC

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self getData];
}

- (void)getData {
    NSArray * allList = [NSUserDefaults arrayForKey:@"WarmList"];
    if (allList == nil) {
        allList = @[
            @{
                @"cotton": @"Cotton-padded jacket",
                @"time":@"5 years",
                @"name": @"Casa",
                @"evaluation": @"One thing to say, cotton padded jacket can save your only heat in winter",
                @"imagename":UIImageJPEGRepresentation([UIImage imageNamed:@"tab1-a"],0.5f),

            },
            
        ];
    }
  self.list = allList;
  [self.collectionView reloadData];
}


    - (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
    {
        return self.list.count;
    }
      
    -(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
    {
    static NSString *identify = @"MyCell";
        Tep_WarmCell *cell = (Tep_WarmCell *)[collectionView dequeueReusableCellWithReuseIdentifier:identify forIndexPath:indexPath];
       [cell setWarmData:self.list[indexPath.row]];
    return cell;

    }

- (CGSize)collectionView:(UICollectionView*)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath*)indexPath{
    return CGSizeMake(Tep_SCREEN_WIDTH - 100,455);
}

- (IBAction)clickAdd:(id)sender {
    [self.navigationController pushViewController:arriveVCName(@"Tep_WarmAddVC") animated:YES];
}


@end
