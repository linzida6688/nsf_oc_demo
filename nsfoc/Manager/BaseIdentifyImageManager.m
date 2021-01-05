//
//  BaseIdentifyImageManager.m
//  nsfoc
//
//  Created by Lindashuai on 2020/9/28.
//  Copyright © 2020 Lindashuai. All rights reserved.
//

#import "BaseIdentifyImageManager.h"
#if (TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE)
#else //真机
#import <FirebaseMLModelInterpreter/FIRModelInputs.h>
#import <FirebaseMLModelInterpreter/FIRModelOutputs.h>
#import <FirebaseMLModelInterpreter/FIRModelInterpreter.h>
#import <FirebaseMLModelInterpreter/FIRCustomLocalModel.h>
#import <FirebaseMLModelInterpreter/FIRModelInputOutputOptions.h>
static CGFloat const kPersentTag = 0.3;
#endif

@implementation BaseIdentifyImageManager

#pragma mark - manager

+ (void)checkImage:(UIImage *)image completBlock:(CompletIdentifyBlock)completBlock {
#if (TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE)
    return;
#else //真机
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    int INPUTWIDTH = 224;

    UIImage *scig = [self _scaleToSize:image size:CGSizeMake(256, 256)];
    scig = [self _imageFromImage:scig inRect:CGRectMake(16, 16, INPUTWIDTH, INPUTWIDTH)];

    NSString *modelPath = [NSBundle.mainBundle pathForResource:@"nsfw" ofType:@"tflite"];

    FIRCustomLocalModel *localModel = [[FIRCustomLocalModel alloc] initWithModelPath:modelPath];
    FIRModelInterpreter *fi = [FIRModelInterpreter modelInterpreterForLocalModel:localModel];

    CGImageRef cgImage = scig.CGImage;// Your input image
    //long imageWidth = CGImageGetWidth(image);
    //long imageHeight = CGImageGetHeight(image);

    CGContextRef context = [self _createARGBBitmapContextFromImage:cgImage];
    CGContextDrawImage(context, CGRectMake(0, 0, INPUTWIDTH, INPUTWIDTH), cgImage);

    UInt8 *imageData = CGBitmapContextGetData(context);

    CGContextRelease(context);
    FIRModelInputs *inputs = [[FIRModelInputs alloc] init];
    NSMutableData *inputData = [[NSMutableData alloc] initWithCapacity:0];
    int offs = 0;
    for (int row = offs; row < INPUTWIDTH + offs; row++) {
        for (int col = offs; col < INPUTWIDTH + offs; col++) {
            long offset = 4 * (row * INPUTWIDTH + col);
            
            Float32 red = imageData[offset];
            Float32 green = imageData[offset+1];
            Float32 blue = imageData[offset+2];
            Float32 red1 = red - 123;
            Float32 green1 = green - 117;
            Float32 blue1 = blue - 104;
            
            [inputData appendBytes:&blue1 length:sizeof(blue1)];
            [inputData appendBytes:&green1 length:sizeof(green1)];
            [inputData appendBytes:&red1 length:sizeof(red1)];
        }
    }

    NSError * error = nil;
    [inputs addInput:inputData error:&error];

    FIRModelInputOutputOptions *ioOptions = [[FIRModelInputOutputOptions alloc] init];
    [ioOptions setInputFormatForIndex:0
                                 type:FIRModelElementTypeFloat32
                           dimensions:@[@1, @224, @224, @3]
                                error:&error];
    if (error != nil) {
        return;
    }
    [ioOptions setOutputFormatForIndex:0
                                  type:FIRModelElementTypeFloat32
                            dimensions:@[@1, @2]
                                 error:&error];
    if (error != nil) {
        return;
    }
    [fi runWithInputs:inputs options:ioOptions completion:^(FIRModelOutputs *outputs, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            NSArray *ou = [outputs outputAtIndex:0 error:nil];
           
            NSNumber *f = ou[0][0];

            float value = 1 - [f floatValue];
            if (completBlock) {
                BOOL canShow = NO;
                if(value >= kPersentTag) { //色情图片
                    canShow = NO;
                } else { //不是
                    canShow = YES;
                }
                completBlock(canShow, value);
            }
            
            //NSLog(@"%@; %@",ou[0][0], ou[0][1]);
            //NSLog(@"e:%@",error);
        });
    }];
#pragma clang diagnostic pop
#endif
}

+ (UIImage *)_scaleToSize:(UIImage *)image size:(CGSize)size {
    // 创建一个bitmap的context
    // 并把它设置成为当前正在使用的context
    UIGraphicsBeginImageContext(size);
    // 绘制改变大小的图片
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    // 从当前context中创建一个改变大小后的图片
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();
    // 返回新的改变大小后的图片
    return scaledImage;
}

+ (UIImage *)_imageFromImage:(UIImage *)image inRect:(CGRect)rect {
    //将UIImage转换成CGImageRef
    CGImageRef sourceImageRef = [image CGImage];

    //按照给定的矩形区域进行剪裁
    CGImageRef newImageRef = CGImageCreateWithImageInRect(sourceImageRef, rect);

    //将CGImageRef转换成UIImage
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];

    //返回剪裁后的图片
    return newImage;
}

+ (CGContextRef)_createARGBBitmapContextFromImage:(CGImageRef)inImage {
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void * bitmapData;
    int bitmapByteCount;
    int bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t pixelsWide = CGImageGetWidth(inImage);
    size_t pixelsHigh = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow = (int)(pixelsWide * 4);
    bitmapByteCount = (int)(bitmapBytesPerRow * pixelsHigh);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    
    if (colorSpace == NULL) {
        fprintf(stderr, "Error allocating color space\n");
        return NULL;
    }
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL) {
        fprintf (stderr, "Memory not allocated!");
        CGColorSpaceRelease( colorSpace );
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    CGImageAlphaInfo alpInfo = CGImageGetAlphaInfo(inImage);
    context = CGBitmapContextCreate (bitmapData,
                                     pixelsWide,
                                     pixelsHigh,
                                     8, // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     alpInfo);
    // kCGImageAlphaNoneSkipFirst
    if (context == NULL) {
        free (bitmapData);
        fprintf (stderr, "Context not created!");
    }
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

#pragma mark - manager end

@end
