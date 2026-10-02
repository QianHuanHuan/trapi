#import <UIKit/UIKit.h>

@interface PPOPassthroughView : UIView
@end

@implementation PPOPassthroughView
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    UIView *hit = [super hitTest:point withEvent:event];
    return hit == self ? nil : hit;
}
@end

@interface PPOOverlayController : UIViewController
@property(nonatomic, strong) UIButton *bubble;
@property(nonatomic, strong) UIView *panel;
@end

@implementation PPOOverlayController
- (void)loadView {
    PPOPassthroughView *root = [[PPOPassthroughView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    root.backgroundColor = UIColor.clearColor;
    self.view = root;

    self.bubble = [UIButton buttonWithType:UIButtonTypeSystem];
    self.bubble.frame = CGRectMake(0, 0, 56, 56);
    self.bubble.layer.cornerRadius = 28;
    self.bubble.backgroundColor = [UIColor colorWithRed:0.31 green:0.29 blue:0.92 alpha:0.96];
    [self.bubble setTitle:@"AI" forState:UIControlStateNormal];
    [self.bubble setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.bubble.titleLabel.font = [UIFont boldSystemFontOfSize:17];
    self.bubble.accessibilityLabel = @"Pocket Agent 浮球，轻点展开，拖动移动";
    [self.view addSubview:self.bubble];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(moveBubble:)];
    pan.cancelsTouchesInView = NO;
    [self.bubble addGestureRecognizer:pan];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(togglePanel)];
    [tap requireGestureRecognizerToFail:pan];
    [self.bubble addGestureRecognizer:tap];

    self.panel = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 258, 132)];
    self.panel.backgroundColor = [UIColor colorWithWhite:0.12 alpha:0.96];
    self.panel.layer.cornerRadius = 18;
    self.panel.layer.shadowColor = UIColor.blackColor.CGColor;
    self.panel.layer.shadowOpacity = 0.24;
    self.panel.layer.shadowRadius = 12;
    self.panel.hidden = YES;
    [self.view addSubview:self.panel];

    UILabel *title = [[UILabel alloc] initWithFrame:CGRectMake(16, 14, 220, 26)];
    title.text = @"全局浮层验证";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont boldSystemFontOfSize:16];
    [self.panel addSubview:title];

    UILabel *detail = [[UILabel alloc] initWithFrame:CGRectMake(16, 42, 226, 36)];
    detail.text = @"已在 SpringBoard 显示。此 PoC 不读取屏幕，也不联网。";
    detail.textColor = [UIColor colorWithWhite:0.88 alpha:1];
    detail.font = [UIFont systemFontOfSize:12];
    detail.numberOfLines = 2;
    [self.panel addSubview:detail];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.frame = CGRectMake(14, 86, 230, 34);
    close.backgroundColor = [UIColor colorWithRed:0.31 green:0.29 blue:0.92 alpha:1];
    close.layer.cornerRadius = 10;
    [close setTitle:@"关闭面板" forState:UIControlStateNormal];
    [close setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    [close addTarget:self action:@selector(togglePanel) forControlEvents:UIControlEventTouchUpInside];
    [self.panel addSubview:close];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    if (CGPointEqualToPoint(self.bubble.center, CGPointZero)) {
        self.bubble.center = CGPointMake(CGRectGetWidth(self.view.bounds) - 38,
                                         CGRectGetHeight(self.view.bounds) * 0.52);
    }
    [self positionPanel];
}

- (void)togglePanel {
    self.panel.hidden = !self.panel.hidden;
    [self positionPanel];
}

- (void)moveBubble:(UIPanGestureRecognizer *)pan {
    CGPoint translation = [pan translationInView:self.view];
    CGPoint center = self.bubble.center;
    center.x += translation.x;
    center.y += translation.y;
    CGFloat half = CGRectGetWidth(self.bubble.bounds) / 2.0;
    center.x = MIN(MAX(half, center.x), CGRectGetWidth(self.view.bounds) - half);
    center.y = MIN(MAX(half + 8, center.y), CGRectGetHeight(self.view.bounds) - half - 8);
    self.bubble.center = center;
    [pan setTranslation:CGPointZero inView:self.view];
    [self positionPanel];
}

- (void)positionPanel {
    CGFloat x = MIN(MAX(12, self.bubble.center.x - CGRectGetWidth(self.panel.bounds) + 28),
                    CGRectGetWidth(self.view.bounds) - CGRectGetWidth(self.panel.bounds) - 12);
    CGFloat y = MIN(MAX(56, self.bubble.center.y - CGRectGetHeight(self.panel.bounds) - 36),
                    CGRectGetHeight(self.view.bounds) - CGRectGetHeight(self.panel.bounds) - 48);
    self.panel.frame = CGRectMake(x, y, CGRectGetWidth(self.panel.bounds), CGRectGetHeight(self.panel.bounds));
}
@end

static UIWindow *PPOOverlayWindow;

%ctor {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (PPOOverlayWindow) return;
        PPOOverlayController *controller = [PPOOverlayController new];
        PPOOverlayWindow = [[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
        PPOOverlayWindow.rootViewController = controller;
        PPOOverlayWindow.backgroundColor = UIColor.clearColor;
        PPOOverlayWindow.windowLevel = UIWindowLevelAlert + 1;
        PPOOverlayWindow.hidden = NO;
    });
}
