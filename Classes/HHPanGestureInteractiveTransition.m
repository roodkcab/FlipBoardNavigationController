//
//  HHPanGestureInteractiveTransition.m
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import "HHPanGestureInteractiveTransition.h"

@implementation HHPanGestureInteractiveTransition {
    BOOL _leftToRightTransition;
}

- (id)initWithGestureRecognizerInView:(UIView *)view recognizedBlock:(void (^)(UIPanGestureRecognizer *recognizer))gestureRecognizedBlock {
    
    self = [super init];
    if (self) {
        _gestureRecognizedBlock = [gestureRecognizedBlock copy];
        _recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [view addGestureRecognizer:_recognizer];
    }
    return self;
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    [super startInteractiveTransition:transitionContext];
    
    _leftToRightTransition = [_recognizer velocityInView:_recognizer.view].x > 0;
}

- (void)pan:(UIPanGestureRecognizer*)recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.gestureRecognizedBlock(recognizer);
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:recognizer.view];
        CGFloat d = translation.x / CGRectGetWidth(recognizer.view.bounds);
        if (!_leftToRightTransition) d *= -1;
        [self updateInteractiveTransition:d*1.2];
    } else if (recognizer.state >= UIGestureRecognizerStateEnded) {
        CGFloat velocity = [recognizer velocityInView:recognizer.view].x;
        if (velocity > 0) {
            [self finishInteractiveTransition];
        } else {
            [self cancelInteractiveTransition];
        }
    }
}

@end