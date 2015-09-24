//
//  HHPercentDrivenInteractiveTransition.h
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import <UIKit/UIKit.h>

@interface HHPercentDrivenInteractiveTransition : NSObject <UIViewControllerInteractiveTransitioning>

- (instancetype)initWithAnimator:(id<UIViewControllerAnimatedTransitioning>)animator;

@property (nonatomic, readonly) CGFloat duration;
@property (readonly) CGFloat percentComplete;

/**
 The animated transitioning that this percent driven interaction should control.
 This property must be set prior to the start of a transition.
 */
@property (nonatomic, weak) id<UIViewControllerAnimatedTransitioning>animator;

@property (nonatomic, readonly) CGFloat completionSpeed; // Only works for completionSpeed = 1
// Not yet implemented
// @property (nonatomic, assign) UIViewAnimationCurve animationCurve;

- (void)updateInteractiveTransition:(CGFloat)percentComplete;
- (void)cancelInteractiveTransition;
- (void)finishInteractiveTransition;

@end
