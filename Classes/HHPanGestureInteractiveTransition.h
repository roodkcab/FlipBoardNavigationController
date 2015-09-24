//
//  HHPanGestureInteractiveTransition.h
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import "HHPercentDrivenInteractiveTransition.h"

@interface HHPanGestureInteractiveTransition : HHPercentDrivenInteractiveTransition

- (id)initWithGestureRecognizerInView:(UIView *)view recognizedBlock:(void (^)(UIPanGestureRecognizer *recognizer))gestureRecognizedBlock;

@property (nonatomic, readonly) UIPanGestureRecognizer *recognizer;

/// This block gets run when the gesture recognizer start recognizing a pan. Inside, the start of a transition can be triggered.
@property (nonatomic, copy) void (^gestureRecognizedBlock)(UIPanGestureRecognizer *recognizer);

@end
