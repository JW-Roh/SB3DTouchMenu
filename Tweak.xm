#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioServices.h>


extern "C" void AudioServicesPlaySystemSoundWithVibration(SystemSoundID inSystemSoundID, id unknown, NSDictionary *options);


@interface SBIconView : UIView
@property(retain, nonatomic) UILongPressGestureRecognizer *shortcutMenuPeekGesture;
@end

@interface SBIconController
+ (id)sharedInstance;
- (void)_handleShortcutMenuPeek:(id)arg1;
- (BOOL)_canRevealShortcutMenu;
- (BOOL)isEditing;
@end

@interface UIGestureRecognizer (Firmware90_Private)
- (void)setRequiredPreviewForceState:(int)arg1;
@end



void hapticFeedback() {
	@autoreleasepool {
		NSDictionary *dict = @{ @"VibePattern" : @[ @(YES), @(50) ], @"Intensity" : @(1) };
		AudioServicesPlaySystemSoundWithVibration(kSystemSoundID_Vibrate, nil, dict);
	}
}


%hook SBIconView 

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
	if ([gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]] && [[%c(SBIconController) sharedInstance] isEditing])
		return NO;
	
	return YES;
}

- (void)addGestureRecognizer:(UIGestureRecognizer *)toAddGesture {
	if (toAddGesture != nil && toAddGesture == self.shortcutMenuPeekGesture) {
		UILongPressGestureRecognizer *menuGestureCanceller = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(__sb3dtm_handleLongPressGesture:)];
		menuGestureCanceller.minimumPressDuration = 1.0f;
		menuGestureCanceller.delegate = (id <UIGestureRecognizerDelegate>)self;
		menuGestureCanceller.delaysTouchesEnded = NO;
		menuGestureCanceller.cancelsTouchesInView = NO;
		menuGestureCanceller.allowableMovement = 1.0f;
		%orig(menuGestureCanceller);
		
		[toAddGesture removeTarget:[%c(SBIconController) sharedInstance] action:@selector(_handleShortcutMenuPeek:)];
		[toAddGesture addTarget:self action:@selector(__sb3dtm_handleForceTouchGesture:)];
		[toAddGesture setRequiredPreviewForceState:0];
		[toAddGesture requireGestureRecognizerToFail:menuGestureCanceller];
		toAddGesture.delegate = (id <UIGestureRecognizerDelegate>)self;
		
		[menuGestureCanceller release];
	}
	
	%orig;
}

%new
- (void)__sb3dtm_handleLongPressGesture:(UILongPressGestureRecognizer *)gesture {
	
}

%new
- (void)__sb3dtm_handleForceTouchGesture:(UILongPressGestureRecognizer *)gesture {
	if (gesture.state != UIGestureRecognizerStateCancelled && gesture.state != UIGestureRecognizerStateFailed) {
		[[%c(SBIconController) sharedInstance] _handleShortcutMenuPeek:gesture];
	}
}

- (void)_handleFirstHalfLongPressTimer:(id)timer {
	if (![[%c(SBIconController) sharedInstance] isEditing]) {
		hapticFeedback();
	}
	
	%orig;
}

- (void)_handleSecondHalfLongPressTimer:(id)timer {
	%orig;
}

%end

%hook SBIconController

- (void)_revealMenuForIconView:(SBIconView *)iconView presentImmediately:(BOOL)imm {
	%orig(iconView, YES);
}

%end

