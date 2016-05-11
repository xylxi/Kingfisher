//
//  Record.swift
//  Kingfisher
//
//  Created by WangZHW on 16/5/3.
//  Copyright © 2016年 Wei Wang. All rights reserved.
//

import Foundation
/*
ImageDownloader类的内部类
    ImageFetchLoad
    用于多个ImageView对同一个URL发请求，只需要一个请求
    当请求时，处理所有ImageView的进度
    请求结束(不管成功与否)，处理所有ImageView的完成回调问题

    对于每个ImageView发送cancel取消时候
    处理downloadTaskCount，当downloadTaskCount ＝ 0 时候，真正调用NSURLSessionTask的cancel方法

    // 疑问
    但是如果有3个ImageView对同一个URL发送请求，有一个ImageView进行取消操作的时候
    当请求结束，怎么知道回调到取消的ImageVIew的回调不回处理回调呢？还是一样会拿到请求的Image，进行显示？

    // 答案，当一个ImaegView进行了cancel操作，但是还有的ImageView不取消，当请求结束后，取消的ImageView的completion闭包，还是回处理的
*/