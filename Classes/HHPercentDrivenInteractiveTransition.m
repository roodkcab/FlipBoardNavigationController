//
//  HHPercentDrivenInteractiveTransition.m
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import "HHPercentDrivenInteractiveTransition.h"

@implementation HHPercentDrivenInteractiveTransition {
    __weak id<UIViewControllerContextTransitioning> _transitionContext;
    BOOL _isInteracting;
    CADisplayLink *_displayLink;
}

#pragma mark - Initialization
- (instancetype)initWithAnimator:(id<UIViewControllerAnimatedTransitioning>)animator {
    
    self = [super init];
    if (self) {
        [self _commonInit];
        _animator = animator;
    }
    return self;
}

- (instancetype)init {
    
    self = [super init];
    if (self) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    _completionSpeed = 1;
}

#pragma mark - Public methods
- (BOOL)isInteracting {
    return _isInteracting;
}

- (CGFloat)duration {
    return [_animator transitionDuration:_transitionContext];
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    _transitionContext = transitionContext;
    [_transitionContext containerView].layer.speed = 0;
    
    [_animator animateTransition:_transitionContext];
}

- (void)updateInteractiveTransition:(CGFloat)percentComplete {
    self.percentComplete = fmaxf(fminf(percentComplete, 1), 0); // Input validation
}

- (void)cancelInteractiveTransition {
    
    _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(_tickCancelAnimation)];
    [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    
    [_transitionContext cancelInteractiveTransition];
}

- (void)finishInteractiveTransition {
    CALayer *layer = [_transitionContext containerView].layer;
    
    layer.speed = [self completionSpeed];
    
    CFTimeInterval pausedTime = [layer timeOffset];
    layer.timeOffset = 0.0;
    layer.beginTime = 0.0;
    CFTimeInterval timeSincePause = [layer convertTime:CACurrentMediaTime() fromLayer:nil] - pausedTime;
    layer.beginTime = timeSincePause;
    
    [_transitionContext finishInteractiveTransition];
}

#pragma mark - Private methods
- (void)setPercentComplete:(CGFloat)percentComplete {
    
    _percentComplete = percentComplete;
    
    [self _setTimeOffset:percentComplete*[self duration]];
    [_transitionContext updateInteractiveTransition:percentComplete];
}

- (void)_setTimeOffset:(NSTimeInterval)timeOffset {
    [_transitionContext containerView].layer.timeOffset = timeOffset;
}

- (void)_tickCancelAnimation {
    NSTimeInterval timeOffset = [self _timeOffset]-[_displayLink duration];
    if (timeOffset < 0) {
        [self _transitionFinishedCanceling];
    } else {
        [self _setTimeOffset:timeOffset];
    }
}

- (CFTimeInterval)_timeOffset {
    return [_transitionContext containerView].layer.timeOffset;
}

- (void)_transitionFinishedCanceling {
    [_displayLink invalidate];
    
    CALayer *layer = [_transitionContext containerView].layer;
    layer.speed = 1;
}

@end
