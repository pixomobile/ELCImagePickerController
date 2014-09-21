//
//  ELCAssetTablePicker.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAssetTablePicker.h"
#import "ELCAssetCell.h"
#import "ELCAsset.h"
#import "ELCAlbumPickerController.h"

@import Photos;

#define CELL_IDENTIFIER @"cell"

@implementation ELCAssetTablePicker

- (instancetype)init
{
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(THUMBNAIL_SIZE, THUMBNAIL_SIZE);

    self = [super initWithCollectionViewLayout:layout];
    
    return self;
}

- (void)viewDidLoad
{
    self.collectionView.backgroundColor = [UIColor whiteColor];

    if (self.immediateReturn) {
        
    } else {
        UIBarButtonItem *doneButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneAction:)];
        [self.navigationItem setRightBarButtonItem:doneButtonItem];
        [self.navigationItem setTitle:localizedString(@"loading")];
    }

    [self.collectionView registerClass:[ELCAssetCell class] forCellWithReuseIdentifier:CELL_IDENTIFIER];

	[self performSelectorInBackground:@selector(preparePhotos) withObject:nil];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return YES;
}

- (void)viewDidLayoutSubviews
{
    UICollectionViewFlowLayout * layout = (UICollectionViewFlowLayout *)self.collectionViewLayout;

    int width = self.collectionView.bounds.size.width;
    int nCols = (width -  4) / (THUMBNAIL_SIZE + 4);
    int padding = (width - nCols * THUMBNAIL_SIZE) / (nCols + 1);

    layout.minimumInteritemSpacing = padding;
    layout.minimumLineSpacing = padding;
    layout.sectionInset = UIEdgeInsetsMake(padding, padding, padding, padding);
}

- (void)preparePhotos
{
    @autoreleasepool {
        NSMutableArray * assets = [[NSMutableArray alloc] init];
    
        if (self.assetGroup == nil) {
            // iOS 8, "All Photos"
            PHFetchResult * moments = [PHAssetCollection fetchMomentsWithOptions:nil];
            
            for (PHAssetCollection * moment in moments) {
                PHFetchResult * assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:moment options:nil];

                for (PHAsset * asset in assetsFetchResults) {
                    if (asset.mediaType == PHAssetMediaTypeImage) {
                        ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:asset];
                        [assets addObject:elcAsset];
                    }
                }
            }
        } else {
            [self.assetGroup enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
                
                if (result == nil) {
                    return;
                }
                
                ELCAsset *elcAsset = [[ELCAsset alloc] initWithAsset:result];
                [elcAsset setParent:self];
                
                BOOL isAssetFiltered = NO;
                if (self.assetPickerFilterDelegate &&
                    [self.assetPickerFilterDelegate respondsToSelector:@selector(assetTablePicker:isAssetFilteredOut:)])
                {
                    isAssetFiltered = [self.assetPickerFilterDelegate assetTablePicker:self isAssetFilteredOut:(ELCAsset*)elcAsset];
                }
                
                if (!isAssetFiltered) {
                    [assets addObject:elcAsset];
                }
                
            }];
        }

        dispatch_sync(dispatch_get_main_queue(), ^{
            self.elcAssets = assets;
            [self.collectionView reloadData];

            // scroll to bottom
            if (assets.count > 0) {
                NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:assets.count - 1 inSection:0];
                [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
            }

            [self.navigationItem setTitle:self.singleSelection ? @"Pick Photo" : @"Pick Photos"];
        });
    }
}

- (void)doneAction:(id)sender
{
	NSMutableArray *selectedAssetsImages = [[NSMutableArray alloc] init];

	for (ELCAsset *elcAsset in self.elcAssets) {
		if ([elcAsset selected]) {
			[selectedAssetsImages addObject:[elcAsset asset]];
		}
	}
    [self.parent selectedAssets:selectedAssetsImages];
}


- (BOOL)shouldSelectAsset:(ELCAsset *)asset
{
    NSUInteger selectionCount = 0;
    for (ELCAsset *elcAsset in self.elcAssets) {
        if (elcAsset.selected) selectionCount++;
    }
    BOOL shouldSelect = YES;
    if ([self.parent respondsToSelector:@selector(shouldSelectAsset:previousCount:)]) {
        shouldSelect = [self.parent shouldSelectAsset:asset previousCount:selectionCount];
    }
    return shouldSelect;
}

- (void)assetSelected:(ELCAsset *)asset
{
    if (self.singleSelection) {

        for (ELCAsset *elcAsset in self.elcAssets) {
            if (asset != elcAsset) {
                elcAsset.selected = NO;
            }
        }
    }
    if (self.immediateReturn) {
        NSArray *singleAssetArray = @[asset.asset];
        [(NSObject *)self.parent performSelector:@selector(selectedAssets:) withObject:singleAssetArray afterDelay:0];
    }
}
- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.elcAssets.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    ELCAssetCell *cell = (ELCAssetCell*)[collectionView dequeueReusableCellWithReuseIdentifier:CELL_IDENTIFIER forIndexPath:indexPath];

    cell.asset = self.elcAssets[indexPath.item];
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    ELCAssetCell * cell = (ELCAssetCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
    
    [cell toggleSelection];
}

- (int)totalSelectedAssets
{
    int count = 0;
    
    for (ELCAsset *asset in self.elcAssets) {
		if (asset.selected) {
            count++;	
		}
	}
    
    return count;
}


@end
