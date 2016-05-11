//
//  ViewController.swift
//  Kingfisher-Demo
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

import UIKit
import Kingfisher

class ViewController: UICollectionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        title = "Kingfisher"
        
        
//        let imgV = UIImageView(frame: CGRectMake(100, 100, 100, 100))
//        self.view.addSubview(imgV)
//        imgV.kf_setImageWithURL(NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-0.jpg")!, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) in
//            print("1--->\(receivedSize),\(totalSize)")
//            }) { (image, error, cacheType, imageURL) in
//                print(image)
//        }
//        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * NSEC_PER_SEC)), dispatch_get_main_queue()) {
//        }
////        imgV.kf_setImageWithURL(NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-1.jpg")!, placeholderImage: nil, optionsInfo: nil, progressBlock: { (receivedSize, totalSize) in
//            print("2--->\(receivedSize),\(totalSize)")
//        }) { (image, error, cacheType, imageURL) in
//            print(image)
//        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func clearCache(sender: AnyObject) {
        KingfisherManager.sharedManager.cache.clearMemoryCache()
        KingfisherManager.sharedManager.cache.clearDiskCache()
    }
    
    @IBAction func reload(sender: AnyObject) {
        collectionView?.reloadData()
    }
}

extension ViewController {
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 10
    }
    
    override func collectionView(collectionView: UICollectionView, didEndDisplayingCell cell: UICollectionViewCell, forItemAtIndexPath indexPath: NSIndexPath) {
        
        // This will cancel all unfinished downloading task when the cell disappearing.
        // swiftlint:disable force_cast
        (cell as! CollectionViewCell).cellImageView.kf_cancelDownloadTask()
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        // swiftlint:disable force_cast
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("collectionViewCell", forIndexPath: indexPath) as! CollectionViewCell
        
        cell.cellImageView.kf_showIndicatorWhenLoading = true
        
        var URL = NSURL(string: "https://raw.githubusercontent.com/onevcat/Kingfisher/master/images/kingfisher-\(indexPath.row + 1).jpg")!
        if indexPath.row == 0 {
            URL = NSURL(string: "http://blog.ibireme.com/wp-content/uploads/2015/11/bbb-nodither.gif")!;
        }
        
        
        cell.cellImageView.kf_setImageWithURL(URL, placeholderImage: nil,
            optionsInfo: [.Transition(ImageTransition.Fade(1)),.BackgroundDecode],
            progressBlock: { receivedSize, totalSize in
                print("\(indexPath.row + 1): \(receivedSize)/\(totalSize)")
            },
            completionHandler: { image, error, cacheType, imageURL in
                print("\(indexPath.row + 1): Finished")
        })
        return cell
    }
}
