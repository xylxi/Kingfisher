//
//  AppDelegate.swift
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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    let queueA: dispatch_queue_t = dispatch_queue_create("com.xylxi.Kingfisher.test", DISPATCH_QUEUE_SERIAL)
    let queueB:  dispatch_queue_t = dispatch_queue_create("com.xylxi.Kingfisher.test", DISPATCH_QUEUE_CONCURRENT)
    
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        self.test_dispatch_barrier_async()
        
        return true
    }
    
    /**
     GCD的学习记录
     关于同步和异步新理解 2016-04-29
     dispatch_sync和dispatch_async本身就是一个函数
     当执行到dispatch_sync函数的时候，只用处理完dispatch_sync函数中的block，dispatch_sync函数才能return返回，，才能继续往下
     dispatch_async则不需要处理完dispatch_async函数中的block，就能return
     */
    
    /**
    *  首先main 队列执行test1任务
    *  打印了 current thread 1
    *  碰到了dispatch_sync(dispatch_get_global_queue(0, 0), ^{block});
    *  block加入了global队列，因为是同步任务，所以需要等到block执行完，才能返回，所以进程将在主线程挂起直到该 Block 完成
    *  global队列按照FIFO，调度队列中的任务
    *  当调度了block，打印了current thread 3，block完成后，返回
    *  返回后，继续主队的任务
    *  打印current thread 2
    */
    func test1() {
        print("current thread 1 = \(NSThread.currentThread())")
        dispatch_sync(dispatch_get_global_queue(0, 0)) { () -> Void in
            print("current thread 3 = \(NSThread.currentThread())")
        }
        print("current thread 2 = \(NSThread.currentThread())")
    }

    /**
     *  首先main 队列执行test2任务
     *  打印了 current thread 1
     *  碰到了dispatch_async(dispatch_get_global_queue(0, 0), ^{block});
     *  dispathch_async中的block加入global队列中，立即返回
     *  继续test2中的任务，打印current thread 2
     *  记住 Block 在全局队列中将按照 FIFO 顺序出列，但可以并发执行。
     *  添加到 dispatch_async 的代码块开始执行。
     *
     *  打印current thread 2和current thread 3，不一定谁在前，谁在后
     */
    func test2() {
        print("current thread 1 = \(NSThread.currentThread())")
        dispatch_async(dispatch_get_global_queue(0, 0)) { () -> Void in
            print("current thread 3 = \(NSThread.currentThread())")
        }
        print("current thread 2 = \(NSThread.currentThread())")
    }
    
    /**
    *  group中notify和wait的区别
    */
    func test3() {
        let queue = dispatch_get_global_queue(0, 0)
        let group = dispatch_group_create()
        
        print("begin group")
        for i in 0..<10 {
            dispatch_group_async(group, queue, { () -> Void in
                print("do \(i) at group")
            })
        }
        
        // 等group中的block都执行完后，调用这个，不阻塞当前线程
        dispatch_group_notify(group, queue) { () -> Void in
            print("all done at group")
        }
        //当前线程卡到这里，知道group中的block执行完，才往下走
        //    dispatch_group_wait(group, DISPATCH_TIME_FOREVER);
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
        
        print("after group")
    }
    
    /**
    *   dispatch_barrier_async处理多线程修改一个数据的问题
    *   dispatch_barrier_xxxx 函数，在将block派送到指定的queue中
    *   dispatch_barrier_xxxx中的block，等待前面的任务完成后，才能派送
    *   在执行dispatch_barrier_xxxx中的block期间，queue不能在派送新的任务
    */
    func test_dispatch_barrier_async() {
        dispatch_async(queueB) { () -> Void in
//            print(2)
        }
        dispatch_async(queueB) { () -> Void in
//            print(3)
        }
        dispatch_async(queueB) { () -> Void in
//            print(4)
        }
        dispatch_barrier_async(queueB) { () -> Void in
            for _ in 0..<100 {
//                print("<<<\(i)")
            }
        }
        dispatch_async(queueB) { () -> Void in
//            print(5)
        }
        dispatch_async(queueB) { () -> Void in
//            print(6)
        }
        dispatch_async(queueB) { () -> Void in
//            print(7)
        }
    }
}
