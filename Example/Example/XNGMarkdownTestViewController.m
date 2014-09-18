#import "XNGMarkdownTestViewController.h"
#import <XNGMarkdownParser/NSAttributedStringMarkdownParser.h>

@interface XNGMarkdownTestViewController ()

@property (strong, nonatomic) UITextView *textView;

@end

@implementation XNGMarkdownTestViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setupTextView];

    NSString * markdown = @"normal text with **bold** and (31231) [link](http://www.xing.com) with some more text\n";

    NSUInteger times = 1000;
    NSMutableString * accum = [[NSMutableString alloc] initWithCapacity:times*markdown.length];
    for(NSUInteger i=0; i<times; ++i) {
        [accum appendString:markdown];
    }

    NSLog(@"BEGIN, parsing string...");
    NSDate * begin = [NSDate date];

    NSAttributedStringMarkdownParser * parser =[[NSAttributedStringMarkdownParser alloc] init];

    NSMutableParagraphStyle * para = [[NSMutableParagraphStyle alloc] init];
    para.minimumLineHeight = 50;

    NSAttributedString * attr = [parser attributedStringFromMarkdownString:accum];

    NSDate * end = [NSDate date];
    NSTimeInterval timeDif = end.timeIntervalSince1970 - begin.timeIntervalSince1970;
    NSLog(@"time to format: %.0f ms", timeDif*1000);
    
    self.textView.attributedText = attr;
}

- (void)setupTextView {
    self.textView = [[UITextView alloc] initWithFrame:CGRectZero];
    [self.view addSubview:self.textView];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    CGRect frame = self.view.frame;
    frame.origin.y = 20;
    frame.size.height -= 20;
    self.textView.frame = frame;
}

@end
