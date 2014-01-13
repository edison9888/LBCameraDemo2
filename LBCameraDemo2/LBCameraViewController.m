//
//  LBCameraViewController.m
//  cameraDemo
//
//  Created by 乐播 on 13-3-1.
//  Copyright (c) 2013年 乐播. All rights reserved.
//

#import "LBCameraViewController.h"
//#import "LBMovieView.h"
//#import "UIColor+Addition.h"
//#import "LBUploadEditController.h"
#import "LBProgressBar.h"
//#import "LBMarkScrollerView.h"
//#import "LBWaterIntroControl.h"
#import "UIImage+rotate.h"
//#import "LBUploadAliSender.h"

#define MAX_Duration 6.5f
#define MIN_Time 0.05f
#define MAX_30Duration 30.0f
#define MIN_30Time 1.0f

@interface LBCameraViewController ()
{
    LBCamera * _camera;
    LBMovieView * _movieView;
    UIImageView * _mainView;
    UIImageView * _bottomView;
    
    UIButton * _nextBtn;
    UIButton * _markBtn;
    UIButton * _changeBtn;
    
    UIActivityIndicatorView * _activityView;
    
    LBProgressBar * _progress;
    
//    MBProgressHUD * _hud;
    
    NSDate * _startDate;
    double _recordTime;
    BOOL _isFinished;
    BOOL _isLoading;
    
    BOOL _hasWritedData;
    BOOL _isChangingLens;
}
@property(nonatomic,retain) NSTimer * timer;
@property(atomic,assign) BOOL shouldContinue;
@property(nonatomic,assign) UIBackgroundTaskIdentifier bgTask;
@property(nonatomic,assign) BOOL isChangingLens;
@property(nonatomic,retain) UIButton *waterBtn;
@end

@implementation LBCameraViewController
@synthesize isLightOn;
@synthesize bgTask;
@synthesize isChangingLens = _isChangingLens;
static BOOL _shouldShowGuide;
@synthesize waterBtn = _waterBtn;
//@synthesize markScrollerView = _markScrollerView;

//letter
@synthesize letterDelegate;
@synthesize letterSelector;
@synthesize letterError;

- (id)initWithChannelType:(int)type
{
    channelType = type;
    
    if(self = [super init])
    {
    }
    
    return self;
}

- (void)checkForShouldShowGuide
{
    NSUserDefaults * userDefault = [NSUserDefaults standardUserDefaults];
    if([userDefault objectForKey:@"firstInCamera"])
    {
        _shouldShowGuide = NO;
    }
    else
    {
        [userDefault setBool:YES forKey:@"firstInCamera"];
        [userDefault synchronize];
        _shouldShowGuide = YES;
    }
}

- (void)setChannelType:(int)_channelType
{
    channelType = _channelType;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        _hasWritedData = NO;
        [self checkForShouldShowGuide];
        //[self initialCamera];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willResignActive) name:UIApplicationWillResignActiveNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(willEnterForground) name:UIApplicationWillEnterForegroundNotification object:nil];
        
    }
    return self;
}


- (void)initialCamera
{
//    [LBMovieView pauseAll];
    NSDateFormatter * dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy_MM_dd_hh_mm_ss"];
    NSDate * now = [NSDate date];
    NSString * dateString = [dateFormatter stringFromDate:now];
    NSString * path = [[LBCameraTool videoPathWithName:dateString] stringByAppendingString:@".mp4"];
    
    _camera = [[LBCamera alloc] initWithFilePath:path];
    BOOL devicePositionFont = [[NSUserDefaults standardUserDefaults] boolForKey:@"DevicePositionFont"];
    if(channelType == 3 || devicePositionFont){
        _camera.cameraPosition = AVCaptureDevicePositionFront;
    }
    _camera.delegate = self;
}

- (void)clearViews
{
//    _movieView = nil;
    _mainView = nil;
    _bottomView = nil;
    _nextBtn = nil;
    _markBtn = nil;
    _changeBtn = nil;
    _progress = nil;
//    _hud = nil;
    imageViewArrow = nil;
//    self.markScrollerView = nil;
    labelTextTip = nil;
    imageViewTip = nil;
    imageViewArrow = nil;
    imageBackground = nil;
    bottomImageView = nil;
    
    device = nil;
    lightButton = nil;
    changeBtn = nil;
    btn_30 = nil;

}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearViews];
    self.timer = nil;
    if(self.bgTask)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

#pragma mark - 顶部
- (UIView *)getTopBar
{
    UIView * topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.width, 50)];
    topBar.userInteractionEnabled = YES;
    topBar.backgroundColor = [UIColor clearColor];
    
    // 取消录制按钮
    UIButton * leftButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [leftButton addTarget:self action:@selector(didClickClose) forControlEvents:UIControlEventTouchUpInside];
    [leftButton setImage:[UIImage imageNamed:@"camera_cancel"] forState:UIControlStateNormal];
    [leftButton setImage:[UIImage imageNamed:@"camera_cancel_select"] forState:UIControlStateHighlighted];
    [leftButton setFrame:CGRectMake(0, 0, 100, 100)];
    [leftButton.titleLabel setFont:[UIFont systemFontOfSize:14]];
    leftButton.center =  CGPointMake(30, topBar.height/2);
    [topBar addSubview:leftButton];
    
    //6秒--30秒切换
    changeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [changeBtn setBackgroundImage:[UIImage imageNamed:@"cameraChange"] forState:UIControlStateNormal];
    changeBtn.frame = CGRectMake(70, 10, 44, 32);
    changeBtn.centerY = topBar.height/2;
    [changeBtn setTitle:@"6秒" forState:UIControlStateNormal];
    [changeBtn.titleLabel setFont:[UIFont systemFontOfSize:14.]];
    longTime = NO;
    if(channelType != CameraChannel_LETTER){
        [changeBtn addTarget:self action:@selector(changeTime:) forControlEvents:UIControlEventTouchUpInside];
    }
    [topBar addSubview:changeBtn];
    
    //开手电筒按钮
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if ([device hasTorch]) {//判断是否有闪光灯
        lightButton = [UIButton buttonWithType:UIButtonTypeCustom];
        lightButton.frame = CGRectMake(210, 0, 44, 44);
        lightButton.centerY = leftButton.centerY;
        [lightButton setShowsTouchWhenHighlighted:YES];
        [lightButton setImage:[UIImage imageNamed:@"light.png"] forState:UIControlStateNormal];
        [lightButton setImage:[UIImage imageNamed:@"light_selected.png"] forState:UIControlStateSelected];
        [lightButton addTarget:self action:@selector(lightClicked:) forControlEvents:UIControlEventTouchUpInside];
        [topBar addSubview:lightButton];
        if ( _camera.cameraPosition == AVCaptureDevicePositionFront) {
            lightButton.hidden = YES;
        }
    }
    
    //切换前后摄像头
    UIButton * rightButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [rightButton setShowsTouchWhenHighlighted:YES];
    [rightButton addTarget:self action:@selector(didClickChangeLens:) forControlEvents:UIControlEventTouchUpInside];
    [rightButton setImage:[UIImage imageNamed:@"camera_btn_lens"] forState:UIControlStateNormal];
    //[rightButton setImage:Image(@"camera_btn_lens_select") forState:UIControlStateHighlighted];
    
    rightButton.size = CGSizeMake(100, 100);
    rightButton.center =  CGPointMake(topBar.width - 30, topBar.height/2);
    [topBar addSubview:rightButton];
    
    return topBar;
}


#pragma mark - 中部

- (void)createMainView
{
    _mainView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 50, self.view.width, 330)];
    _mainView.userInteractionEnabled = YES;
    _mainView.backgroundColor =  [UIColor colorWithRed:58.0/255 green:58.0/255 blue:58.0/255 alpha:1.0];
    //[_mainView sizeToFit];
    
    _progress = [[LBProgressBar alloc] initWithFrame:CGRectMake(0, 0, _mainView.frame.size.width, 8)];
    UIImage * progress_bg = [UIImage imageNamed:@"camera_progress_bg.png"];
    progress_bg = [progress_bg stretchableImageWithLeftCapWidth:2 topCapHeight:2];
    [_progress setBackgroundImage:progress_bg];
    UIImage * progress_fg = [UIImage imageNamed:@"camera_progress_fg.png"];
    progress_fg = [progress_fg stretchableImageWithLeftCapWidth:2 topCapHeight:2];
    [_progress setProgressImage:progress_fg];
    [_mainView addSubview:_progress];
    
    CALayer * topLine = [CALayer layer];
    topLine.frame = CGRectMake(0, _progress.bottom, _mainView.width, 1);
    topLine.backgroundColor = [UIColor blackColor].CGColor;
    [_mainView.layer addSublayer:topLine];
    
    _movieView = [[LBMovieView alloc] initWithFrame:CGRectMake(0, _progress.bottom+1, _mainView.width, _mainView.width)];
    [_mainView addSubview:_movieView];
    
    [_mainView addSubview:_camera.cameraView];
    _camera.cameraView.frame = _movieView.frame;
    
    CALayer * bottomLine = [CALayer layer];
    bottomLine.frame = CGRectMake(0, _movieView.bottom, _mainView.width, 1);
    bottomLine.backgroundColor = [UIColor blackColor].CGColor;
    [_mainView.layer addSublayer:bottomLine];
    
    if(_shouldShowGuide)
    {
        UIView * instructionView = [[UIView alloc] initWithFrame:CGRectMake(0, 30, _mainView.width, 80)];
        instructionView.backgroundColor = [UIColor clearColor];
        [_mainView addSubview:instructionView];
        
//        _hud = [[MBProgressHUD alloc] initWithView:instructionView];
        //_hud.center = CGPointMake(instructionView.width/2, 40);
//        [instructionView addSubview:_hud];
//        _hud.mode = MBProgressHUDModeText;
//        _hud.delegate = self;
    }
    
    if(![[NSUserDefaults standardUserDefaults] objectForKey:@"newPerson"])
    {
        UIView *viewTip = [[UIView alloc] initWithFrame:_mainView.bounds];
        [viewTip setUserInteractionEnabled:YES];
        [viewTip setTag:111];
        [viewTip setBackgroundColor:[UIColor clearColor]];
        viewTip.center = _mainView.center;
        viewTip.top = viewTip.top - 40;
        [_mainView addSubview:viewTip];
        imageViewTip = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"frist_one"]];
        [imageViewTip setFrame:CGRectMake(73, 100, 173, 184)];
        imageViewTip.center = viewTip.center;
        [imageViewTip setUserInteractionEnabled:YES];
        [viewTip addSubview:imageViewTip];
        
        imageBackground = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100,139, 30)];
        [imageBackground setUserInteractionEnabled:YES];
        [imageBackground setImage:[[UIImage imageNamed:@"fristPage_view"] stretchableImageWithLeftCapWidth:13 topCapHeight:12]];
        //[viewTip addSubview:imageBackground];
        imageBackground.centerX = viewTip.centerX;
        imageBackground.bottom =  imageViewTip.top  - 20;
        
        labelTextTip = [[UILabel alloc] initWithFrame:CGRectMake(5, 0, imageBackground.width - 10, imageBackground.height)];
        [labelTextTip setUserInteractionEnabled:YES];
        [labelTextTip setTextAlignment:NSTextAlignmentCenter];
        [labelTextTip setFont:[UIFont systemFontOfSize:14]];
        [labelTextTip setTextColor:[UIColor whiteColor]];
        //[labelTextTip setShadowColor:[UIColor blackColor]];
        //[labelTextTip setShadowOffset:CGSizeMake(0, 1)];
        [labelTextTip setBackgroundColor:[UIColor clearColor]];
        [labelTextTip setText:@"按住屏幕，开始拍摄"];
        //[imageBackground addSubview:labelTextTip];
        
        
        imageViewArrow = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 7, 9)];
        [imageViewArrow setUserInteractionEnabled:YES];
        [imageViewArrow setImage:[UIImage imageNamed:@"fristPage_view_arrow.png"]];
        [imageViewArrow setTop:imageViewTip.top  - 21];
        [imageViewArrow setCenterX:imageViewTip.centerX];
        //[viewTip addSubview:imageViewArrow];
        [[NSUserDefaults standardUserDefaults] setObject:@"FirstTouch" forKey:@"FirstTouch"];    }
    [self.view addSubview:_mainView];
}

#pragma mark - 底部

- (void)createBottomView
{
    //UIImage * img = Image(@"camera_bottom.png");
    UIImageView * imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, _mainView.bottom, self.view.width, self.view.height-_mainView.bottom)];
    imageView.backgroundColor =  [UIColor colorWithRed:58.0/255 green:58.0/255 blue:58.0/255 alpha:1.0];;
    imageView.userInteractionEnabled = YES;
    [self.view addSubview:imageView];
    _bottomView = imageView;
    
    _markBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //_markBtn.highlighted = YES;
    [_markBtn setImage:[UIImage imageNamed:@"camera_btn_mark"] forState:UIControlStateNormal];
    [_markBtn setImage:[UIImage imageNamed:@"camera_btn_mark_select"] forState:UIControlStateHighlighted];
    [_markBtn sizeToFit];
    [_markBtn addTarget:self action:@selector(didClickMark:) forControlEvents:UIControlEventTouchUpInside];
    int space = _bottomView.frame.size.height-22-_markBtn.height ;
    _markBtn.frame = CGRectMake(_bottomView.width-_markBtn.width - 64 , space - 30, 70, 70);
    [_bottomView addSubview:_markBtn];
    _markBtn.hidden = YES;
    
    btn_30 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn_30.frame = CGRectMake(_bottomView.width - 56 - 10 , space - 20, 63, 63);
    btn_30.center = CGPointMake(self.view.centerX, _markBtn.centerY);
    [btn_30 setBackgroundImage:[UIImage imageNamed:@"camera_30.png"] forState:UIControlStateNormal];
    [btn_30 setBackgroundImage:[UIImage imageNamed:@"camera_30_selected.png"] forState:UIControlStateSelected];
    [btn_30 addTarget:self action:@selector(camera_30:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomView addSubview:btn_30];
    btn_30.hidden = YES;
    
    //    _waterBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    //    [_waterBtn setImage:[UIImage imageNamed:@"camera_btn_mark"] forState:UIControlStateNormal];
    //    [_waterBtn sizeToFit];
    //    [_waterBtn setFrame:CGRectMake(22, space, _waterBtn.width, _waterBtn.height)];
    //    [_waterBtn addTarget:self action:@selector(didClickWater:) forControlEvents:UIControlEventTouchUpInside];
    //    [_bottomView addSubview:_waterBtn];
    
    _activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityView.center = _markBtn.center;
    [_bottomView addSubview:_activityView];
    _activityView.hidden = YES;
    
    CGSize size = CGSizeMake(136, 36);
    _nextBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _nextBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    //[_nextBtn setTitleShadowColor:[UIColor blackColor] forState:UIControlStateNormal];
    //_nextBtn.titleLabel.shadowOffset = CGSizeMake(0, 1);
    UIImage * nextImg = [UIImage imageNamed:@"camera_btn_publish.png"];
    nextImg = [nextImg stretchableImageWithLeftCapWidth:5 topCapHeight:5];
    UIImage * nextImg_select = [UIImage imageNamed:@"camera_btn_publish_select.png"];
    nextImg_select = [nextImg_select stretchableImageWithLeftCapWidth:5 topCapHeight:5];
    [_nextBtn setBackgroundImage:nextImg forState:UIControlStateNormal];
    [_nextBtn setBackgroundImage:nextImg_select forState:UIControlStateHighlighted];
    [_nextBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    if(channelType==CameraChannel_LETTER){
        [_nextBtn setTitle:@"发送私信" forState:UIControlStateNormal];
    }
    else{
        [_nextBtn setTitle:@"下一步" forState:UIControlStateNormal];
    }
    [_nextBtn addTarget:self action:@selector(didClickNext:) forControlEvents:UIControlEventTouchUpInside];
    _nextBtn.frame = CGRectMake(0, _bottomView.height-22-size.height, size.width, size.height);
    _nextBtn.centerX = _bottomView.width/2;
    [_bottomView addSubview:_nextBtn];
    _nextBtn.hidden = YES;
    
    bottomImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"camTip_6s.png"]];
    bottomImageView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width-174)/2, (self.view.height-_mainView.bottom-23)/2, 174, 23);
    [_bottomView addSubview:bottomImageView];
}
#pragma mark -

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES];
    
    [self initialCamera];
    
    self.view.backgroundColor =  [UIColor colorWithRed:58.0/255 green:58.0/255 blue:58.0/255 alpha:1.0];;
    self.view.userInteractionEnabled = YES;
    UIView * topBar = [self getTopBar];
    [self.view addSubview:topBar];
    [self createMainView];
    [self createBottomView];
    [self instanceLight];
    [self performSelector:@selector(start) withObject:nil afterDelay:0.5];
    
}

- (void)instanceLight{
    //AVCaptureDevice代表抽象的硬件设备
    // 找到一个合适的AVCaptureDevice
    device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (![device hasTorch]) {//判断是否有闪光灯
        lightButton.hidden = YES;
    }
    
    isLightOn = NO;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    
    [self clearViews];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if(_isFinished)
        [_movieView pause];
    else
    {
        [self stopRecord];
        [_camera endCapture];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES];
    
    if(_isFinished)
        [self playCapture];
    else
    {
        [_camera startCapture];
    }
}

- (void)lightClicked:(UIButton *)sender{
    isLightOn = 1-isLightOn;
    [lightButton setSelected:isLightOn];
    if (isLightOn) {
        [self turnOnLed:YES];
    }else{
        [self turnOffLed:YES];
    }
}

//打开手电筒
-(void) turnOnLed:(bool)update
{
    [device lockForConfiguration:nil];
    [device setTorchMode:AVCaptureTorchModeOn];
    [device unlockForConfiguration];
}

//关闭手电筒
-(void) turnOffLed:(bool)update
{
    if (![device hasTorch]) {//判断是否有闪光灯
        return;
    }
    [device lockForConfiguration:nil];
    [device setTorchMode: AVCaptureTorchModeOff];
    [device unlockForConfiguration];
}

- (void)playCapture
{
    if(_isFinished)
    {
        [_mainView bringSubviewToFront:_movieView];
        NSString * path = [_camera videoPath];
        if([LBCameraTool fileExist:path])
        {
            [_movieView setPlayerURL:[NSURL fileURLWithPath:path]];
            [_movieView play];
        }
        else
        {
            NSLog(@"no player path in playCapture");
        }
    }
}

- (void)stop
{
    [_camera endRecord];
    [_camera endCapture];
}

- (void)start
{
    [_camera startCapture];
    //    if(_shouldShowGuide)
    //    {
    //        [_hud show:YES];
    //        _hud.labelText = @"按住屏幕，开始拍摄";
    //    }
}

- (void)startRecord
{
    if (_isFinished == YES || _isLoading == YES || ![_camera isSessionRunning])
        return;
    [_camera startRecord];
    _hasWritedData = YES;
    _startDate = [[NSDate date] copy];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1/200.0f target:self selector:@selector(step) userInfo:nil repeats:YES];
    _isLoading = YES;
    
    /*
     if (longTime) {
     return;
     }
     */
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"FirstTouch"])
    {
        [labelTextTip setText:@"松开屏幕，暂停拍摄"];
        [imageViewTip setImage:[UIImage imageNamed:@"frist_two"]];
        [imageViewArrow setHidden:YES];
    }
    
    //[_waterBtn setHidden:YES];
    
    //    LBWaterIntroControl *obj = (LBWaterIntroControl*)[_mainView viewWithTag:101];
    //    if(obj)
    //    {
    //        [obj setEnableWater:NO];
    //    }
    
}

- (void)stopRecord
{
    if (_isFinished == YES || _isLoading == NO)
        return;
    _isLoading = NO;
    
    if (self.timer.isValid)
    {
        [self.timer invalidate];
        [_camera pauseRecord];
        float endFloat = [[NSDate date] timeIntervalSinceDate:_startDate];
        _recordTime += endFloat;
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"FirstTouch"])
    {
        [labelTextTip setText:@"让我们换个场景，继续拍摄"];
        [imageViewTip setImage:[UIImage imageNamed:@"frist_three"]];
        [labelTextTip sizeToFit];
        [labelTextTip setTop:5];
        [imageViewArrow setHidden:NO];
        [imageViewArrow setTop:imageViewTip.top  - 21];
        [imageViewArrow setCenterX:imageViewTip.centerX];
        [labelTextTip setTextAlignment:NSTextAlignmentCenter];
        [imageBackground setWidth:labelTextTip.width+10];
        [imageBackground setCenterX:_mainView.centerX];
    }
}

#pragma mark Touch

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (closeTouch) {
        [bottomImageView setHidden:YES];
        return;
    }
    btn_30.hidden = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(touchEnd) object:nil];
    [changeBtn setEnabled:NO];
    NSLog(@"touch");
    if(_isChangingLens)
    {
        NSLog(@"_isChangingLens");
        _shouldContinue = YES;
    }
    else
    {
        [self startRecord];
        //        if(_shouldShowGuide)
        //        {
        //            [_hud hide:YES];
        //        }
        //[changeBtn setTitle:@"6秒" forState:UIControlStateNormal];
        //longTime = NO;
        //btn_30.hidden = YES;
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (closeTouch) {
        return;
    }
    double endFloat = [[NSDate date] timeIntervalSinceDate:_startDate];
    if(endFloat<MIN_Time)
    {
        [self performSelector:@selector(touchEnd) withObject:nil afterDelay:MIN_Time-endFloat];
    }
    else
    {
        [self touchEnd];
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    double endFloat = [[NSDate date] timeIntervalSinceDate:_startDate];
    if(endFloat < MIN_Time)
    {
        [self performSelector:@selector(touchEnd) withObject:nil afterDelay:MIN_Time-endFloat];
    }
    else
    {
        [self touchEnd];
    }
    //_shouldContinue = NO;
    //[self stopRecord];
}

- (void)touchEnd
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:_cmd object:nil];
    _shouldContinue = NO;
    [self stopRecord];
    //    if(_shouldShowGuide && _isFinished == NO)
    //    {
    //        [_hud show:YES];
    //        _hud.labelText = @"按住屏幕，继续拍摄";
    //    }
}

- (void)step
{
    double time = [_camera writedDuration];
    //double endFloat = [[NSDate date] timeIntervalSinceDate:_startDate];
    //double totalTime = _recordTime + endFloat;
    double totalTime = time;
    NSLog(@"touchTime:%f ,audiotime:%f",totalTime,time);
    if (longTime) {
        _progress.progress =  totalTime/MAX_30Duration;
        if (totalTime >= 1.0f && totalTime <= MAX_30Duration)
        {
            btn_30.hidden = NO;
            //[btn_30 setTitle:@"结束" forState:UIControlStateNormal];
            [btn_30 setBackgroundImage:[UIImage imageNamed:@"camera_30_finished.png"] forState:UIControlStateNormal];
            if(bottomImageView && [bottomImageView isDescendantOfView:_bottomView])
            {
                [bottomImageView removeFromSuperview];
            }
        }
        else if(MAX_30Duration - totalTime <= 0.0f)
        {
            [self didFinishCapture];
        }
    } else {
        _progress.progress =  totalTime/MAX_Duration;
        if (totalTime >= 1.0f && totalTime <= MAX_Duration)
        {
            _markBtn.hidden = NO;
            
            if(bottomImageView && [bottomImageView isDescendantOfView:_bottomView])
            {
                [bottomImageView removeFromSuperview];
            }
            
        }
        else if(MAX_Duration - totalTime <= 0.0f)
        {
            [self didFinishCapture];
        }
    }
    
    //    static BOOL hasShowText = NO;
    //    if(_shouldShowGuide && hasShowText==NO && totalTime>=2.0 )
    //    {
    //        _hud.labelText = @"松开，暂停拍摄";
    //        [_hud show:YES];
    //        hasShowText = YES;
    //    }
}

- (void)didFinishCapture
{
    btn_30.hidden = YES;
    _markBtn.hidden = YES;
    [_activityView startAnimating];
    [self.navigationItem setTitle:@"回放"];
    [self.navigationItem setRightBarButtonItem:nil animated:YES];
    if (self.timer.isValid)
        [self.timer invalidate];
    _isFinished = YES;
    _shouldShowGuide = NO;
    [self stop];
}

- (void)saveToMovieDirectory
{
    [LBCameraTool moveToFormalPath:[_camera videoPath]];
    [LBCameraTool moveToFormalPath:[LBCameraTool getThumbPathWithPath:_camera.videoPath]];
}

#pragma mark IBAction
- (void)setIsChangingLens:(BOOL)sender
{
    _isChangingLens = sender;
}

- (void)didClickChangeLens:(UIButton *)sender
{
    if(_isFinished)
        return;
    if(_isChangingLens == YES)
        return;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(setIsChangingLens:) object:NO];
    _isChangingLens = YES;
    [self performSelector:@selector(setIsChangingLens:) withObject:NO afterDelay:1];
    self.shouldContinue = self.timer.isValid;
    if(self.shouldContinue)
        [self stopRecord];
    if(_camera.cameraPosition == AVCaptureDevicePositionUnspecified || _camera.cameraPosition == AVCaptureDevicePositionBack)
    {
        lightButton.hidden = YES;
        [self willResignActive];
        _camera.cameraPosition = AVCaptureDevicePositionFront;
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DevicePositionFont"];
    }
    else
    {
        lightButton.hidden = NO;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"DevicePositionFont"];
        _camera.cameraPosition = AVCaptureDevicePositionBack;
    }
    if(self.shouldContinue)
        [self performSelector:@selector(startRecord) withObject:nil afterDelay:0.5];
}

- (void)setLocalMark
{
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"FirstTouch"])
    {
        [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"FirstTouch"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [[NSUserDefaults standardUserDefaults] setObject:@"newPerson" forKey:@"newPerson"];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if([[NSUserDefaults standardUserDefaults] objectForKey:@"newPerson"] && [_mainView viewWithTag:111])
    {
        [[_mainView viewWithTag:111] setHidden:YES];
    }
    
}

- (void)didClickClose
{
    [self setLocalMark];
//    [Global clearPlayStatus];
    
    if(_hasWritedData)
    {
        UIActionSheet * sheet ;
        if(channelType == CameraChannel_LETTER){
            sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"取消发送" otherButtonTitles:nil];
        }
        else{
            sheet = [[UIActionSheet alloc] initWithTitle:@"" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:@"取消发布" otherButtonTitles:nil];
        }
        [sheet showInView:self.view];
    }
    else
    {
        [_camera cancel];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
//
#define waterViewHeight 100
//- (void)didClickWater:(UIButton *)sender
//{
//    if(!_markScrollerView)
//    {
//        self.markScrollerView = [[LBMarkScrollerView alloc] initWithFrame:CGRectMake(0, _mainView.height - waterViewHeight, _mainView.width, waterViewHeight) delegate:self];
//    }
//    
//    if ([_markScrollerView isDescendantOfView:_mainView]) {
//        [_markScrollerView removeFromSuperview];
//    }
//    else
//    {
//        [_mainView addSubview:_markScrollerView];
//    }
//    
//}

- (void)changeWaterIndex:(NSString*)plist
{
    UIView *obj = [_mainView viewWithTag:101];
    if(obj)
    {
        [obj removeFromSuperview];
    }
    
//    LBWaterIntroControl *view = [[LBWaterIntroControl alloc] initWithFrame:CGRectMake(0, _mainView.height - waterViewHeight, screenSize().width, waterViewHeight) delegate:self key:plist];
//    [view setTag:101];
//    [view setPageControl:YES];
//    [_camera setWaterImage:[self convertViewToImage:view]];
//    [view setPageControl:NO];
//    
//    [_mainView addSubview:view];
}

- (void)scrollViewDidScroll
{
    id obj = [_mainView viewWithTag:101];
    if(obj)
    {
        if(obj && [obj respondsToSelector:@selector(setPageControl:)])
        {
//            [obj setPageControl:YES];
        }
        [_camera setWaterImage:[self convertViewToImage:obj]];
        if(obj && [obj respondsToSelector:@selector(setPageControl:)])
        {
//            [obj setPageControl:NO];
        }
    }
}

//
//#define ONE_HALF             (1 << (SCALEBITS - 1))
//#define FIX(x)               ((int) ((x) * (1L<<SCALEBITS) + 0.5))
//typedef unsigned char        uint8_t;
//void rgb24_to_yuv420p(uint8_t *lum, uint8_t *cb, uint8_t *cr, uint8_t *src, int width, int height)
//{
//    int wrap, wrap3, x, y;
//    int r, g, b, r1, g1, b1;
//    uint8_t *p;
//    wrap = width;
//    wrap3 = width * 3;
//    p = src;
//    for (y = 0; y < height; y += 2)
//    {
//        for (x = 0; x < width; x += 2)
//        {
//            r = p[0];
//            g = p[1];
//            b = p[2];
//            r1 = r;
//            g1 = g;
//            b1 = b;
//            lum[0] = (FIX(0.29900) * r + FIX(0.58700) * g +FIX(0.11400) * b + ONE_HALF) >> SCALEBITS;
//            r = p[3];
//            g = p[4];
//            b = p[5];
//            r1 += r;
//            g1 += g;
//            b1 += b;
//            lum[1] = (FIX(0.29900) * r + FIX(0.58700) * g +FIX(0.11400) * b + ONE_HALF) >> SCALEBITS;
//            p += wrap3;
//            lum += wrap;
//            r = p[0];
//            g = p[1];
//            b = p[2];
//            r1 += r;
//            g1 += g;
//            b1 += b;
//            lum[0] = (FIX(0.29900) * r + FIX(0.58700) * g +FIX(0.11400) * b + ONE_HALF) >> SCALEBITS;
//            r = p[3];
//            g = p[4];
//            b = p[5];
//            r1 += r;
//            g1 += g;
//            b1 += b;
//            lum[1] = (FIX(0.29900) * r + FIX(0.58700) * g +FIX(0.11400) * b + ONE_HALF) >> SCALEBITS;
//
//            cb[0] = (((- FIX(0.16874) * r1 - FIX(0.33126) * g1 +
//                       FIX(0.50000) * b1 + 4 * ONE_HALF - 1) >> (SCALEBITS + 2)) + 128);
//            cr[0] = (((FIX(0.50000) * r1 - FIX(0.41869) * g1 -
//                       FIX(0.08131) * b1 + 4 * ONE_HALF - 1) >> (SCALEBITS + 2)) + 128);
//            cb++;
//            cr++;
//            p += -wrap3+2 * 3;
//            lum += -wrap + 2;
//        }
//        p += wrap3;
//        lum += wrap;
//    }
//}

- (UIImage*)convertViewToImage:(UIView*)v{
    UIGraphicsBeginImageContextWithOptions(v.bounds.size, NO, 0.0);
    [v.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return [image rotateImage: UIImageOrientationLeft];
}

- (void)didClickMark:(UIButton *)sender
{
    [sender setHidden:YES];
    //[_waterBtn setHidden:YES];
    [self setLocalMark];
    [self didFinishCapture];
    
}

- (void)camera_30:(id)sender
{
    double time = [_camera writedDuration];
    if (time == 0.0) {
        [bottomImageView setHidden:YES];
        btn_30.hidden = YES;
        [changeBtn setEnabled:NO];
        [self startRecord];
        closeTouch = YES;
    }
    else if (time > 1.0)
    {
        [sender setHidden:YES];
        [self didFinishCapture];
        closeTouch = NO;
    }
}

- (void)didClickNext:(UIButton *)sender
{
    [self setLocalMark];
    if(channelType == CameraChannel_LETTER){
        if(self.letterDelegate && self.letterSelector)
        {
            if([self.letterDelegate respondsToSelector:self.letterSelector])
            {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                [self.letterDelegate performSelector:self.letterSelector withObject:_camera.videoPath];
#pragma clang diagnostic pop
            }
        }
        //[_camera cancel];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
//        LBUploadEditController * controller = [[LBUploadEditController alloc] initWithMoviePath:_camera.videoPath style:channelType];
//        if(channelType)
//        {
//            [controller setStyle:channelType];
//        }
//        [self.navigationController pushViewController:controller animated:YES];
    }
}


#pragma mark LBCameraDelegate

- (void)didFinishExport:(LBCamera *)camera withSuccess:(BOOL)success
{
    [_activityView stopAnimating];
    _nextBtn.hidden = NO;
    _markBtn.hidden = YES;
    [self playCapture];
}

#pragma mark NSNotification

- (void)willEnterForground
{
    if(self.bgTask)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
}

- (void)willResignActive{
    isLightOn = 0;
    [lightButton setSelected:isLightOn];
    [self turnOffLed:YES];
}

- (void)didEnterBackground
{
    if (self.timer.isValid)
        [self.timer invalidate];
    if(self.bgTask)
    {
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }
    self.bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        if(!_isFinished)
        {
            [self stopRecord];
            [_camera cancel];
            [self dismissViewControllerAnimated:YES completion:nil];
        }
        [[UIApplication sharedApplication] endBackgroundTask:self.bgTask];
        self.bgTask = UIBackgroundTaskInvalid;
    }];
}

//#pragma mark LBWaterIntroViewDelegate
//- (void)imageTapped
//{
//    //self.navigationController
//}
//
//- (void)localMarkTapped
//{}
//
//- (void)descriptionLabelTapped
//{}

- (void)changeTime:(id)sender
{
    UIButton *btn = sender;
    if (longTime == NO) {
        [btn setTitle:@"30秒" forState:UIControlStateNormal];
        longTime = YES;
        btn_30.hidden = NO;
        bottomImageView.image = [UIImage imageNamed:@"camTip.png"];
        bottomImageView.frame = CGRectMake(btn_30.right + 10, btn.top+10, 108, 18);
    }
    else
    {
        [btn setTitle:@"6秒" forState:UIControlStateNormal];
        longTime = NO;
        btn_30.hidden = YES;
        bottomImageView.image = [UIImage imageNamed:@"camTip_6s.png"];
        bottomImageView.frame = CGRectMake(([UIScreen mainScreen].bounds.size.width-174)/2, (self.view.height-_mainView.bottom-23)/2, 174, 23);
    }
}

#pragma mark MBProgressHUDDelegate
//- (void)hudWasHidden:(MBProgressHUD *)hud
//{
//    
//}

#pragma mark UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"index ：%d",buttonIndex);
    if(buttonIndex == 0)
    {
        if(self.timer.isValid)
            [self.timer invalidate];
        [_camera cancel];
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}
@end
