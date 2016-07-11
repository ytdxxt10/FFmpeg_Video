//
//  TEVideoFrame.m
//  FFmpeg_Video
//
//  Created by offcn_c on 16/5/10.
//  Copyright © 2016年 offcn_c. All rights reserved.
//

#import "TEVideoFrame.h"
#include "libswscale/swscale.h"
@interface TEVideoFrame()
{
    

}
@end

@implementation TEVideoFrame

- (instancetype)initWithVideo:(NSString *)moviePath
{
    if (!(self = [super init])) {
        return nil;
    }
    _isNetwork = isNetworkPath(moviePath);
    if (_isNetwork) {
        avformat_network_init();
    }
    AVCodec  *pCodec;
//    AVCodec *audioCodec;
    
    //注册所有的文件格式和编解码器
    avcodec_register_all();
    av_register_all();
    
    //打开视频文件
    /*打开输入流，四个参数1.获得文件名，这个函数读取文件的头部并且把信息保存到AVFormatContext结构体中，，fmt:如果非空,这个参数强制一个特定的输入格式。否则自动适应格式
     ##注释  将文件格式的上下文传递到AVFormatContext类型的结构体formatCtx中
     */
    
    if (avformat_open_input(&pFormatContext, [moviePath cStringUsingEncoding:NSASCIIStringEncoding], NULL, NULL)) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't open file\n");
        goto initError;
    }
    //读取数据包获取流媒体文件的信息，每个AVStream存储一个视频/音频流的相关数据；每个AVStream对应一个AVCodecContext，存储该视频/音频流使用解码方式的相关数据 ##注释 查找文件中流的信息
    if (avformat_find_stream_info(pFormatContext, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Couldn't find a video stream in the input");
        goto initError;
    }
    
    //find the first video stream
    if ((videoStream = av_find_best_stream(pFormatContext, AVMEDIA_TYPE_VIDEO, -1, -1, &pCodec, 0)) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot find a video stream in the input file\n");
        goto initError;
    }
    
    // find the audio stream;
//    if ((audioStream = av_find_best_stream(pFormatContext, AVMEDIA_TYPE_AUDIO, -1, -1, &pCodec, 0))<0) {
//        av_log(NULL, AV_LOG_ERROR, "Cannot find a audio stream in the input file\n");
//    }
    
    //Get a pointer to the codec context for the video stream
    pCodecContext = pFormatContext->streams[videoStream]->codec;
    
//    audioCodeContext = pFormatContext->streams[audioStream]->codec;
    
    //find the decoder for the video stream
    pCodec = avcodec_find_decoder(pCodecContext->codec_id);
//    audioCodec = avcodec_find_decoder(audioCodeContext->codec_id);
    
    if (pCodec == NULL) {
        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
        goto initError;
    }
//    if (audioCodec == NULL) {
//        av_log(NULL, AV_LOG_ERROR, "Unsupported codec!\n");
//        goto initError;
//    }
//    
    //open codec
    if (avcodec_open2(pCodecContext, pCodec, NULL) < 0) {
        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
        goto initError;
    }
    
//    if (avcodec_open2(audioCodeContext, audioCodec, NULL)<0) {
//        av_log(NULL, AV_LOG_ERROR, "Cannot open video decoder\n");
//    }
    
    pFrame = av_frame_alloc();
//    audioFrame = av_frame_alloc();
    
    
    _outputWidth = pCodecContext->width;
    self.outputHeight = pCodecContext->height;
    return self;
    
initError:
    return nil;
}

- (void)seekTime:(double)seconds
{
    AVRational timeBase = pFormatContext->streams[videoStream]->time_base;
    int64_t targetFrame = (int64_t)((double)timeBase.den/timeBase.num *seconds);
    avformat_seek_file(pFormatContext, videoStream, targetFrame, targetFrame, targetFrame, AVSEEK_FLAG_FRAME);
    avcodec_flush_buffers(pCodecContext);

}

- (BOOL)stepFrame
{
    //AVPacket packet;
    int frameFinished = 0;
    while (!frameFinished && av_read_frame(pFormatContext, &packet)>=0) {
        //is this a packet from the video stream
        if (packet.stream_index == videoStream) {
            avcodec_decode_video2(pCodecContext, pFrame, &frameFinished, &packet);
        }
    }
    return frameFinished != 0;
}
static BOOL isNetworkPath (NSString *path)
{
    NSRange r = [path rangeOfString:@":"];
    if (r.location == NSNotFound) {
        return NO;
    }
    NSString *scheme = [path substringFromIndex:r.length];
    if ([scheme isEqualToString:@"file"]) {
        return NO;
    }
    
    return YES;
}

- (UIImage *)currentImage
{
    if (!pFrame->data[0]) {
        return nil;
    }
    [self convertFrameToRGB];
    return [self imageFromAVPicture:picture width:_outputWidth height:_outputHeight];
}

-(double)duration
{
    return (double)pFormatContext->duration/AV_TIME_BASE;

}

- (double)currentTime
{
    AVRational timeBase = pFormatContext->streams[videoStream]->time_base;
    return packet.pts * (double)timeBase.num / timeBase.den;
}

- (int)sourceWidth {
    return pCodecContext->width;
}

- (int)sourceHeight {
    return pCodecContext->height;

}
- (void)convertFrameToRGB
    {
        sws_scale(img_convert_context, pFrame->data, pFrame->linesize, 0, pCodecContext->height, picture.data, picture.linesize);

}

-(UIImage *)imageFromAVPicture:(AVPicture)pict width:(int)width height:(int)height {
    
    CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
    CFDataRef data = CFDataCreateWithBytesNoCopy(kCFAllocatorDefault,pict.data[0],pict.linesize[0] * height,kCFAllocatorNull);
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData(data);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef cgImage = CGImageCreate(width, height, 8, 24, pict.linesize[0], colorSpace, bitmapInfo, provider, NULL, NO, kCGRenderingIntentDefault);
    CGColorSpaceRelease(colorSpace);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CFRelease(data);
    return image;
}
-(void)setOutputWidth:(int)newValue {
    if (_outputWidth == newValue) return;
    _outputWidth = newValue;
    [self setupScaler];
}

-(void)setOutputHeight:(int)newValue {
    if (_outputHeight == newValue) return;
    _outputHeight = newValue;
    [self setupScaler];
}

-(void)setupScaler {
    
    // Release old picture and scaler
    avpicture_free(&picture);
    sws_freeContext(img_convert_context);
    
    // Allocate RGB picture
    avpicture_alloc(&picture, AV_PIX_FMT_RGB24, _outputWidth, _outputHeight);
    
    // Setup scaler
    static int sws_flags =  SWS_FAST_BILINEAR;
    img_convert_context = sws_getContext(pCodecContext->width,
                                     pCodecContext->height,
                                     pCodecContext->pix_fmt,
                                     _outputWidth,
                                     _outputHeight,
                                     AV_PIX_FMT_RGB24,
                                     sws_flags, NULL, NULL, NULL);
}



-(void)dealloc
{
    sws_freeContext(img_convert_context);
    
    av_free(pFrame);
    
    if (pCodecContext) {
        avcodec_close(pCodecContext);
    }
    
    if (pFormatContext) {
        avformat_close_input(&pFormatContext);
    }

}
@end
