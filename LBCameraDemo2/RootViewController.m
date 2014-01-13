//
//  RootViewController.m
//  LeBoCameraDemo
//
//  Created by 乐播 on 14-1-8.
//  Copyright (c) 2014年 Hongli. All rights reserved.
//

#import "RootViewController.h"
#import "LBCameraViewController.h"
@interface RootViewController ()

@end

@implementation RootViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    UIButton *cameraBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    cameraBtn.frame = CGRectMake(100, 100, 100, 44);
    [cameraBtn setTitle:@"camera" forState:UIControlStateNormal];
    [cameraBtn addTarget:self action:@selector(cameraClicked:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:cameraBtn];
}

- (void)cameraClicked:(UIButton *)sender{
    LBCameraViewController *cameraVC = [[LBCameraViewController alloc] initWithChannelType:0];
    [self presentViewController:cameraVC animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
