//
//  AssetCell.h
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ELCAsset.h"

@interface ELCAssetCell : UICollectionViewCell

@property (nonatomic) ELCAsset * asset;

- (void)toggleSelection;

@end
