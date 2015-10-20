//
//  HHPanGestureInteractiveTransition.m
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import "HHPanGestureInteractiveTransition.h"

@interface HHPanGestureInteractiveTransition () <UIGestureRecognizerDelegate>

/// This block gets run when the gesture recognizer start recognizing a pan. Inside, the start of a transition can be triggered.
@property (nonatomic, copy) void (^gestureRecognizedBlock)(UIPanGestureRecognizer *recognizer);
@property (nonatomic, assign) BOOL leftToRightTransition;
@property (nonatomic, assign) BOOL keyboardVisible;

@end

@implementation HHPanGestureInteractiveTransition

- (id)initWithGestureRecognizerInView:(UIView *)view recognizedBlock:(void (^)(UIPanGestureRecognizer *recognizer))gestureRecognizedBlock
{
    self = [super init];
    if (self) {
        _gestureRecognizedBlock = [gestureRecognizedBlock copy];
        _recognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        _recognizer.delegate = self;
        [view addGestureRecognizer:_recognizer];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noticeShowKeyboard:) name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noticeHideKeyboard:) name:UIKeyboardWillHideNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (IBAction)noticeShowKeyboard:(id)sender
{
    self.keyboardVisible = YES;
}

- (IBAction)noticeHideKeyboard:(id)sender
{
    self.keyboardVisible = NO;
}

- (void)startInteractiveTransition:(id<UIViewControllerContextTransitioning>)transitionContext
{
    [super startInteractiveTransition:transitionContext];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return !self.keyboardVisible && [self.delegate swipeBackGestureEnable:[touch locationInView:touch.window]];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}

- (void)pan:(UIPanGestureRecognizer*)recognizer {
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        CGPoint v = [self.recognizer velocityInView:self.recognizer.view];
        self.leftToRightTransition = v.x > 100 && v.x > fabs(v.y * 1.5);
        if (self.leftToRightTransition) {
            self.gestureRecognizedBlock(recognizer);
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [recognizer translationInView:recognizer.view];
        CGFloat d = translation.x / CGRectGetWidth(recognizer.view.bounds);
        if (!self.leftToRightTransition) d *= -1;
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