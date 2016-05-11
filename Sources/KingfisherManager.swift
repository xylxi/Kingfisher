//
//  KingfisherManager.swift
//  Kingfisher
//
//  Created by Wei Wang on 15/4/6.
//
//  Copyright (c) 2016 Wei Wang <onevcat@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

#if os(OSX)
    import AppKit
#else
    import UIKit
#endif

public typealias DownloadProgressBlock = ((receivedSize: Int64, totalSize: Int64) -> ())
public typealias CompletionHandler = ((image: Image?, error: NSError?, cacheType: CacheType, imageURL: NSURL?) -> ())

/// RetrieveImageTask represents a task of image retrieving process.
/// It contains an async task of getting image from disk and from network.
/// 图像检索处理的任务，检索缓存，和网络
public class RetrieveImageTask {
    
    // If task is canceled before the download task started (which means the `downloadTask` is nil),
    // the download task should not begin.
    var cancelledBeforeDownlodStarting: Bool = false
    
    /// The disk retrieve task in this image task. Kingfisher will try to look up in cache first. This task represent the cache search task.
    /// 从磁盘中检索图片的任务
    public var diskRetrieveTask: RetrieveImageDiskTask?
    
    /// The network retrieve task in this image task.
    /// 从网络下载图片的任务
    public var downloadTask: RetrieveImageDownloadTask?
    
    /**
     Cancel current task. If this task does not begin or already done, do nothing.
     取消当前的任务，如果任务还没有开始，或者已经结束，那么什么都不做
     */
    public func cancel() {
        // From Xcode 7 beta 6, the `dispatch_block_cancel` will crash at runtime.
        // It fixed in Xcode 7.1.
        // See https://github.com/onevcat/Kingfisher/issues/99 for more.
        if let diskRetrieveTask = diskRetrieveTask {
            // iOS8，以后新增的取消正在等待之行的GCD中的block
            dispatch_block_cancel(diskRetrieveTask)
        }
        
        // 如果正在下载中，那么调用cancel，请求下载 
        // 则session代理，会触发完成回调，UIImageView的setUrl方法结束
        // 所以不用设置cancelledBeforeDownlodStarting = true
        if let downloadTask = downloadTask {
            downloadTask.cancel()
        } else {
            cancelledBeforeDownlodStarting = true
        }
    }
    deinit {
        print("task is dead")
    }
}

/// Error domain of Kingfisher
public let KingfisherErrorDomain = "com.onevcat.Kingfisher.Error"

private let instance = KingfisherManager()

/// Main manager class of Kingfisher. It connects Kingfisher downloader and cache.
/// You can use this class to retrieve an image via a specified URL from web or cache.
public class KingfisherManager {
    
    /// Shared manager used by the extensions across Kingfisher.
    /// 因为有了let声明instance，所以不许呀担心多线程问题
    public class var sharedManager: KingfisherManager {
        return instance
    }
    
    /// Cache used by this manager
    public var cache: ImageCache
    
    /// Downloader used by this manager
    public var downloader: ImageDownloader
    
    /**
     Default init method
     
     - returns: A Kingfisher manager object with default cache, default downloader, and default prefetcher.
     */
    public convenience init() {
        self.init(downloader: ImageDownloader.defaultDownloader, cache: ImageCache.defaultCache)
    }
    
    init(downloader: ImageDownloader, cache: ImageCache) {
        self.downloader = downloader
        self.cache = cache
    }
    
    /**
     Get an image with resource.
     If KingfisherOptions.None is used as `options`, Kingfisher will seek the image in memory and disk first.
     如果KingfisherOptions枚举值为None，Kingfisher首先回去内存和磁盘中寻找image
     
     If not found, it will download the image at `resource.downloadURL` and cache it with `resource.cacheKey`.
     如果没有找到，将根据resource.downloadURL下载图片，并且使用resource.cacheKey作为key缓存下载的图片
     
     These default behaviors could be adjusted by passing different options. See `KingfisherOptions` for more.
     这些行为将会根据可选项的值调整
     
     - parameter resource:          Resource object contains information such as `cacheKey` and `downloadURL`.
     - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called every time downloaded data changed. This could be used as a progress UI.
     - parameter completionHandler: Called when the whole retrieving process finished.
     
     - returns: A `RetrieveImageTask` task object. You can use this object to cancel the task.
     */
    public func retrieveImageWithResource(resource: Resource,
        optionsInfo: KingfisherOptionsInfo?,
        progressBlock: DownloadProgressBlock?,
        completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        // 新建任务
        let task = RetrieveImageTask()
        
        // 判断optionsInfo是否包含.ForceRefresh
        if let optionsInfo = optionsInfo where optionsInfo.forceRefresh {
            downloadAndCacheImageWithURL(resource.downloadURL,
                forKey: resource.cacheKey,
                retrieveImageTask: task,
                progressBlock: progressBlock,
                completionHandler: completionHandler,
                options: optionsInfo)
        } else {
            tryToRetrieveImageFromCacheForKey(resource.cacheKey,
                withURL: resource.downloadURL,
                retrieveImageTask: task,
                progressBlock: progressBlock,
                completionHandler: completionHandler,
                options: optionsInfo)
        }
        
        return task
    }
    
    /**
     Get an image with `URL.absoluteString` as the key.
     If KingfisherOptions.None is used as `options`, Kingfisher will seek the image in memory and disk first.
     If not found, it will download the image at URL and cache it with `URL.absoluteString` value as its key.
     
     If you need to specify the key other than `URL.absoluteString`, please use resource version of this API with `resource.cacheKey` set to what you want.
     
     These default behaviors could be adjusted by passing different options. See `KingfisherOptions` for more.
     
     - parameter URL:               The image URL.
     - parameter optionsInfo:       A dictionary could control some behaviors. See `KingfisherOptionsInfo` for more.
     - parameter progressBlock:     Called every time downloaded data changed. This could be used as a progress UI.
     - parameter completionHandler: Called when the whole retrieving process finished.
     
     - returns: A `RetrieveImageTask` task object. You can use this object to cancel the task.
     */
    public func retrieveImageWithURL(URL: NSURL,
        optionsInfo: KingfisherOptionsInfo?,
        progressBlock: DownloadProgressBlock?,
        completionHandler: CompletionHandler?) -> RetrieveImageTask
    {
        return retrieveImageWithResource(Resource(downloadURL: URL), optionsInfo: optionsInfo, progressBlock: progressBlock, completionHandler: completionHandler)
    }
    
    /** 强制从网络上下载图片，并且缓存图片 */
    func downloadAndCacheImageWithURL(URL: NSURL,
        forKey key: String,
        retrieveImageTask: RetrieveImageTask,
        progressBlock: DownloadProgressBlock?,
        completionHandler: CompletionHandler?,
        options: KingfisherOptionsInfo?) -> RetrieveImageDownloadTask?
    {
        let downloader = options?.downloader ?? self.downloader
        return downloader.downloadImageWithURL(URL, retrieveImageTask: retrieveImageTask, options: options,
            progressBlock: { receivedSize, totalSize in
                progressBlock?(receivedSize: receivedSize, totalSize: totalSize)
            },
            //
            completionHandler: { image, error, imageURL, originalData in
                
                let targetCache = options?.targetCache ?? self.cache
                if let error = error where error.code == KingfisherError.NotModified.rawValue {
                    // Not modified. Try to find the image from cache.
                    // (The image should be in cache. It should be guaranteed by the framework users.)
                    targetCache.retrieveImageForKey(key, options: options, completionHandler: { (cacheImage, cacheType) -> () in
                        completionHandler?(image: cacheImage, error: nil, cacheType: cacheType, imageURL: URL)
                        
                    })
                    return
                }
                
                if let image = image, originalData = originalData {
                    // 如果有图片，缓存图片
                    targetCache.storeImage(image, originalData: originalData, forKey: key, toDisk: !(options?.cacheMemoryOnly ?? false), completionHandler: nil)
                }
                
                completionHandler?(image: image, error: error, cacheType: .None, imageURL: URL)
                
        })
    }
    
    /** 先尝试从缓存中获取图片 */
    func tryToRetrieveImageFromCacheForKey(key: String,
        withURL URL: NSURL,
        retrieveImageTask: RetrieveImageTask,
        progressBlock: DownloadProgressBlock?,
        completionHandler: CompletionHandler?,
        options: KingfisherOptionsInfo?)
    {
        let diskTaskCompletionHandler: CompletionHandler = { (image, error, cacheType, imageURL) -> () in
            // Break retain cycle created inside diskTask closure below
            retrieveImageTask.diskRetrieveTask = nil
            completionHandler?(image: image, error: error, cacheType: cacheType, imageURL: imageURL)
        }
        
        let targetCache = options?.targetCache ?? cache
        let diskTask = targetCache.retrieveImageForKey(key, options: options,
            completionHandler: { image, cacheType in
                if image != nil {
                    diskTaskCompletionHandler(image: image, error: nil, cacheType:cacheType, imageURL: URL)
                } else {
                    self.downloadAndCacheImageWithURL(URL,
                        forKey: key,
                        retrieveImageTask: retrieveImageTask,
                        progressBlock: progressBlock,
                        completionHandler: diskTaskCompletionHandler,
                        options: options)
                }
        })
        retrieveImageTask.diskRetrieveTask = diskTask
    }
}
