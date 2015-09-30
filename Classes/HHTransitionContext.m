//
//  HHTransitionContext.m
//  Pods
//
//  Created by buaacss on 15/9/24.
//
//

#import "HHTransitionContext.h"

@interface HHTransitionContext ()

@property (nonatomic, strong) UIViewController *fromViewController;
@property (nonatomic, strong) UIViewController *toViewController;
@property (nonatomic, strong) NSDictionary *privateViewControllers;
@property (nonatomic, assign) CGRect privateDisappearingFromRect;
@property (nonatomic, assign) CGRect privateAppearingFromRect;
@property (nonatomic, assign) CGRect privateDisappearingToRect;
@property (nonatomic, assign) CGRect privateAppearingToRect;
@property (nonatomic, weak) UIView *containerView;
@property (nonatomic, assign) UIModalPresentationStyle presentationStyle;
@property (nonatomic, assign) BOOL canceled;

@end

@implementation HHTransitionContext

- (instancetype)initWithFromViewController:(UIViewController *)fromViewController toViewController:(UIViewController *)toViewController isPush:(BOOL)isPush
{
    NSAssert ([fromViewController isViewLoaded] && fromViewController.view.superview, @"The fromViewController view must reside in the container view upon initializing the transition context.");
    
    if ((self = [super init])) {
        _canceled = NO;
        _presentationStyle = UIModalPresentationCustom;
        _fromViewController = fromViewController;
        _toViewController = toViewController;
        _containerView = fromViewController.view.superview;
        _privateViewControllers = @{
                                        UITransitionContextFromViewControllerKey:fromViewController,
                                        UITransitionContextToViewControllerKey:toViewController,
                                        };
        
        // Set the view frame properties which make sense in our specialized ContainerViewController context. Views appear from and disappear to the sides, corresponding to where the icon buttons are positioned. So tapping a button to the right of the currently selected, makes the view disappear to the left and the new view appear from the right. The animator object can choose to use this to determine whether the transition should be going left to right, or right to left, for example.
        CGFloat travelDistance = _containerView.bounds.size.width;
        if (isPush) {
            [_containerView addSubview:toViewController.view];
            _privateAppearingFromRect = CGRectOffset (_containerView.bounds, travelDistance, 0);
            _privateAppearingToRect = _containerView.bounds;
            _privateDisappearingToRect = _privateDisappearingFromRect = _containerView.bounds;
        } else {
            //[_containerView insertSubview:toViewController.view belowSubview:fromViewController.view];
            [toViewController viewWillAppear:YES];
            _privateDisappearingFromRect = _containerView.bounds;
            _privateDisappearingToRect = CGRectOffset (_containerView.bounds, travelDistance, 0);
            _privateAppearingToRect = _privateAppearingFromRect = _containerView.bounds;
        }
    }
    
    return self;
}

- (CGRect)initialFrameForViewController:(UIViewController *)viewController {
	if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
		return self.privateDisappearingFromRect;
	} else {
		return self.privateAppearingFromRect;
	}
}

- (CGRect)finalFrameForViewController:(UIViewController *)viewController {
	if (viewController == [self viewControllerForKey:UITransitionContextFromViewControllerKey]) {
		return self.privateDisappearingToRect;
	} else {
		return self.privateAppearingToRect;
	}
}

- (UIViewController *)viewControllerForKey:(NSString *)key {
	return self.privateViewControllers[key];
}

- (void)completeTransition:(BOOL)didComplete {
	if (self.completionBlock) {
        [self.toViewController viewDidAppear:YES];
		self.completionBlock (didComplete);
	}
}

- (BOOL)transitionWasCancelled
{
    return self.canceled;
}

// Supress warnings by implementing empty interaction methods for the remainder of the protocol:

- (void)updateInteractiveTransition:(CGFloat)percentComplete
{
}

- (void)finishInteractiveTransition
{
    self.canceled = NO;
}

- (void)cancelInteractiveTransition
{
    self.canceled = YES;
}

@end