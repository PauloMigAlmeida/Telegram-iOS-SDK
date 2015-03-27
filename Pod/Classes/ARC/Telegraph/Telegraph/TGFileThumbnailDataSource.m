#import "TGFileThumbnailDataSource.h"

#import "TGStringUtils.h"

#import "TGWorkerPool.h"
#import "TGWorkerTask.h"
#import "TGMediaPreviewTask.h"

#import "TGMemoryImageCache.h"

#import "TGImageUtils.h"
#import "TGStringUtils.h"
#import "TGRemoteImageView.h"

#import "TGImageBlur.h"
#import "UIImage+TG.h"
#import "NSObject+TGLock.h"

#import "TGMediaStoreContext.h"

#import <AVFoundation/AVFoundation.h>
#import "TGCommon.h"

static TGWorkerPool *workerPool()
{
    static TGWorkerPool *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        instance = [[TGWorkerPool alloc] init];
    });
    
    return instance;
}

static ASQueue *taskManagementQueue()
{
    static ASQueue *queue = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        queue = [[ASQueue alloc] initWithName:"org.telegram.fileThumbnailTaskManagementQueue"];
    });
    
    return queue;
}

@implementation TGFileThumbnailDataSource

+ (void)load
{
    @autoreleasepool
    {
        [TGImageDataSource registerDataSource:[[self alloc] init]];
    }
}

- (bool)canHandleUri:(NSString *)uri
{
    return [uri hasPrefix:@"file-thumbnail://"];
}

- (bool)canHandleAttributeUri:(NSString *)uri
{
    return [uri hasPrefix:@"file-thumbnail://"];
}

- (id)loadDataAsyncWithUri:(NSString *)uri progress:(void (^)(float))progress partialCompletion:(void (^)(TGDataResource *resource))__unused partialCompletion completion:(void (^)(TGDataResource *))completion
{
    TGMediaPreviewTask *previewTask = [[TGMediaPreviewTask alloc] init];
    
    [taskManagementQueue() dispatchOnQueue:^
    {
        TGWorkerTask *workerTask = [[TGWorkerTask alloc] initWithBlock:^(bool (^isCancelled)())
        {
            TGDataResource *result = [TGFileThumbnailDataSource _performLoad:uri isCancelled:isCancelled];
            
            if (result != nil && progress != nil)
                progress(1.0f);
            
            if (isCancelled != nil && isCancelled())
                return;
            
            if (completion != nil)
                completion(result != nil ? result : [TGFileThumbnailDataSource resultForUnavailableImage]);
        }];
        
        if ([TGFileThumbnailDataSource _isDataLocallyAvailableForUri:uri])
        {
            [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
        }
        else
        {
            NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"file-thumbnail://?".length]];
            
            if ([args[@"legacy-thumbnail-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
            {
                static NSString *filesDirectory = nil;
                static dispatch_once_t onceToken;
                dispatch_once(&onceToken, ^
                {
                    filesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0] stringByAppendingPathComponent:@"files"];
                });
                
                NSString *fileDirectoryName = nil;
                if (args[@"id"] != nil)
                    fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"id"] longLongValue]];
                else
                    fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", (int64_t)[args[@"local-id"] longLongValue]];
                NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
                
                [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
                
                NSString *temporaryThumbnailImagePath = [fileDirectory stringByAppendingPathComponent:@"file-thumb.jpg"];
                
                [previewTask executeWithTargetFilePath:temporaryThumbnailImagePath uri:args[@"legacy-thumbnail-cache-url"] completion:^(bool success)
                {
                    if (success)
                    {
                        dispatch_async([TGCache diskCacheQueue], ^
                        {
                            [previewTask executeWithWorkerTask:workerTask workerPool:workerPool()];
                        });
                    }
                    else
                    {
                        if (completion != nil)
                            completion([TGFileThumbnailDataSource resultForUnavailableImage]);
                    }
                } workerTask:workerTask];
            }
            else
            {
                if (completion != nil)
                    completion([TGFileThumbnailDataSource resultForUnavailableImage]);
            }
        }
    }];
    
    return previewTask;
}

+ (bool)_isDataLocallyAvailableForUri:(NSString *)uri
{
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"file-thumbnail://?".length]];
    
    if ((![args[@"id"] respondsToSelector:@selector(longLongValue)] && [args[@"local-id"] respondsToSelector:@selector(longLongValue)]) || ![args[@"width"] respondsToSelector:@selector(intValue)] || ![args[@"height"] respondsToSelector:@selector(intValue)] || ![args[@"renderWidth"] respondsToSelector:@selector(intValue)] || ![args[@"renderHeight"] respondsToSelector:@selector(intValue)] || ![args[@"file-name"] respondsToSelector:@selector(characterAtIndex:)])
    {
        return false;
    }
    
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *fileDirectoryName = nil;
    if (args[@"id"] != nil)
        fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"id"] longLongValue]];
    else
        fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", (int64_t)[args[@"local-id"] longLongValue]];
    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
    
    CGSize size = CGSizeMake([args[@"width"] intValue], [args[@"height"] intValue]);
    CGSize renderSize = CGSizeMake([args[@"renderWidth"] intValue], [args[@"renderHeight"] intValue]);
    
    NSString *thumbnailPath = [fileDirectory stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"thumbnail-%dx%d-%dx%d.jpg", (int)size.width, (int)size.height, (int)renderSize.width, (int)renderSize.height]];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:thumbnailPath isDirectory:NULL])
        return true;
    
    NSString *temporaryThumbnailImagePath = [fileDirectory stringByAppendingPathComponent:@"file-thumb.jpg"];
    if ([[NSFileManager defaultManager] fileExistsAtPath:temporaryThumbnailImagePath])
        return true;
    
    NSString *filePath = [fileDirectory stringByAppendingPathComponent:args[@"file-name"]];
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL])
        return true;
    
    if ([args[@"legacy-thumbnail-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
    {
        NSString *legacyThumbnailImagePath = [[TGRemoteImageView sharedCache] pathForCachedData:args[@"legacy-thumbnail-cache-url"]];
        if ([[NSFileManager defaultManager] fileExistsAtPath:legacyThumbnailImagePath isDirectory:NULL])
            return true;
    }
    
    return false;
}

- (void)cancelTaskById:(id)taskId
{
    [taskManagementQueue() dispatchOnQueue:^
    {
        if ([taskId isKindOfClass:[TGMediaPreviewTask class]])
        {
            TGMediaPreviewTask *previewTask = taskId;
            [previewTask cancel];
        }
    }];
}

+ (TGDataResource *)resultForUnavailableImage
{
    static TGDataResource *imageData = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        imageData = [[TGDataResource alloc] initWithImage:TGAverageColorImage([UIColor whiteColor]) decoded:true];
    });
    
    return imageData;
}

- (id)loadAttributeSyncForUri:(NSString *)uri attribute:(NSString *)attribute
{
    if ([attribute isEqualToString:@"placeholder"])
    {
        UIImage *reducedImage = [[TGMediaStoreContext instance] mediaImage:uri attributes:nil];
        
        if (reducedImage != nil)
            return reducedImage;
        
        NSNumber *averageColor = [[TGMediaStoreContext instance] mediaImageAverageColor:uri];
        if (averageColor != nil)
        {
            UIImage *image = TGAverageColorImage(UIColorRGB([averageColor intValue]));
            return image;
        }
        
        static UIImage *placeholder = nil;
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^
        {
            placeholder = TGAverageColorImage([UIColor whiteColor]);
        });
        
        return placeholder;
    }
    
    return nil;
}

- (TGDataResource *)loadDataSyncWithUri:(NSString *)uri canWait:(bool)canWait acceptPartialData:(bool)__unused acceptPartialData asyncTaskId:(__autoreleasing id *)__unused asyncTaskId progress:(void (^)(float))__unused progress partialCompletion:(void (^)(TGDataResource *))__unused partialCompletion completion:(void (^)(TGDataResource *))__unused completion
{
    if (uri == nil)
        return nil;
    
    UIImage *cachedImage = [[TGMediaStoreContext instance] mediaImage:uri attributes:nil];
    if (cachedImage != nil)
        return [[TGDataResource alloc] initWithImage:cachedImage decoded:true];
    
    if (!canWait)
        return nil;
    
    return [TGFileThumbnailDataSource _performLoad:uri isCancelled:nil];
}

+ (TGDataResource *)_performLoad:(NSString *)uri isCancelled:(bool (^)())isCancelled
{
    if (isCancelled && isCancelled())
        return nil;
    
    NSDictionary *args = [TGStringUtils argumentDictionaryInUrlString:[uri substringFromIndex:@"file-thumbnail://?".length]];
    
    if ((![args[@"id"] respondsToSelector:@selector(longLongValue)] && ![args[@"local-id"] respondsToSelector:@selector(longLongValue)]) || ![args[@"width"] respondsToSelector:@selector(intValue)] || ![args[@"height"] respondsToSelector:@selector(intValue)] || ![args[@"renderWidth"] respondsToSelector:@selector(intValue)] || ![args[@"renderHeight"] respondsToSelector:@selector(intValue)] || ![args[@"file-name"] respondsToSelector:@selector(characterAtIndex:)])
    {
        return nil;
    }
    
    static NSString *filesDirectory = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^
    {
        filesDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, true)[0] stringByAppendingPathComponent:@"files"];
    });
    
    NSString *fileDirectoryName = nil;
    if (args[@"id"] != nil)
        fileDirectoryName = [[NSString alloc] initWithFormat:@"%" PRIx64 "", (int64_t)[args[@"id"] longLongValue]];
    else
        fileDirectoryName = [[NSString alloc] initWithFormat:@"local%" PRIx64 "", (int64_t)[args[@"local-id"] longLongValue]];
    NSString *fileDirectory = [filesDirectory stringByAppendingPathComponent:fileDirectoryName];
    
    CGSize size = CGSizeMake([args[@"width"] intValue], [args[@"height"] intValue]);
    CGSize renderSize = CGSizeMake([args[@"renderWidth"] intValue], [args[@"renderHeight"] intValue]);
    
    NSString *thumbnailPath = [fileDirectory stringByAppendingPathComponent:[[NSString alloc] initWithFormat:@"thumbnail-%dx%d-%dx%d.jpg", (int)size.width, (int)size.height, (int)renderSize.width, (int)renderSize.height]];
    
    UIImage *thumbnailSourceImage = [[UIImage alloc] initWithContentsOfFile:thumbnailPath];
    bool lowQualityThumbnail = false;
    
    if (thumbnailSourceImage == nil)
    {
        [[NSFileManager defaultManager] createDirectoryAtPath:fileDirectory withIntermediateDirectories:true attributes:nil error:nil];
        
        NSString *filePath = [fileDirectory stringByAppendingPathComponent:args[@"file-name"]];
        NSString *temporaryThumbnailImagePath = [fileDirectory stringByAppendingPathComponent:@"file-thumb.jpg"];
        
        UIImage *image = nil;
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:NULL])
        {
            image = [[UIImage alloc] initWithContentsOfFile:filePath];
            if (image == nil)
                image = [[UIImage alloc] initWithContentsOfFile:temporaryThumbnailImagePath];
        }
        else
        {
            image = [[UIImage alloc] initWithContentsOfFile:temporaryThumbnailImagePath];
            if (image == nil)
            {
                if ([args[@"legacy-thumbnail-cache-url"] respondsToSelector:@selector(characterAtIndex:)])
                {
                    NSString *legacyThumbnailImagePath = [[TGRemoteImageView sharedCache] pathForCachedData:args[@"legacy-thumbnail-cache-url"]];
                    image = [[UIImage alloc] initWithContentsOfFile:legacyThumbnailImagePath];
                    
                    if (image != nil)
                    {
                        [[NSFileManager defaultManager] copyItemAtPath:legacyThumbnailImagePath toPath:temporaryThumbnailImagePath error:nil];
                    }
                }
            }
            
            lowQualityThumbnail = true;
        }
        
        if (image != nil)
        {
            const float cacheFactor = 0.85f;
            CGSize cachedImageSize = CGSizeMake(ceilf(size.width * cacheFactor), ceilf(size.height * cacheFactor));
            CGSize cachedRenderSize = CGSizeMake(ceilf(renderSize.width * cacheFactor), ceilf(renderSize.height * cacheFactor));
            UIGraphicsBeginImageContextWithOptions(cachedImageSize, true, 2.0f);
            
            CGRect imageRect = CGRectMake((cachedImageSize.width - cachedRenderSize.width) / 2.0f, (cachedImageSize.height - cachedRenderSize.height) / 2.0f, cachedRenderSize.width, cachedRenderSize.height);
            [image drawInRect:imageRect blendMode:kCGBlendModeCopy alpha:1.0f];
            
            thumbnailSourceImage = UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            if (thumbnailSourceImage != nil && !lowQualityThumbnail)
            {
                NSData *thumbnailSourceData = UIImageJPEGRepresentation(thumbnailSourceImage, 0.8f);
                [thumbnailSourceData writeToFile:thumbnailPath atomically:false];
            }
        }
    }
    else
    {
        UIGraphicsBeginImageContextWithOptions(size, true, 2.0f);
        
        CGRect imageRect = CGRectMake(0.0f, 0.0f, size.width, size.height);
        [thumbnailSourceImage drawInRect:imageRect blendMode:kCGBlendModeCopy alpha:1.0f];
        
        thumbnailSourceImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    
    if (thumbnailSourceImage != nil)
    {
        UIImage *thumbnailImage = nil;
        
        NSNumber *averageColor = [[TGMediaStoreContext instance] mediaImageAverageColor:uri];
        bool needsAverageColor = averageColor == nil;
        uint32_t averageColorValue = [averageColor intValue];
        
        if (lowQualityThumbnail)
            thumbnailImage = TGBlurredFileImage(thumbnailSourceImage, size, needsAverageColor ? &averageColorValue : NULL);
        else
            thumbnailImage = TGLoadedFileImage(thumbnailSourceImage, size, needsAverageColor ? &averageColorValue : NULL);
        
        if (thumbnailImage != nil)
        {
            [[TGMediaStoreContext instance] setMediaImageAverageColorForKey:uri averageColor:@(averageColorValue)];
            if (!lowQualityThumbnail)
                [[TGMediaStoreContext instance] setMediaImageForKey:uri image:thumbnailImage attributes:nil];
        
            return [[TGDataResource alloc] initWithImage:thumbnailImage decoded:true];
        }
    }
    
    return nil;
}

@end