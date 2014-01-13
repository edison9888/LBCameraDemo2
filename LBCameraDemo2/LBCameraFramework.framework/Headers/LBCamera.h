//
//  LBCamera.h
//  cameraDemo
//
//  Created by 乐播 on 13-3-1.
//  Copyright (c) 2013年 乐播. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "LBView.h"

@protocol LBCameraDelegate;

@interface LBCamera : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate,LBViewDisplayDelegate>

// 视频的时长
@property(nonatomic,readonly)   double          writedDuration;
// 视频的预览载体
@property(nonatomic,readonly)   LBView          *cameraView;
// 录制的视频输出路径
@property(nonatomic,readonly)   NSString        *videoPath;
// 
@property(nonatomic,retain)     UIImage         *waterImage;
// 录制完成回调代理
@property(nonatomic,assign)     id              <LBCameraDelegate> delegate;
// 视频预览层
@property(nonatomic,readonly)   AVCaptureVideoPreviewLayer * layer;
// 视频的前后摄像头方向
@property(nonatomic,readwrite)  AVCaptureDevicePosition cameraPosition;

//- (void)processPixelBufferBlue: (CVImageBufferRef)pixelBuffer;

/**
 * 自定义视频输出路径
 */
- (id)initWithFilePath:(NSString *)filePath;

/* 默认视频输出路径 
 * 例如：/Documents/movie/2014_01_13_03_07_19.mp4
 */
- (id)init;

/** 
 *开始捕获头像
 */
- (void)startCapture;

/**
 *结束捕获头像
 */
- (void)endCapture;

/**
 *开始录制视频
 */
- (void)startRecord;

/**
 *暂停录制
 */
- (void)pauseRecord;

/**
 *结束录制  结束后回自动合成视频，并回调 - (void)didFinishExport:(LBCamera *)camera withSuccess:(BOOL)success;
 */
- (void)endRecord;

/**
 * 清理掉当前录制的视频
 */
- (void)clearFile;

/**
 *取消录制，并清理掉当前录制的视频
 */
- (void)cancel;

/**
 *检测会话是否正在运行，正在运行返回YES 否则，NO
 */
- (BOOL)isSessionRunning;

@end


@protocol LBCameraDelegate <NSObject>
@optional

/** 录制完成回调
 *  param camera  获取录制的一些基本信息
 *  param success 返回录制合成成功或者失败  成功返回YES  失败返回NO
 */
- (void)didFinishExport:(LBCamera *)camera withSuccess:(BOOL)success;

@end