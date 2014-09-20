//
//  AlbumPickerController.m
//
//  Created by ELC on 2/15/11.
//  Copyright 2011 ELC Technologies. All rights reserved.
//

#import "ELCAlbumPickerController.h"
#import "ELCImagePickerController.h"
#import "ELCAssetTablePicker.h"

@interface ELCAlbumPickerController ()

@property (nonatomic, strong) ALAssetsLibrary *library;

@end

@implementation ELCAlbumPickerController

//Using auto synthesizers

#pragma mark -
#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	
	[self.navigationItem setTitle:localizedString(@"loading")];

    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self.parent action:@selector(cancelImagePicker)];
	[self.navigationItem setLeftBarButtonItem:cancelButton];

    NSMutableArray *tempArray = [[NSMutableArray alloc] init];
	self.assetGroups = tempArray;
    
    ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
    self.library = assetLibrary;

    // Load Albums into assetGroups
    dispatch_async(dispatch_get_main_queue(), ^
    {
        @autoreleasepool {
        
        // Group enumerator Block
            void (^assetGroupEnumerator)(ALAssetsGroup *, BOOL *) = ^(ALAssetsGroup *group, BOOL *stop) 
            {
                if (group == nil) {
                    // Reload albums
                    [self performSelectorOnMainThread:@selector(reloadTableView) withObject:nil waitUntilDone:YES];

                    return;
                }
                
                // added fix for camera albums order
                NSUInteger nType = [[group valueForProperty:ALAssetsGroupPropertyType] intValue];
                
                if (nType == ALAssetsGroupSavedPhotos) {
                    [self.assetGroups insertObject:group atIndex:0];
                }
                else {
                    [self.assetGroups addObject:group];
                }
            };
            
            // Group Enumerator Failure Block
            void (^assetGroupEnumberatorFailure)(NSError *) = ^(NSError *error) {
                NSString * message;

                if (error.code == ALAssetsLibraryAccessUserDeniedError ||
                    error.code == ALAssetsLibraryAccessGloballyDeniedError) {
                    NSString * appName = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleDisplayName"];
                    message = [NSString stringWithFormat:localizedString(@"noaccess_album"), appName];
                } else {
                    message = error.localizedFailureReason;
                    if (error.localizedRecoverySuggestion != 0) {
                        message = [NSString stringWithFormat:@"%@ - %@", message, error.localizedRecoverySuggestion];
                    }
                }
                
                UIAlertView * alert = [[UIAlertView alloc] initWithTitle:localizedString(@"error")
                                                                 message:message
                                                                delegate:nil
                                                       cancelButtonTitle:localizedString(@"ok")
                                                       otherButtonTitles:nil];
                [alert show];
                
                NSLog(@"A problem occured %@", [error description]);
            };
            
            // Enumerate Albums
            [self.library enumerateGroupsWithTypes:ALAssetsGroupAll
                                        usingBlock:assetGroupEnumerator
                                      failureBlock:assetGroupEnumberatorFailure];
            
        }
    });    
}

- (void)reloadTableView
{
	[self.tableView reloadData];
	[self.navigationItem setTitle:localizedString(@"select_album")];
}

- (BOOL)shouldSelectAsset:(ELCAsset *)asset previousCount:(NSUInteger)previousCount
{
    return [self.parent shouldSelectAsset:asset previousCount:previousCount];
}

- (void)selectedAssets:(NSArray*)assets
{
	[_parent selectedAssets:assets];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    // Add "All Photos" on iOS 8
    return [self.assetGroups count] + (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1);
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    NSInteger row = indexPath.row;

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        if (row == 0) {
            // "All Photos" on iOS 8
            cell.textLabel.text = localizedString(@"all_photos");
            cell.imageView.image = nil;
            
            if (self.assetGroups.count > 0) {
                // Hack: there is no easy way to get a thumbnail for PHAssetCollection
                // Just use the thumbnail for album "Recent added"
                ALAssetsGroup *g = (ALAssetsGroup*)self.assetGroups[0];
                [cell.imageView setImage:[UIImage imageWithCGImage:g.posterImage]];
            }
        }

        row --;
    }
    
    if (row >= 0) {
        ALAssetsGroup *g = (ALAssetsGroup*)[self.assetGroups objectAtIndex:row];
        
        [g setAssetsFilter:[ALAssetsFilter allPhotos]];
        NSInteger gCount = [g numberOfAssets];
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@ (%ld)",[g valueForProperty:ALAssetsGroupPropertyName], (long)gCount];
        [cell.imageView setImage:[UIImage imageWithCGImage:g.posterImage]];
    }
    
	[cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
	
    return cell;
}

#pragma mark -
#pragma mark Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	ELCAssetTablePicker *picker = [[ELCAssetTablePicker alloc] init];
	picker.parent = self;

    NSInteger row = indexPath.row;

    if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_7_1) {
        row --;
    }

    // If row < 0, then it's "All Photos" on iOS 8
    if (row >= 0) {
        picker.assetGroup = [self.assetGroups objectAtIndex:row];
        [picker.assetGroup setAssetsFilter:[ALAssetsFilter allPhotos]];
    }
    
	picker.assetPickerFilterDelegate = self.assetPickerFilterDelegate;
	
	[self.navigationController pushViewController:picker animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 57;
}

@end

