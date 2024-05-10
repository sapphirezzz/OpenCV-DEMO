//
//  OutlineManager.m
//  OpenCV
//
//  Created by zack on 2024/5/10.
//

#ifdef __cplusplus
#import <opencv2/opencv.hpp>
#import <opencv2/imgcodecs/ios.h>
#import <opencv2/imgproc.hpp>
#import <opencv2/highgui.hpp>
#import <opencv2/core/operations.hpp>

#import <opencv2/core/core_c.h>
using namespace cv;
using namespace std;

#endif

#import "OutlineManager.h"

@implementation OutlineManager

Mat src; Mat src_gray;
int thresh = 100;
int max_thresh = 255;
RNG rng(12345);

+(UIImage *)cannyInputImage:(UIImage *)inputImage value:(int)value {

    if (value==0) {
        return inputImage;
    }
    cv::Mat srcImage= [OutlineManager cvMatFromUIImage: inputImage];
    cv::Mat destImage;
    destImage.create(srcImage.size(), srcImage.type());
    cv::Mat grayImage;
    cvtColor(srcImage, grayImage, cv::COLOR_BGR2GRAY);
    cv::Mat edge;
    blur(grayImage,edge,cv::Size(value,value));
    Canny(edge, edge, 13, 9, 3);
    destImage = cv::Scalar::all(0);
    srcImage.copyTo(destImage, edge);
    UIImage *image = [OutlineManager UIImageFromCVMat: destImage];
    return image;

//    vector<vector<cv::Point> > contours;
//    vector<Vec4i> hierarchy;
//    
//    if (value==0) {
//        return inputImage;
//    }
//    cv::Mat srcImage= [OutlineManager cvMatFromUIImage: inputImage];
//    cv::Mat destImage;
//    destImage.create(srcImage.size(), srcImage.type());
//    cv::Mat grayImage;
//    cvtColor(srcImage, grayImage, cv::COLOR_BGR2GRAY);
//    cv::Mat edge;
//    blur(grayImage,edge,cv::Size(value,value));
//    Canny(edge, edge, 13, 9, 3);
//    findContours( edge, contours, hierarchy, RETR_TREE, CHAIN_APPROX_SIMPLE, cv::Point(0, 0) );
//    
//    Mat drawing = Mat::zeros( edge.size(), CV_8UC3 );
//    for( int i = 0; i< contours.size(); i++ )
//       {
//         Scalar color = Scalar( rng.uniform(0, 255), rng.uniform(0,255), rng.uniform(0,255) );
//           drawContours( drawing, contours, i, color, 2, 8, hierarchy, 0, cv::Point() );
//       }
//
//    UIImage *image = [OutlineManager UIImageFromCVMat: drawing];
//    return image;
}

+(cv::Mat)cvMatFromUIImage:(UIImage *)image {

    //获取图片的CGImageRef结构体
    CGImageRef imageRef = CGImageCreateCopy([image CGImage]);
    //获取图片尺寸
    CGSize size = CGSizeMake(CGImageGetWidth(imageRef), CGImageGetHeight(imageRef));
    //获取图片宽度
    CGFloat cols = size.width;
    //获取图高度
    CGFloat rows = size.height;
    //获取图片颜色空间，创建图片对应Mat对象，需要使用同样的颜色空间
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    
    //判断图片的通道位深及通道数 默认使用8位4通道格式
    int type = CV_16UC4;
    //获取bitmpa位数
    size_t bitsPerPixel = CGImageGetBitsPerPixel(imageRef);
    //获取通道位深
    size_t bitsPerComponent = CGImageGetBitsPerComponent(imageRef);
    //获取通道数
    size_t channels = bitsPerPixel/bitsPerComponent;
    if(channels == 3 || channels == 4){  // 因为quartz框架只支持处理带有alpha通道的数据，所以3通道的图片采取跟4通道的图片一样的处理方式，转化的时候alpha默认会赋最大值，归一化的数值位1.0，这样即使给图片增加了alpha通道，也并不会影响图片的展示
        if(bitsPerComponent == 8){
            //8位3通道 因为iOS端只支持
            type = CV_8UC4;
        }else if(bitsPerComponent == 16){
            //16位3通道
            type = CV_16UC4;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else{
        printf("图片格式不支持");
        abort();
    }
    
    //创建位图信息  根据通道位深及通道数判断使用的位图信息
    CGBitmapInfo bitmapInfo;
    
    if(bitsPerComponent == 8){
        if(channels == 3){
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrderDefault;
        }else  if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrderDefault;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else if(bitsPerComponent == 16){
        if(channels == 3){  //虽然是三通道，但是iOS端的CGBitmapContextCreate方法不支持16位3通道的创建，所以仍然作为4通道处理
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else  if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else{
        printf("图片格式不支持");
        abort();
    }


    //使用获取到的宽高创建mat对象CV_16UC4 为传入的矩阵类型
    cv::Mat cvMat(rows, cols, type); // 每通道8bit 共有4通道（RGB + Alpha通道 RGBA格式）
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // 数据源
                                                    cols,                       // 每行像素数
                                                    rows,                       // 列数（高度）
                                                    bitsPerComponent,                          // 每个通道bit数
                                                    cvMat.step[0],              // 每行字节数
                                                    colorSpace,                 // 颜色空间
                                                    bitmapInfo); // 位图信息(alpha通道信息，字节读取信息)
    //将图片绘制到上下文中mat对象中
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    //释放imageRef对象
    CGImageRelease(imageRef);
    //释放颜色空间
    CGColorSpaceRelease(colorSpace);
    //释放上下文环境
    CGContextRelease(contextRef);
    return cvMat;
}

+(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
    
    //获取矩阵数据
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    //判断矩阵使用的颜色空间
    CGColorSpaceRef colorSpace;
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    //创建数据privder
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    //获取bitmpa位数
    size_t bitsPerPixel = cvMat.elemSize()*8;
    //获取通道数
    size_t channels = cvMat.channels();
    //获取通道位深
    size_t bitsPerComponent = bitsPerPixel/channels;
    
    //创建位图信息  根据通道位深及通道数判断使用的位图信息
    CGBitmapInfo bitmapInfo;
    if(bitsPerComponent == 8){
        if(channels == 3){
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrderDefault;
        }else if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrderDefault;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else if(bitsPerComponent == 16){
        if(channels == 3){
            bitmapInfo = kCGImageAlphaNone | kCGImageByteOrder16Little;
        }else if(channels == 4){
            bitmapInfo = kCGImageAlphaPremultipliedLast | kCGImageByteOrder16Little;
        }else{
            printf("图片格式不支持");
            abort();
        }
    }else{
        printf("图片格式不支持");
        abort();
    }
    
   

    //根据矩阵及相关信息创建CGImageRef结构体
    CGImageRef imageRef = CGImageCreate(cvMat.cols, //矩阵宽度
                                        cvMat.rows, //矩阵列数
                                        bitsPerComponent,        //通道位深
                                        8 * cvMat.elemSize(),  //每个像素位深
                                        cvMat.step[0],  //每行占用字节数
                                        colorSpace,    //使用的颜色空间
                                        bitmapInfo,//通道排序、大小端读取顺序信息
                                        provider, //数据源
                                        NULL,   //解码数组 一般传null
                                        true, //是否抗锯齿
                                        kCGRenderingIntentDefault   //使用默认的渲染方式
                                        );
    // 通过cgImage转化出来UIImage对象
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    //释放imageRef
    CGImageRelease(imageRef);
    //释放provider
    CGDataProviderRelease(provider);
    //释放颜色空间
    CGColorSpaceRelease(colorSpace);
    return finalImage;
}

@end
