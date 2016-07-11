//
//  TEVideoFrame.h
//  FFmpeg_Video
//
//  Created by offcn_c on 16/5/10.
//  Copyright © 2016年 offcn_c. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

@interface KxAudioFrame : NSObject
@property (readonly) UInt32             numOutputChannels;
@property (readonly) Float64            samplingRate;
@property (readonly) UInt32             numBytesPerSample;
@property (readwrite) Float32           outputVolume;
@property (readonly) BOOL               playing;
@property (readonly, strong) NSString   *audioRoute;
@end


@interface TEVideoFrame : NSObject
{
    AVFormatContext *pFormatContext;
    AVCodecContext *pCodecContext;
    AVCodecContext *audioCodeContext;
    AVFrame *pFrame;
    AVFrame *audioFrame;
    AVPacket packet;
    AVPicture picture;
    int videoStream;
    int audioStream;
    struct SwsContext *img_convert_context;
    UIImage *currentImage;
    double duration;
}

/*最新的解码图像**/
@property (nonatomic, readonly) UIImage *currentImage;

/*视频帧的尺寸*/
@property (nonatomic, readonly) int sourceWidth, sourceHeight;

/*输出图片的尺寸**/
@property (nonatomic) int outputWidth, outputHeight;

/*视频的持续时间**/
@property (nonatomic, readonly) double duration;

/*现在视频的时间**/
@property (nonatomic, readonly) double currentTime;

@property (nonatomic, readonly) BOOL isNetwork;

/*初始化视频路径或地址 将输出内容作为source的内容**/
- (instancetype)initWithVideo:(NSString *)moviePath;
/*从视频流中读取到下一帧，如果没有读到帧的话返回false**/
- (BOOL) stepFrame;
/*跳到这个时间点的关键帧**/
- (void)seekTime:(double)seconds;

@end
