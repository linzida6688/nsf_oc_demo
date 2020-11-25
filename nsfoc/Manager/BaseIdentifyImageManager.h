//
//  BaseIdentifyImageManager.h
//  nsfoc
//
//  Created by Lindashuai on 2020/9/28.
//  Copyright © 2020 Lindashuai. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN
/*
 1.pod 'Firebase/Auth'(导入基础库) pod 'FirebaseMLModelInterpreter', '~> 0.22.0'# 鉴黄
 2.nsfw.tflite add file
 3.只能在真机运行
 */
typedef void(^CompletIdentifyBlock)(BOOL canShow, CGFloat valid);
@interface BaseIdentifyImageManager : NSObject

+ (void)checkImage:(UIImage *)image completBlock:(CompletIdentifyBlock)completBlock;

@end

NS_ASSUME_NONNULL_END
