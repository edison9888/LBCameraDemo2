//
//  LBCameraViewController.h
//  cameraDemo
//
//  Created by 乐播 on 13-3-1.
//  Copyright (c) 2013年 乐播. All rights reserved.
//

typedef enum _CameraChannelType{
    CameraChannel_LETTER = 10,
    CameraChannel_COMMENT_MOVIE,
}CameraChannelType;


#import <UIKit/UIKit.h>
//#import "LBCamera.h"
//#import "LBPlayer.h"
//#import "LBCameraTool.h"
//#import "LBBaseController.h"
//#import "LBMarkScrollerView.h"
@interface LBCameraViewController : UIViewController<LBCameraDelegate,UIActionSheetDelegate>
{
    UILabel *labelTextTip;
    UIImageView *imageViewTip;
    UIImageView *imageViewArrow;
    UIImageView *imageBackground;
    UIImageView *bottomImageView;
    int channelType;
    
    BOOL isLightOn;
    AVCaptureDevice *device;
    UIButton *lightButton;
    UIButton *changeBtn;
    UIButton *btn_30;
    BOOL longTime;
    BOOL closeTouch;
    
}

@property(nonatomic, assign) BOOL isLightOn;

//letter
@property(nonatomic, weak) id letterDelegate;
@property(nonatomic, assign)SEL letterSelector;
@property(nonatomic, assign)SEL letterError;

- (id)initWithChannelType:(int)type;
- (void)changeWaterIndex:(NSString*)plist;
- (void)scrollViewDidScroll;
- (void)setChannelType:(int)_channelType;

@end
