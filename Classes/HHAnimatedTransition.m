//
//  HHAnimatedTransition.m
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import "HHAnimatedTransition.h"

#pragma mark Self Defined EaseOut Timing Funciton

typedef double (^KeyframeParametricBlock)(double);

@interface CAKeyframeAnimation (Parametric)

+ (id)animationWithKeyPath:(NSString *)path
                  function:(KeyframeParametricBlock)block
                 fromValue:(double)fromValue
                   toValue:(double)toValue;

@end

@implementation CAKeyframeAnimation (Parametric)

+ (id)animationWithKeyPath:(NSString *)path
                  function:(KeyframeParametricBlock)block
                 fromValue:(double)fromValue
                   toValue:(double)toValue {
    // get a keyframe animation to set up
    CAKeyframeAnimation *animation =
    [CAKeyframeAnimation animationWithKeyPath:path];
    // break the time into steps
    //  (the more steps, the smoother the animation)
    NSUInteger steps = 200;
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:steps];
    double time = 0.0;
    double timeStep = 1.0 / (double)(steps - 1);
    for(NSUInteger i = 0; i < steps; i++) {
        double value = fromValue + (block(time) * (toValue - fromValue));
        [values addObject:[NSNumber numberWithDouble:value]];
        time += timeStep;
    }
    // we want linear animation between keyframes, with equal time steps
    animation.calculationMode = kCAAnimationLinear;
    // set keyframes and we're done
    [animation setValues:values];
    return(animation);
}

@end

#pragma mark HHAnimatedTransition

@interface HHAnimatedTransition ()

@property (nonatomic, strong) id<UIViewControllerContextTransitioning>context;

@end

@implementation HHAnimatedTransition

- (NSTimeInterval)transitionDuration:(id<UIViewControllerContextTransitioning>)transitionContext {
    return 0.3;
}

/// Slide views horizontally, with a bit of space between, while fading out and in.
- (void)animateTransition:(id<UIViewControllerContextTransitioning>)transitionContext {
    
    self.context = transitionContext;
    
    UIViewController* toViewController = [transitionContext viewControllerForKey:UITransitionContextToViewControllerKey];
    UIViewController* fromViewController = [transitionContext viewControllerForKey:UITransitionContextFromViewControllerKey];
    
    // When sliding the views horizontally in and out, figure out whether we are going left or right.
    BOOL isPush = [transitionContext initialFrameForViewController:toViewController].origin.x > 1;
    
    if (isPush) {
        KeyframeParametricBlock function = ^double(double time) {
            CGFloat coeff = 4;
            CGFloat offset = exp(-coeff);
            CGFloat scale = 1.0 / (1.0 - offset);
            return 1.0 - scale * (exp(time * -coeff) - offset);
        };
        
        CALayer *layer = toViewController.view.layer;
        if (layer) {
            [CATransaction begin];
            [CATransaction setCompletionBlock:^{
                [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
            }];
            [CATransaction
             setValue:@(0.5)
             forKey:kCATransactionAnimationDuration];
            
            // make an animation
            CAAnimation *flip = [CAKeyframeAnimation
                                 animationWithKeyPath:@"position.x"
                                 function:function fromValue:[transitionContext containerView].bounds.size.width * 3 / 2 toValue:[transitionContext containerView].bounds.size.width / 2];
            // use it
            [layer addAnimation:flip forKey:@"position"];
            
            [CATransaction commit];
        }
    } else {
        CGFloat travelDistance = [transitionContext containerView].bounds.size.width;
        fromViewController.view.transform = CGAffineTransformMakeTranslation(0, 0);
        [UIView animateWithDuration:[self transitionDuration:transitionContext] delay:0 options:0x00 animations:^{
            fromViewController.view.transform = CGAffineTransformMakeTranslation(travelDistance, 0);
        } completion:^(BOOL finished) {
            fromViewController.view.transform = CGAffineTransformIdentity;
            [transitionContext completeTransition:![transitionContext transitionWasCancelled]];
        }];
    }
}

- (void)animationEnded:(BOOL)transitionCompleted
{
    if (!transitionCompleted) {
        //被取消
        UIViewController *fromViewController = [self.context viewControllerForKey:UITransitionContextFromViewControllerKey];
        [fromViewController.view.layer removeAllAnimations];
        fromViewController.view.frame = self.context.containerView.bounds;
    }
}

@end
