#import "PanelController.h"
#import "BackgroundView.h"
#import "StatusItemView.h"
#import "MenubarController.h"

#import "DDMathParser.h"
#import "DDMathTokenizer.h"
#import "DDMathTokenInterpreter.h"
#import "DDMathOperator.h"
#import "DDMathOperatorSet.h"

#define OPEN_DURATION .15
#define CLOSE_DURATION .1
#define MENU_ANIMATION_DURATION .1

#pragma mark -

@implementation PanelController {
    NSInteger POPUP_HEIGHT;
    NSInteger PANEL_WIDTH;
    NSInteger PANEL_OriginX;
    NSInteger PANEL_OriginY;
}

@synthesize backgroundView = _backgroundView;
@synthesize delegate = _delegate;
@synthesize txtInput = _txtInput;
@synthesize txtAnswer = _txtAnswer;
@synthesize opsWindow = _opsWindow;

- (id)initWithDelegate:(id<PanelControllerDelegate>)delegate
{
    self = [super initWithWindowNibName:@"Panel"];
    if (self != nil)
    {
        POPUP_HEIGHT = 122;
        PANEL_WIDTH = 280;
        PANEL_OriginX = -1;
        _delegate = delegate;
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    NSPanel *panel = (id)[self window];
    [panel setAcceptsMouseMovedEvents:YES];
    [panel setLevel:NSPopUpMenuWindowLevel];
    [panel setOpaque:NO];
    [panel setBackgroundColor:[NSColor clearColor]];
    self.txtInput.delegate = self;
    [self.txtInput setFocusRingType:NSFocusRingTypeNone];
    _opsWindow.titlebarAppearsTransparent = YES;
    _opsWindow.backgroundColor = [NSColor blackColor];
}

- (void)textDidChange:(NSNotification *)notification {
    NSString *result = @"";
    DDMathOperatorSet *defaultOperators = [DDMathOperatorSet defaultOperatorSet];
    defaultOperators.interpretsPercentSignAsModulo = NO;
    DDMathEvaluator *evaluator = [[DDMathEvaluator alloc] init];
    evaluator.functionResolver = ^DDMathFunction (NSString *name) {
        return ^(NSArray *args, NSDictionary *substitutions, DDMathEvaluator *eval, NSError **error) {
            return [DDExpression numberExpressionWithNumber:@0];
        };
    };
    evaluator.variableResolver = ^(NSString *variable) {
        return @0;
    };
    for (NSString *line in [[[self.txtInput textStorage] string] componentsSeparatedByString:@"\n"]) {
        NSError *error = nil;
        DDMathTokenizer *tokenizer = [[DDMathTokenizer alloc] initWithString:line operatorSet:nil error:&error];
        DDMathTokenInterpreter *interpreter = [[DDMathTokenInterpreter alloc] initWithTokenizer:tokenizer error:&error];
        DDParser *parser = [[DDParser alloc] initWithTokenInterpreter:interpreter];
        DDExpression *expression = [parser parsedExpressionWithError:&error];
        DDExpression *rewritten = [[DDExpressionRewriter defaultRewriter] expressionByRewritingExpression:expression withEvaluator:evaluator];
        NSNumber *value = [evaluator evaluateExpression:rewritten withSubstitutions:nil error:&error];
        if (value == nil) {
            result = [NSString stringWithFormat:@"%@\n", result];
        } else {
            result = [NSString stringWithFormat:@"%@\n%@", result, [value description]];
        }
    }
    [self.txtAnswer setString:[result stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
}

- (BOOL)control:(NSControl*)control textView:(NSTextView*)textView doCommandBySelector:(SEL)commandSelector
{
    BOOL result = NO;
    if (commandSelector == @selector(insertNewline:))
    {
        [textView insertNewlineIgnoringFieldEditor:self];
        result = YES;
    }
    return result;
}

#pragma mark - Public accessors

- (BOOL)hasActivePanel
{
    return _hasActivePanel;
}

- (void)setHasActivePanel:(BOOL)flag
{
    if (_hasActivePanel != flag)
    {
        _hasActivePanel = flag;
        if (_hasActivePanel)
        {
            [self openPanel];
        }
        else
        {
            [self closePanel];
        }
    }
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification
{
    self.hasActivePanel = NO;
}

- (void)windowDidResignKey:(NSNotification *)notification;
{
    if ([[self window] isVisible])
    {
        self.hasActivePanel = NO;
    }
}

- (void)windowDidResize:(NSNotification *)notification
{
    NSWindow *panel = [self window];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    CGFloat statusX = roundf(NSMidX(statusRect));
    CGFloat panelX = statusX - NSMinX(panelRect);
    self.backgroundView.arrowX = panelX;
    PANEL_WIDTH = panelRect.size.width;
    POPUP_HEIGHT = panelRect.size.height;
    PANEL_OriginX = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
    PANEL_OriginY = NSMaxY(statusRect) - NSHeight(panelRect);
}

#pragma mark - Keyboard

- (void)cancelOperation:(id)sender
{
    self.hasActivePanel = NO;
}

#pragma mark - Public methods

- (NSRect)statusRectForWindow:(NSWindow *)window
{
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = NSZeroRect;
    
    StatusItemView *statusItemView = nil;
    if ([self.delegate respondsToSelector:@selector(statusItemViewForPanelController:)])
    {
        statusItemView = [self.delegate statusItemViewForPanelController:self];
    }
    
    if (statusItemView)
    {
        statusRect = statusItemView.globalRect;
        statusRect.origin.y = NSMinY(statusRect) - NSHeight(statusRect);
    }
    else
    {
        statusRect.size = NSMakeSize(STATUS_ITEM_VIEW_WIDTH, [[NSStatusBar systemStatusBar] thickness]);
        statusRect.origin.x = roundf((NSWidth(screenRect) - NSWidth(statusRect)) / 2);
        statusRect.origin.y = NSHeight(screenRect) - NSHeight(statusRect) * 2;
    }
    return statusRect;
}

- (void)openPanel
{
    NSWindow *panel = [self window];
    [panel setStyleMask:[panel styleMask] | NSResizableWindowMask];
    NSRect screenRect = [[[NSScreen screens] objectAtIndex:0] frame];
    NSRect statusRect = [self statusRectForWindow:panel];
    NSRect panelRect = [panel frame];
    panelRect.size.width = PANEL_WIDTH;
    panelRect.size.height = POPUP_HEIGHT;
    if (PANEL_OriginX == -1) {
        panelRect.origin.x = roundf(NSMidX(statusRect) - NSWidth(panelRect) / 2);
        panelRect.origin.y = NSMaxY(statusRect) - NSHeight(panelRect);
    }
    else {
        panelRect.origin.x = PANEL_OriginX;
        panelRect.origin.y = PANEL_OriginY;
    }
    if (NSMaxX(panelRect) > (NSMaxX(screenRect) - ARROW_HEIGHT))
        panelRect.origin.x -= NSMaxX(panelRect) - (NSMaxX(screenRect) - ARROW_HEIGHT);
    [NSApp activateIgnoringOtherApps:NO];
    [panel setAlphaValue:0];
    [panel setFrame:statusRect display:YES];
    [panel makeKeyAndOrderFront:nil];
    NSTimeInterval openDuration = OPEN_DURATION;
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:openDuration];
    [[panel animator] setFrame:panelRect display:YES];
    [[panel animator] setAlphaValue:1];
    [NSAnimationContext endGrouping];
}

- (void)closePanel
{
    [NSAnimationContext beginGrouping];
    [[NSAnimationContext currentContext] setDuration:CLOSE_DURATION];
    [[[self window] animator] setAlphaValue:0];
    [NSAnimationContext endGrouping];
    dispatch_after(dispatch_walltime(NULL, NSEC_PER_SEC * CLOSE_DURATION * 2), dispatch_get_main_queue(), ^{
        [self.window orderOut:nil];
    });
}

- (void)openOps
{
    [NSApp activateIgnoringOtherApps:YES];
    [_opsWindow center];
    [_opsWindow makeKeyAndOrderFront:self];
    [_opsWindow setIsVisible:YES];
    [self showWindow:_opsWindow];
    [_opsWindow update];
}

@end
