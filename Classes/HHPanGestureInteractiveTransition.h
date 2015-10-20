//
//  HHPanGestureInteractiveTransition.h
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import "HHPercentDrivenInteractiveTransition.h"

@protocol HHPanGestureInteractiveTransitionDelegate <NSObject>

- (BOOL)swipeBackGestureEnable:(CGPoint)point;

@end

@interface HHPanGestureInteractiveTransition : HHPercentDrivenInteractiveTransition

- (id)initWithGestureRecognizerInView:(UIView *)view recognizedBlock:(void (^)(UIPanGestureRecognizer *recognizer))gestureRecognizedBlock;

@property (nonatomic, readonly) UIPanGestureRecognizer *recognizer;
@property (nonatomic, weak) id<HHPanGestureInteractiveTransitionDelegate> delegate;

@end
