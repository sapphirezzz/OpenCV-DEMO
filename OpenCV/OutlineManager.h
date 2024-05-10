//
//  OutlineManager.h
//  OpenCV
//
//  Created by zack on 2024/5/10.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface OutlineManager: NSObject

+(UIImage *)cannyInputImage:(UIImage *)inputImage value:(int)value;

@end

NS_ASSUME_NONNULL_END
