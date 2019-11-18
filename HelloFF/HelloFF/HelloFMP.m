//
//  HelloFMP.m
//  HelloFF
//
//  Created by 任前辈 on 2019/11/12.
//  Copyright © 2019 任前辈. All rights reserved.
//

#import "HelloFMP.h"
#include "avformat.h"
#include "libswscale/swscale.h"
#include "libswresample/swresample.h"
#include "libavutil/pixdesc.h"

#import <VideoToolbox/VideoToolbox.h>
#import <UIKit/UIKit.h>

#import "RQBPlayView.h"
@implementation HelloFMP

static BOOL isNetworkPath (NSString *path)
{
    NSRange r = [path rangeOfString:@":"];
    if (r.location == NSNotFound)
        return NO;
    NSString *scheme = [path substringToIndex:r.length];
    if ([scheme isEqualToString:@"file"])
        return NO;
    return YES;
}

static NSData * copyFrameData(UInt8 *src, int linesize, int width, int height)
{
    width = MIN(linesize, width);
    NSMutableData *md = [NSMutableData dataWithLength: width * height];
    Byte *dst = md.mutableBytes;
    for (NSUInteger i = 0; i < height; ++i) {
        memcpy(dst, src, width);
        dst += width;
        src += linesize;
    }
    return md;
}


+(void)startApi:(UIView*)view inPath:(NSString *)path{
   
    
    
     AVFormatContext *formatCtx = NULL;
     
     av_register_all();
   
    if (isNetworkPath(path)) {
        avformat_network_init();
    }
    
    
    formatCtx = avformat_alloc_context();
   //打开文件
    if (avformat_open_input(&formatCtx, [path cStringUsingEncoding:NSUTF8StringEncoding],NULL, NULL) < 0) {
        
        return;
    }
    
    //find video
    if (avformat_find_stream_info(formatCtx, NULL) < 0) {
        return;
    }
    
    //输出信息
    av_dump_format(formatCtx, 0,[path cStringUsingEncoding:NSUTF8StringEncoding] , false);
    
    
    //找视频
    NSInteger   _videoStream = -1;
    for (int i = 0 ; i < formatCtx->nb_streams; i++) {
        if (formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            _videoStream = i;
            break;
        }
    }
    
    if (_videoStream < 0) {
        return;
    }
    
    AVCodecContext * videoCtx = formatCtx->streams[_videoStream]->codec;
    
    AVCodec * pcodec =  avcodec_find_decoder(videoCtx->codec_id);
    
    if (!pcodec) {
        return;
    }
    
    
    //单纯显示视频的demo
    KxVideoFrameFormat decoderType = (videoCtx->pix_fmt == AV_PIX_FMT_YUV420P || videoCtx->pix_fmt == AV_PIX_FMT_YUVJ420P) ? KxVideoFrameFormatYUV : KxVideoFrameFormatRGB ;
    
    
    float dw = videoCtx->width;
    float dh = videoCtx->height;
    
   
    RQBPlayView * playview = [[RQBPlayView alloc] initWithFrame:CGRectMake(0, 0, 300, 400) decoder:decoderType dW:dw dH:dh];
    playview.contentMode = UIViewContentModeScaleAspectFit;
       playview.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleBottomMargin;
    playview.backgroundColor = [UIColor greenColor];
    playview.center = view.center;
    [view addSubview:playview];
    
    
    
    //rgb sws
    struct SwsContext * _swsContext;
    _swsContext =
    sws_getContext(videoCtx->width, videoCtx->height, videoCtx->pix_fmt, videoCtx->width, videoCtx->height, AV_PIX_FMT_RGB24, SWS_FAST_BILINEAR, NULL, NULL, NULL);
    AVPicture        _picture;
    avpicture_alloc(&_picture,
    AV_PIX_FMT_RGB24,
    videoCtx->width,
    videoCtx->height);
    
    
    //刷新UI
     
    dispatch_queue_t queue = dispatch_queue_create("ddd", NULL);
    
    dispatch_async(queue, ^{
        
        dispatch_semaphore_t semp = dispatch_semaphore_create(0);
    
        AVFrame  *_videoFrame = av_frame_alloc();

        //解码
         AVPacket *packet = (AVPacket *)av_malloc(sizeof(AVPacket));

        avcodec_open2(videoCtx, pcodec, NULL);
        while (1) {
            
            if (av_read_frame(formatCtx, packet) < 0) {
                break;
            }
            
            if (packet->stream_index == _videoStream) {

//                * @deprecated Use avcodec_send_packet() and avcodec_receive_frame().
//                int ret = avcodec_decode_video2(videoCtx, _videoFrame, &gotframe,packet);
               int ret1 = avcodec_send_packet(videoCtx, packet);
               int ret2 = avcodec_receive_frame(videoCtx, _videoFrame);
                if ( ret1 < 0 || ret2 < 0) {
                    continue;
                }
               
                
               
                KxVideoFrame *frame;
                
                if (decoderType == KxVideoFrameFormatYUV) {
                        
                    KxVideoFrameYUV * yuvFrame = [[KxVideoFrameYUV alloc] init];
                    
                    yuvFrame.luma =
                    copyFrameData(_videoFrame->data[0],
                                                  _videoFrame->linesize[0],
                                                  videoCtx->width,
                                                  videoCtx->height);

                    yuvFrame.chromaB = copyFrameData(_videoFrame->data[1],
                                                     _videoFrame->linesize[1],
                                                     videoCtx->width / 2,
                                                     videoCtx->height / 2);

                    yuvFrame.chromaR = copyFrameData(_videoFrame->data[2],
                                                     _videoFrame->linesize[2],
                                                     videoCtx->width / 2,
                                                     videoCtx->height / 2);
                    frame = yuvFrame;
                    frame.duration = _videoFrame->pkt_duration;
                }else{
                    
                    sws_scale(_swsContext,
                    (const uint8_t **)_videoFrame->data,
                    _videoFrame->linesize,
                    0,
                    videoCtx->height,
                    _picture.data,
                    _picture.linesize);
                    
                    
                    KxVideoFrameRGB *rgbFrame = [[KxVideoFrameRGB alloc] init];
                           
                           rgbFrame.linesize = _picture.linesize[0];
                           rgbFrame.rgb = [NSData dataWithBytes:_picture.data[0]
                                                       length:rgbFrame.linesize * videoCtx->height];
                    frame = rgbFrame;
                }
                
                frame.width = videoCtx->width;
                frame.height = videoCtx->height;
                NSLog(@"=========正在刷新");
                NSLog(@"=========%f",frame.duration);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [playview render:frame];
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.025 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        dispatch_semaphore_signal(semp);
                    });
                });
                dispatch_semaphore_wait(semp, DISPATCH_TIME_FOREVER);

                
                
            }
            
        }
        
        av_free_packet(packet);

         NSLog(@"结束了");
        
    });
    
   
    
    
}
@end
