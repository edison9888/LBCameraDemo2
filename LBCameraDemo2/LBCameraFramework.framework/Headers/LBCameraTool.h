//
//  LBCameraTool.h
//  LeBo
//
//  Created by 乐播 on 13-3-18.
//
//

#import <Foundation/Foundation.h>
#define Movie_Width 480.

@interface LBCameraTool : NSObject
/**
 *  根据视频的地址获取首帧图的方法
 *  videoPath 为视频地址
 */
+ (UIImage *)getThumbImageWithPath:(NSString *)videoPath;

/**
 *  根据视频地址获取首帧图像并返回图片地址的方法
 * videoPath 为视频地址
 */
+ (NSString *)getThumbPathWithPath:(NSString *)videoPath;

/**
 * 根据视频地址创建并获取首帧图片
 * videoPath 为视频地址
 */
+ (UIImage *)createThumbImageWithPath:(NSString *)videoPath;

/**
 * 根据后缀名获取视频地址
 * name 为后缀名
 */
+ (NSString *)videoPathWithName:(NSString *)name;

/**
 * 根据录制视频过程中的视频地址获取视频地址
 * param name  为后缀名
 */
+ (NSString *)videoTempPathWithName:(NSString *)name; 

/**
 * 根据录制视频过程中的视频地址获取视频地址
 * param  tempPath 为中间过程中完整的视频地址
 */
+ (NSString *)getFormalPathFromTempPath:(NSString *)tempPath;

/**
 * 根据原始地址获取中间过程中得地址
 * param formalPath 为原始地址
 */
+ (NSString *)getTempPathFromFormalPath:(NSString *)formalPath;

/**
 * 根据网址获取获取缓存的视频地址
 * param path 为视频的远程网址
 */
+ (NSString *)getCachePathForRemotePath:(NSString *)path;

/**
 * 根据地址检查是否文件地址下文件存在
 * param path 完整文件地址
 */
+ (BOOL)fileExist:(NSString *)file;

/**
 * 录制完成，根据中间地址，把视频转移到原始地址
 * param tempPath 视频的中间地址
 */
+ (void)moveToFormalPath:(NSString *)tempPath;

/**
 * 清除掉录制过程中的视频缓存
 */
+ (void)clearTemps;


@end
