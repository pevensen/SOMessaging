//
//  SOMessageInputView.m
//  SOSimpleChatDemo
//
//  Created by Artur Mkrtchyan on 4/25/14.
//  Copyright (c) 2014 SocialOjbects Software. All rights reserved.
//

#import "SOMessageInputView.h"
#import <QuartzCore/QuartzCore.h>
#import "UINavigationController+Rotation.h"

@interface SOMessageInputView() <UITextViewDelegate, UIGestureRecognizerDelegate>
{
    CGRect keyboardFrame;
    UIViewAnimationCurve keyboardCurve;
    double keyboardDuration;
    UIView *inputAccessoryForFindingKeyboard;
    CGFloat initialInputViewPosYWhenKeyboardIsShown;
    BOOL keyboardHidesFromDragging;
}

@property (weak, nonatomic) UIView *keyboardView;

@end

@implementation SOMessageInputView

- (id)init
{
    self = [super init];
    if (self) {
        [self setupInitialData];
        [self setup];
    }
    return self;
}

- (void)setupInitialData
{
    self.textInitialHeight = 40.0f;
    self.textMaxHeight = 130.0f;
    self.textleftMargin = 5.0f;
    self.textTopMargin = 5.5f;
    self.textBottomMargin = 5.5f;
    
    CGRect frame = CGRectZero;
    frame.size.height = self.textInitialHeight;
    frame.size.width = [UIScreen mainScreen].bounds.size.width;
    self.frame = frame;
    
    self.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
}

- (void)setup
{
    self.backgroundColor = [UIColor colorWithRed:(237/255.0) green:(237/255.0) blue:(237/255.0) alpha:1];
    
    self.textBgImageView = [[UIImageView alloc] init];
    self.textBgImageView.backgroundColor = [UIColor clearColor];
    self.textBgImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:self.textBgImageView];
    
    self.textView = [[SOPlaceholderedTextView alloc] init];
    self.textView.textColor = [UIColor blackColor];
    self.textView.delegate = self;
    self.textView.backgroundColor = [UIColor clearColor];
    [self.textView setTextContainerInset:UIEdgeInsetsZero];
    self.textView.textContainer.lineFragmentPadding = 0;
    self.textView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    inputAccessoryForFindingKeyboard = [[UIView alloc] initWithFrame:CGRectZero];
    self.textView.inputAccessoryView = inputAccessoryForFindingKeyboard;
    [self addSubview:self.textView];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.backgroundColor = [UIColor clearColor];
    [self.sendButton setTitleColor:[UIColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]
                          forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor colorWithRed:0.0 green:65.0/255.0 blue:136.0/255.0 alpha:1.0]
                          forState:UIControlStateHighlighted];
    self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleTopMargin;
    [self.sendButton addTarget:self action:@selector(sendTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.sendButton];
    
    self.mediaButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.mediaButton addTarget:self action:@selector(mediaTapped:) forControlEvents:UIControlEventTouchUpInside];
    self.mediaButton.contentMode = UIViewContentModeScaleAspectFit;
    self.mediaButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.mediaButton.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
    [self addSubview:self.mediaButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillShowNote:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleKeyboardWillHideNote:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleOrientationDidChandeNote:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    self.textView.placeholderText = NSLocalizedString(@"Type message...", nil);
    [self.sendButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
    self.sendButton.frame = CGRectMake(0, 0, 70, self.textInitialHeight - self.textTopMargin - self.textBottomMargin);
    
    [self.mediaButton setImage:[UIImage imageNamed:@"attachment.png"] forState:UIControlStateNormal];
    self.mediaButton.frame = CGRectMake(0, 0, 50, 24);
    
    [self adjustInputView];
}

#pragma mark - Public methods
- (void)adjustInputView
{
    if (!self.mediaButton.hidden) {
        CGRect mediaFrame = self.mediaButton.frame;
        mediaFrame.origin = CGPointMake(0, 0);
        self.mediaButton.frame = mediaFrame;
        self.mediaButton.center = CGPointMake(self.mediaButton.center.x, self.textInitialHeight/2);
    } else {
        self.mediaButton.frame = CGRectZero;
    }
    

    
    CGRect sendFrame = self.sendButton.frame;
    sendFrame.origin = CGPointMake(self.frame.size.width - sendFrame.size.width, 0);
    self.sendButton.frame = sendFrame;
    self.sendButton.center = CGPointMake(self.sendButton.center.x, self.textInitialHeight/2);
    
    CGRect txtBgFrame = self.textBgImageView.frame;
    txtBgFrame.origin = CGPointMake(self.mediaButton.frame.origin.x + self.mediaButton.frame.size.width + self.textleftMargin, self.textTopMargin);
    txtBgFrame.size = CGSizeMake(self.frame.size.width - self.mediaButton.frame.size.width - self.textleftMargin - self.sendButton.frame.size.width - self.textRightMargin, self.textInitialHeight - self.textTopMargin - self.textBottomMargin);

    self.textBgImageView.frame = txtBgFrame;
    
    UIImage *image = [UIImage imageNamed:@"inputTextBG.png"];
    self.textBgImageView.image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(13, 13, 13, 13)];

    CGFloat topPadding = 6.0f;
    CGFloat bottomPadding = 5.0f;
    CGFloat leftPadding = 6.0f;
    CGFloat rightPadding = 6.0f;
    
    CGRect txtFrame = self.textView.frame;
    txtFrame.origin.x = txtBgFrame.origin.x + leftPadding;
    txtFrame.origin.y = txtBgFrame.origin.y + topPadding;
    txtFrame.size.width = txtBgFrame.size.width - leftPadding - rightPadding;
    txtFrame.size.height = txtBgFrame.size.height - topPadding - bottomPadding;
    self.textView.frame = txtFrame;
}

- (void)adjustPosition
{
    CGRect frame = self.frame;
    frame.origin.y = self.superview.bounds.size.height - frame.size.height;
    self.frame = frame;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0.0, self.frame.size.height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    
    pan.delegate = self;
    
    [self addGestureRecognizer:tap];
    [self.superview addGestureRecognizer:pan];
    
    UINavigationController *nc = [self navigationControllerInstance];
    nc.cantAutorotate = NO;
}

- (void)adjustTableViewWithCurve:(BOOL)withCurve scrollsToBottom:(BOOL)scrollToBottom
{
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.tableView.contentInset.top, 0.0, keyboardFrame.size.height + self.frame.size.height, 0.0);

    NSInteger section = [self.tableView numberOfSections] - 1;
    NSInteger row = [self.tableView numberOfRowsInSection:section] - 1;
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row inSection:section];
    
    [UIView beginAnimations:@"anim" context:NULL];
    [UIView setAnimationDuration:keyboardDuration];
    if (withCurve) {
        [UIView setAnimationCurve:keyboardCurve];
    }
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    if (scrollToBottom) {
        [self.tableView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:NO];
    }
    [UIView commitAnimations];
}

#pragma mark - Actions
- (void)sendTapped:(id)sender
{
    NSString *msg = self.textView.text;
    self.textView.text = @"";
    [self adjustTextViewSize];
    
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageInputView:didSendMessage:)]) {
        [self.delegate messageInputView:self didSendMessage:msg];
    }
}

- (void)mediaTapped:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(messageInputViewDidSelectMediaButton:)]) {
        [self.delegate messageInputViewDidSelectMediaButton:self];
    }
}

#pragma mark - private Methods
- (void)adjustTextViewSize
{
    CGRect usedFrame = [self.textView.layoutManager usedRectForTextContainer:self.textView.textContainer];
    
    CGRect frame = self.textView.frame;
    CGFloat delta = ceilf(usedFrame.size.height) - frame.size.height;
    
     CGFloat lineHeight = self.textView.font.lineHeight;
    int numberOfActualLines = (int)ceilf(usedFrame.size.height / lineHeight);
    
    CGFloat actualHeight = numberOfActualLines * lineHeight;
    
    delta = actualHeight - self.textView.frame.size.height; //self.textView.font.lineHeight - 5;
    CGRect frm = self.frame;
    frm.size.height += ceilf(delta);
    frm.origin.y -= ceilf(delta);
    
    if (frm.size.height < self.textMaxHeight) {
        if (frm.size.height < self.textInitialHeight) {
            frm.size.height = self.textInitialHeight;
            frm.origin.y = self.superview.bounds.size.height - frm.size.height - keyboardFrame.size.height;
        }
        
        
        [UIView animateWithDuration:0.3 animations:^{
            self.frame = frm;

        } completion:^(BOOL finished) {
            [self.textView scrollRectToVisible:usedFrame animated:YES];
        }];
    } else {
        [self.textView scrollRectToVisible:usedFrame animated:YES];
    }
    
    [self adjustTableViewWithCurve:NO scrollsToBottom:YES];
}

#pragma mark - textview delegate
- (void)textViewDidChange:(UITextView *)textView
{
    [self adjustTextViewSize];    
}

#pragma mark - Notifications handlers
- (void)handleKeyboardWillShowNote:(NSNotification *)notification
{
    CGRect keyboardRect = [[notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    if (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation)) {
        keyboardRect = CGRectMake(keyboardRect.origin.x, keyboardRect.origin.y, MAX(keyboardRect.size.width,keyboardRect.size.height), MIN(keyboardRect.size.width,keyboardRect.size.height));
    }
    
    keyboardFrame = keyboardRect;
    
	UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
    keyboardCurve = curve;
    
	double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardDuration = duration;
    
    CGRect frame = self.frame;
    frame.origin.y = self.superview.bounds.size.height - frame.size.height - keyboardRect.size.height;
    initialInputViewPosYWhenKeyboardIsShown = frame.origin.y;
    
    [self adjustTableViewWithCurve:YES scrollsToBottom:YES];
    
    [UIView animateWithDuration:duration animations:^{
        [UIView setAnimationCurve:curve];
        self.frame = frame;
    }];
    
    //Closing keyboard on tap
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self.textView action:@selector(resignFirstResponder)];
    [self.tableView addGestureRecognizer:tap];
}

- (void)handleKeyboardWillHideNote:(NSNotification *)notification
{
	UIViewAnimationCurve curve = [[notification.userInfo objectForKey:UIKeyboardAnimationCurveUserInfoKey] integerValue];
	double duration = [[notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    keyboardCurve = curve;
    keyboardDuration = duration;
    
    CGRect frame = self.frame;
    frame.origin.y = self.superview.bounds.size.height - frame.size.height;
    keyboardFrame = CGRectZero;
    [UIView animateWithDuration:duration animations:^{
        [UIView setAnimationCurve:curve];
        self.frame = frame;
    } completion:^(BOOL finished) {

    }];
    
    [self adjustTableViewWithCurve:YES scrollsToBottom:!keyboardHidesFromDragging];
    
    keyboardHidesFromDragging = NO;
}

- (void)handleOrientationDidChandeNote:(NSNotification *)note
{
    [self performSelector:@selector(adjustTextViewSize) withObject:nil afterDelay:0.1];
}

#pragma mark - Gestures
- (void)handleTap:(UITapGestureRecognizer *)tap
{
    if (![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

- (void)handlePan:(UIPanGestureRecognizer *)pan
{
    // if keyboard isn't opened then return.
    if (![self.textView isFirstResponder]) {
        return;
    }
    
    static BOOL panDidEnterIntoThisView = NO;
    static CGFloat initialPosY          = 0;
    static CGFloat kbInitialPosY        = 0;
    
    if (!self.keyboardView) {
        self.keyboardView = inputAccessoryForFindingKeyboard.superview;
    }
    
    CGRect frame   = self.frame;
    CGRect kbFrame = self.keyboardView.frame;
    
    CGPoint point = [pan locationInView:self.superview];

    if (!panDidEnterIntoThisView) {
        if (CGRectContainsPoint(self.frame, point)) {
            panDidEnterIntoThisView = YES;
            _viewIsDragging = YES;
            UINavigationController *nc = [self navigationControllerInstance];
            nc.cantAutorotate = YES;
            initialPosY = self.frame.origin.y;
            kbInitialPosY = self.keyboardView.frame.origin.y;
            [pan setTranslation:CGPointZero inView:pan.view];
        }
    }
    
    if (_viewIsDragging)
    {
        CGPoint translation = [pan translationInView:pan.view];
        
        frame.origin.y   += translation.y;
        kbFrame.origin.y += translation.y;
        
        if (pan.state == UIGestureRecognizerStateEnded || pan.state == UIGestureRecognizerStateCancelled)
        {
            UINavigationController *nc = [self navigationControllerInstance];
            nc.cantAutorotate = NO;

            panDidEnterIntoThisView = NO;
            _viewIsDragging = NO;
            
            if (frame.origin.y < initialPosY + (self.frame.size.height + self.keyboardView.frame.size.height)/2) {
                
                frame.origin.y   = initialPosY;
                kbFrame.origin.y = kbInitialPosY;
                
                [UIView animateWithDuration:keyboardDuration animations:^{
                    self.frame = frame;
                    self.keyboardView.frame = kbFrame;
                }];
                
            } else {
                
                frame.origin.y   = self.superview.frame.size.height - self.frame.size.height;
                kbFrame.origin.y = self.superview.frame.size.height;
                
                [UIView animateWithDuration:keyboardDuration animations:^{
                    self.frame = frame;
                    self.keyboardView.frame = kbFrame;
                } completion:^(BOOL finished) {
                    keyboardHidesFromDragging = YES;
                    [self hideKeeyboardWithoutAnimation];
                }];
                
            }
            return;
        }
        
        if (frame.origin.y < initialPosY) {
            
            UINavigationController *nc = [self navigationControllerInstance];
            nc.cantAutorotate = NO;
            
            panDidEnterIntoThisView = NO;
            _viewIsDragging = NO;
            
            frame.origin.y   = initialPosY;
            kbFrame.origin.y = kbInitialPosY;
            
            [UIView animateWithDuration:keyboardDuration animations:^{
                self.frame = frame;
                self.keyboardView.frame = kbFrame;
            }];
            
        } else if (frame.origin.y > self.superview.frame.size.height - self.frame.size.height) {
            
            UINavigationController *nc = [self navigationControllerInstance];
            nc.cantAutorotate = NO;

            
            panDidEnterIntoThisView = NO;
            _viewIsDragging = NO;
            
            frame.origin.y   = self.superview.frame.size.height - self.frame.size.height;
            kbFrame.origin.y = self.superview.frame.size.height;
            
            [UIView animateWithDuration:keyboardDuration animations:^{
                self.frame = frame;
                self.keyboardView.frame = kbFrame;
            } completion:^(BOOL finished) {
                keyboardHidesFromDragging = YES;
                [self hideKeeyboardWithoutAnimation];
                
                // Canceling pan gesture
                pan.enabled = NO;
                pan.enabled = YES;
            }];
            
        } else {
            
            self.frame = frame;
            self.keyboardView.frame = kbFrame;
        }
    }
    
    [pan setTranslation:CGPointZero inView:pan.view];
}

- (void)closeKeyboard
{
    CGRect frame = self.keyboardView.frame;
    CGRect selfFrame = self.frame;
    frame.origin.y = self.superview.frame.size.height;
    selfFrame.origin.y = frame.origin.y - selfFrame.size.height;

    __weak SOMessageInputView *weakSelf = self;
    [UIView animateWithDuration:keyboardDuration animations:^{
        weakSelf.keyboardView.frame = frame;
        weakSelf.frame = selfFrame;
    } completion:^(BOOL finished) {
        [self hideKeeyboardWithoutAnimation];
    }];
}

- (void)hideKeeyboardWithoutAnimation
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.0];
    [UIView setAnimationDelay:0.0];
    [UIView setAnimationCurve:UIViewAnimationCurveLinear];
    
    [self.textView resignFirstResponder];
    
    [UIView commitAnimations];
}

#pragma mark - 
- (UINavigationController*)navigationControllerInstance
{
    UINavigationController *resultNVC = nil;
    UIViewController *vc = nil;
    for (UIView* next = [self superview]; next; next = next.superview)
    {
        UIResponder* nextResponder = [next nextResponder];
        
        if ([nextResponder isKindOfClass:[UIViewController class]])
        {
            vc = (UIViewController*)nextResponder;
            break;
        }
    }
    
    if (vc)
    {
        if ([vc isKindOfClass:[UINavigationController class]])
        {
            resultNVC = (UINavigationController *)vc;
        }
        else
        {
            resultNVC = vc.navigationController;
        }
    }
    
    return resultNVC;
}

#pragma mark - Gestures delegate
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return YES;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    return YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end