#import "BackgroundView.h"
#import "StatusItemView.h"
#import "ExtendedTextView.h"

@class PanelController;

@protocol PanelControllerDelegate <NSObject>

@optional

- (StatusItemView *)statusItemViewForPanelController:(PanelController *)controller;

@end

#pragma mark -

@interface PanelController : NSWindowController <NSWindowDelegate, NSTextViewDelegate>
{
    BOOL _hasActivePanel;
    __unsafe_unretained BackgroundView *_backgroundView;
    __unsafe_unretained ExtendedTextView *_txtInput;
    __unsafe_unretained ExtendedTextView *_txtAnswer;
    __unsafe_unretained NSPanel *_opsWindow;
    __unsafe_unretained id<PanelControllerDelegate> _delegate;
}

@property (nonatomic, unsafe_unretained) IBOutlet BackgroundView *backgroundView;
@property (nonatomic, unsafe_unretained) IBOutlet ExtendedTextView *txtInput;
@property (nonatomic, unsafe_unretained) IBOutlet ExtendedTextView *txtAnswer;
@property (nonatomic, unsafe_unretained) IBOutlet NSPanel *opsWindow;


@property (nonatomic) BOOL hasActivePanel;
@property (nonatomic, unsafe_unretained, readonly) id<PanelControllerDelegate> delegate;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate;

- (void)openPanel;
- (void)closePanel;
- (void)openOps;

@end
