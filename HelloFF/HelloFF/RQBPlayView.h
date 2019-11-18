//
//  RQBPlayView.h
//  HelloFF
//
//  Created by 任前辈 on 2019/11/15.
//  Copyright © 2019 任前辈. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum {
    
    KxMovieFrameTypeAudio,
    KxMovieFrameTypeVideo,
    KxMovieFrameTypeArtwork,
    KxMovieFrameTypeSubtitle,
    
} KxMovieFrameType;

typedef enum {
        
    KxVideoFrameFormatRGB,
    KxVideoFrameFormatYUV,
    
} KxVideoFrameFormat;

@interface KxMovieFrame : NSObject
@property ( nonatomic) CGFloat position;
@property ( nonatomic) CGFloat duration;
@end

@interface KxVideoFrame : KxMovieFrame
@property ( nonatomic) NSUInteger width;
@property ( nonatomic) NSUInteger height;
@end

@interface KxVideoFrameRGB : KxVideoFrame
@property ( nonatomic) NSUInteger linesize;
@property ( nonatomic, strong) NSData *rgb;
- (UIImage *) asImage;
@end

@interface KxVideoFrameYUV : KxVideoFrame
@property ( nonatomic, strong) NSData *luma;
@property ( nonatomic, strong) NSData *chromaB;
@property ( nonatomic, strong) NSData *chromaR;
@end




@interface RQBPlayView : UIView
- (id) initWithFrame:(CGRect)frame
             decoder: (KxVideoFrameFormat) Format  dW:(CGFloat)dw dH:(CGFloat)dh;
- (void)render: (KxVideoFrame *) frame;

@end

NS_ASSUME_NONNULL_END
