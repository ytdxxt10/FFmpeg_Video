//
//  ViewController.m
//  FFmpeg_Video
//
//  Created by offcn_c on 16/5/10.
//  Copyright © 2016年 offcn_c. All rights reserved.
//

#import "ViewController.h"
#import "TEVideoFrame.h"

@interface ViewController ()
{
    float lastFrameTime;
}
@property (weak, nonatomic) IBOutlet UIImageView *videoImageView;
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIButton *timeButton;
@property (weak, nonatomic) IBOutlet UILabel *fpsLabel;


@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *path = [[NSBundle mainBundle]pathForResource:@"sophie" ofType:@"mov"];
    path = @"http://livecdn.cdbs.com.cn/fmvideo.flv";
    self.video = [[TEVideoFrame alloc]initWithVideo:path];
    
    NSLog(@"video duration: %f\n video size: %d × %d",_video.duration,_video.sourceWidth,_video.sourceHeight);
    _videoImageView.image = _video.currentImage;
    

}


- (IBAction)playButtonClick:(UIButton *)sender {
    _playButton.enabled = false;
    lastFrameTime = -1;
    
    //跳到0s
    [_video seekTime:0.0];
    [NSTimer scheduledTimerWithTimeInterval:1.0/30 target:self selector:@selector(displayNextFrame:) userInfo:nil repeats:true];
}

- (IBAction)timeButtonClick:(UIButton *)sender {
    NSLog(@"current time: %f s",_video.currentTime);
}

#define LERP(A,B,C) ((A)*(1.0-C)+(B)*C)

- (void)displayNextFrame:(NSTimer *)timer {
    NSTimeInterval startTime = [NSDate timeIntervalSinceReferenceDate];
    
    if (![_video stepFrame]) {
        [timer invalidate];
        [_playButton setEnabled:YES];
        return;
    }
    _videoImageView.image = _video.currentImage;
    float frameTime = 1.0/([NSDate timeIntervalSinceReferenceDate] - startTime);
    if (lastFrameTime < 0) {
        lastFrameTime = frameTime;
    } else {
        lastFrameTime = LERP(frameTime, lastFrameTime, 0.8);
    }
    
    [_fpsLabel setText:[NSString stringWithFormat:@"%.0f",lastFrameTime]];

}

- (BOOL)prefersStatusBarHidden{return true;}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
