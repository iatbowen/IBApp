//
//  MBAssetManager.m
//  IBApplication
//
//  Created by Bowen on 2020/4/1.
//  Copyright © 2020 BowenCoder. All rights reserved.
//

#import "MBAssetManager.h"
#import "MBAsset.h"
#import "MBLogger.h"
#import "UIMacros.h"

void MBImageWriteToSavedPhotosAlbumWithAlbumAssetsGroup(UIImage *image, MBAssetGroup *albumAssetsGroup, MBWriteAssetCompletionBlock completionBlock) {
    [MBAssetManager saveImageWithImageRef:image.CGImage albumAssetsGroup:albumAssetsGroup orientation:image.imageOrientation completionBlock:completionBlock];
}

void MBSaveImageAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(NSString *imagePath, MBAssetGroup *albumAssetsGroup, MBWriteAssetCompletionBlock completionBlock) {
    [MBAssetManager saveImageWithImagePathURL:[NSURL fileURLWithPath:imagePath] albumAssetsGroup:albumAssetsGroup completionBlock:completionBlock];
}

void MBSaveVideoAtPathToSavedPhotosAlbumWithAlbumAssetsGroup(NSString *videoPath, MBAssetGroup *albumAssetsGroup, MBWriteAssetCompletionBlock completionBlock) {
    [MBAssetManager saveVideoWithVideoPathURL:[NSURL fileURLWithPath:videoPath] albumAssetsGroup:albumAssetsGroup completionBlock:completionBlock];
}

@implementation MBAssetManager

+ (MBAssetAuthorizationStatus)authorizationStatus {
    __block MBAssetAuthorizationStatus status;
    // 获取当前应用对照片的访问授权状态
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    if (authorizationStatus == PHAuthorizationStatusRestricted || authorizationStatus == PHAuthorizationStatusDenied) {
        status = MBAssetAuthorizationStatusNotAuthorized;
    } else if (authorizationStatus == PHAuthorizationStatusNotDetermined) {
        status = MBAssetAuthorizationStatusNotDetermined;
    } else {
        status = MBAssetAuthorizationStatusAuthorized;
    }
    return status;
}

+ (void)requestAuthorization:(void(^)(MBAssetAuthorizationStatus status))handler {
    [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus phStatus) {
        MBAssetAuthorizationStatus status;
        if (phStatus == PHAuthorizationStatusRestricted || phStatus == PHAuthorizationStatusDenied) {
            status = MBAssetAuthorizationStatusNotAuthorized;
        } else if (phStatus == PHAuthorizationStatusNotDetermined) {
            status = MBAssetAuthorizationStatusNotDetermined;
        } else {
            status = MBAssetAuthorizationStatusAuthorized;
        }
        if (handler) {
            handler(status);
        }
    }];
}

+ (void)enumerateAllAlbumsWithAlbumContentType:(MBAlbumContentType)contentType showEmptyAlbum:(BOOL)showEmptyAlbum showSmartAlbumIfSupported:(BOOL)showSmartAlbumIfSupported usingBlock:(void (^)(MBAssetGroup *resultAssetsGroup))enumerationBlock {
    // 根据条件获取所有合适的相册，并保存到临时数组中
    NSArray *tempAlbumsArray = [PHPhotoLibrary fetchAllAlbumsWithAlbumContentType:contentType showEmptyAlbum:showEmptyAlbum showSmartAlbum:showSmartAlbumIfSupported];
    
    // 创建一个 PHFetchOptions，用于 MBAssetGroup 对资源的排序以及对内容类型进行控制
    PHFetchOptions *phFetchOptions = [PHPhotoLibrary createFetchOptionsWithAlbumContentType:contentType];
    
    // 遍历结果，生成对应的 MBAssetGroup，并调用 enumerationBlock
    for (NSUInteger i = 0; i < [tempAlbumsArray count]; i++) {
        PHAssetCollection *phAssetCollection = [tempAlbumsArray objectAtIndex:i];
        MBAssetGroup *assetsGroup = [[MBAssetGroup alloc] initWithPHCollection:phAssetCollection fetchAssetsOptions:phFetchOptions];
        if (enumerationBlock) {
            enumerationBlock(assetsGroup);
        }
    }
    
    /**
     *  所有结果遍历完毕，这时再调用一次 enumerationBlock，并传递 nil 作为实参，作为枚举相册结束的标记。
     */
    if (enumerationBlock) {
        enumerationBlock(nil);
    }
}

+ (void)enumerateAllAlbumsWithAlbumContentType:(MBAlbumContentType)contentType usingBlock:(void (^)(MBAssetGroup *resultAssetsGroup))enumerationBlock {
    [self enumerateAllAlbumsWithAlbumContentType:contentType showEmptyAlbum:NO showSmartAlbumIfSupported:YES usingBlock:enumerationBlock];
}

+ (void)saveImageWithImageRef:(CGImageRef)imageRef albumAssetsGroup:(MBAssetGroup *)albumAssetsGroup orientation:(UIImageOrientation)orientation completionBlock:(MBWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把图片加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] addImageToAlbum:imageRef
                                    albumAssetCollection:albumPhAssetCollection
                                             orientation:orientation
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
        if (success) {
            PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
            PHAsset *phAsset = fetchResult.lastObject;
            MBAsset *asset = [[MBAsset alloc] initWithPHAsset:phAsset];
            completionBlock(asset, error);
        } else {
            MBLogE(@"Get PHAsset of image error: %@", error);
            completionBlock(nil, error);
        }
    }];
}

+ (void)saveImageWithImagePathURL:(NSURL *)imagePathURL albumAssetsGroup:(MBAssetGroup *)albumAssetsGroup completionBlock:(MBWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把图片加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] addImageToAlbum:imagePathURL
                                    albumAssetCollection:albumPhAssetCollection
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
        if (success) {
            PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
            PHAsset *phAsset = fetchResult.lastObject;
            MBAsset *asset = [[MBAsset alloc] initWithPHAsset:phAsset];
            completionBlock(asset, error);
        } else {
            MBLogE(@"Get PHAsset of image error: %@", error);
            completionBlock(nil, error);
        }
    }];
}

+ (void)saveVideoWithVideoPathURL:(NSURL *)videoPathURL albumAssetsGroup:(MBAssetGroup *)albumAssetsGroup completionBlock:(MBWriteAssetCompletionBlock)completionBlock {
    PHAssetCollection *albumPhAssetCollection = albumAssetsGroup.phAssetCollection;
    // 把视频加入到指定的相册对应的 PHAssetCollection
    [[PHPhotoLibrary sharedPhotoLibrary] addVideoToAlbum:videoPathURL
                                    albumAssetCollection:albumPhAssetCollection
                                       completionHandler:^(BOOL success, NSDate *creationDate, NSError *error) {
        if (success) {
            PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"creationDate = %@", creationDate];
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:albumPhAssetCollection options:fetchOptions];
            PHAsset *phAsset = fetchResult.lastObject;
            MBAsset *asset = [[MBAsset alloc] initWithPHAsset:phAsset];
            completionBlock(asset, error);
        } else {
            MBLogE(@"Get PHAsset of video Error: %@", error);
            completionBlock(nil, error);
        }
    }];
}

@end


@implementation PHPhotoLibrary (Ext)

+ (PHFetchOptions *)createFetchOptionsWithAlbumContentType:(MBAlbumContentType)contentType {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    // 根据输入的内容类型过滤相册内的资源
    switch (contentType) {
        case MBAlbumContentTypeOnlyPhoto:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i", PHAssetMediaTypeImage];
            break;
            
        case MBAlbumContentTypeOnlyVideo:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i",PHAssetMediaTypeVideo];
            break;
            
        case MBAlbumContentTypeOnlyAudio:
            fetchOptions.predicate = [NSPredicate predicateWithFormat:@"mediaType = %i",PHAssetMediaTypeAudio];
            break;
            
        default:
            break;
    }
    return fetchOptions;
}

+ (NSArray *)fetchAllAlbumsWithAlbumContentType:(MBAlbumContentType)contentType showEmptyAlbum:(BOOL)showEmptyAlbum showSmartAlbum:(BOOL)showSmartAlbum {
    NSMutableArray *tempAlbumsArray = [[NSMutableArray alloc] init];
    
    // 创建一个 PHFetchOptions，用于创建 MBAssetGroup 对资源的排序和类型进行控制
    PHFetchOptions *fetchOptions = [PHPhotoLibrary createFetchOptionsWithAlbumContentType:contentType];
    
    PHFetchResult *fetchResult;
    if (showSmartAlbum) {
        // 允许显示系统的“智能相册”
        // 获取保存了所有“智能相册”的 PHFetchResult
        fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAny options:nil];
    } else {
        // 不允许显示系统的智能相册，但由于在 PhotoKit 中，“相机胶卷”也属于“智能相册”，因此这里从“智能相册”中单独获取到“相机胶卷”
        fetchResult = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary options:nil];
    }
    // 循环遍历相册列表
    for (NSInteger i = 0; i < fetchResult.count; i++) {
        // 获取一个相册
        PHCollection *collection = fetchResult[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            // 获取相册内的资源对应的 fetchResult，用于判断根据内容类型过滤后的资源数量是否大于 0，只有资源数量大于 0 的相册才会作为有效的相册显示
            PHFetchResult *currentFetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
            if (currentFetchResult.count > 0 || showEmptyAlbum) {
                // 若相册不为空，或者允许显示空相册，则保存相册到结果数组
                // 判断如果是“相机胶卷”，则放到结果列表的第一位
                if (assetCollection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary) {
                    [tempAlbumsArray insertObject:assetCollection atIndex:0];
                } else {
                    [tempAlbumsArray addObject:assetCollection];
                }
            }
        } else {
            NSAssert(NO, @"Fetch collection not PHCollection: %@", collection);
        }
    }
    
    // 获取所有用户自己建立的相册
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    // 循环遍历用户自己建立的相册
    for (NSInteger i = 0; i < topLevelUserCollections.count; i++) {
        // 获取一个相册
        PHCollection *collection = topLevelUserCollections[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            
            if (showEmptyAlbum) {
                // 允许显示空相册，直接保存相册到结果数组中
                [tempAlbumsArray addObject:assetCollection];
            } else {
                // 不允许显示空相册，需要判断当前相册是否为空
                PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
                // 获取相册内的资源对应的 fetchResult，用于判断根据内容类型过滤后的资源数量是否大于 0
                if (fetchResult.count > 0) {
                    [tempAlbumsArray addObject:assetCollection];
                }
            }
        }
    }
    
    // 获取从 macOS 设备同步过来的相册，同步过来的相册不允许删除照片，因此不会为空
    PHFetchResult *macCollections = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    // 循环从 macOS 设备同步过来的相册
    for (NSInteger i = 0; i < macCollections.count; i++) {
        // 获取一个相册
        PHCollection *collection = macCollections[i];
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHAssetCollection *assetCollection = (PHAssetCollection *)collection;
            [tempAlbumsArray addObject:assetCollection];
        }
    }
    
    NSArray *resultAlbumsArray = [tempAlbumsArray copy];
    return resultAlbumsArray;
}

+ (PHAsset *)fetchLatestAssetWithAssetCollection:(PHAssetCollection *)assetCollection {
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    // 按时间的先后对 PHAssetCollection 内的资源进行排序，最新的资源排在数组最后面
    fetchOptions.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:YES]];
    PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:assetCollection options:fetchOptions];
    // 获取 PHAssetCollection 内最后一个资源，即最新的资源
    PHAsset *latestAsset = fetchResult.lastObject;
    return latestAsset;
}

- (void)addImageToAlbum:(CGImageRef)imageRef albumAssetCollection:(PHAssetCollection *)albumAssetCollection orientation:(UIImageOrientation)orientation completionHandler:(void(^)(BOOL success, NSDate *creationDate, NSError *error))completionHandler {
    UIImage *targetImage = [UIImage imageWithCGImage:imageRef scale:kScreenScale orientation:orientation];
    [[PHPhotoLibrary sharedPhotoLibrary] addImageToAlbum:targetImage imagePathURL:nil albumAssetCollection:albumAssetCollection completionHandler:completionHandler];
}

- (void)addImageToAlbum:(NSURL *)imagePathURL albumAssetCollection:(PHAssetCollection *)albumAssetCollection completionHandler:(void (^)(BOOL success, NSDate *creationDate, NSError *error))completionHandler {
    [[PHPhotoLibrary sharedPhotoLibrary] addImageToAlbum:nil imagePathURL:imagePathURL albumAssetCollection:albumAssetCollection completionHandler:completionHandler];
}

- (void)addImageToAlbum:(UIImage *)image imagePathURL:(NSURL *)imagePathURL albumAssetCollection:(PHAssetCollection *)albumAssetCollection completionHandler:(void(^)(BOOL success, NSDate *creationDate, NSError *error))completionHandler {
    __block NSDate *creationDate = nil;
    [self performChanges:^{
        // 创建一个以图片生成新的 PHAsset，这时图片已经被添加到“相机胶卷”
        
        PHAssetChangeRequest *assetChangeRequest;
        if (image) {
            assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        } else if (imagePathURL) {
            assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromImageAtFileURL:imagePathURL];
        } else {
            MBLogE(@"Creating asset with empty data");
            return;
        }
        assetChangeRequest.creationDate = [NSDate date];
        creationDate = assetChangeRequest.creationDate;
        
        if (albumAssetCollection.assetCollectionType == PHAssetCollectionTypeAlbum) {
            // 如果传入的相册类型为标准的相册（非“智能相册”和“时刻”），则把刚刚创建的 Asset 添加到传入的相册中。
            
            // 创建一个改变 PHAssetCollection 的请求，并指定相册对应的 PHAssetCollection
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:albumAssetCollection];
            /**
             *  把 PHAsset 加入到对应的 PHAssetCollection 中，系统推荐的方法是调用 placeholderForCreatedAsset ，
             *  返回一个的 placeholder 来代替刚创建的 PHAsset 的引用，并把该引用加入到一个 PHAssetCollectionChangeRequest 中。
             */
            [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
        }
        
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            MBLogE(@"Creating asset of image error : %@", error);
        }
        
        if (completionHandler) {
            /**
             *  performChanges:completionHandler 不在主线程执行，若用户在该 block 中操作 UI 时会产生一些问题，
             *  为了避免这种情况，这里该 block 主动放到主线程执行。
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                BOOL creatingSuccess = success && creationDate; // 若创建时间为 nil，则说明 performChanges 中传入的资源为空，因此需要同时判断 performChanges 是否执行成功以及资源是否有创建时间。
                completionHandler(creatingSuccess, creationDate, error);
            });
        }
    }];
}


- (void)addVideoToAlbum:(NSURL *)videoPathURL albumAssetCollection:(PHAssetCollection *)albumAssetCollection completionHandler:(void(^)(BOOL success, NSDate *creationDate, NSError *error))completionHandler {
    __block NSDate *creationDate = nil;
    [self performChanges:^{
        // 创建一个以视频生成新的 PHAsset 的请求
        PHAssetChangeRequest *assetChangeRequest = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:videoPathURL];
        assetChangeRequest.creationDate = [NSDate date];
        creationDate = assetChangeRequest.creationDate;
        
        if (albumAssetCollection.assetCollectionType == PHAssetCollectionTypeAlbum) {
            // 如果传入的相册类型为标准的相册（非“智能相册”和“时刻”），则把刚刚创建的 Asset 添加到传入的相册中。
            
            // 创建一个改变 PHAssetCollection 的请求，并指定相册对应的 PHAssetCollection
            PHAssetCollectionChangeRequest *assetCollectionChangeRequest = [PHAssetCollectionChangeRequest changeRequestForAssetCollection:albumAssetCollection];
            /**
             *  把 PHAsset 加入到对应的 PHAssetCollection 中，系统推荐的方法是调用 placeholderForCreatedAsset ，
             *  返回一个的 placeholder 来代替刚创建的 PHAsset 的引用，并把该引用加入到一个 PHAssetCollectionChangeRequest 中。
             */
            [assetCollectionChangeRequest addAssets:@[[assetChangeRequest placeholderForCreatedAsset]]];
        }
        
    } completionHandler:^(BOOL success, NSError *error) {
        if (!success) {
            MBLogE(@"Creating asset of video error: %@", error);
        }
        
        if (completionHandler) {
            /**
             *  performChanges:completionHandler 不在主线程执行，若用户在该 block 中操作 UI 时会产生一些问题，
             *  为了避免这种情况，这里该 block 主动放到主线程执行。
             */
            dispatch_async(dispatch_get_main_queue(), ^{
                completionHandler(success, creationDate, error);
            });
        }
    }];
}


@end
