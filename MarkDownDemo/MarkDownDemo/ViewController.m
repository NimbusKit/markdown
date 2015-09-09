//
//  ViewController.m
//  MarkDownDemo
//
//  Created by tangkunyin on 15/9/8.
//  Copyright (c) 2015年 shuoit. All rights reserved.
//

#import "ViewController.h"
#import "NSAttributedStringMarkdownParser.h"

@interface ViewController ()
@property (nonatomic, strong) UITextView *textView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSAttributedString *attributeString = [self parseMarkDownText:[self getSourceTextFromLocalFile]];
    
    self.textView.attributedText = attributeString;
    
    [self.view addSubview:self.textView];
}

- (NSString *)getSourceTextFromLocalFile
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"MdSource.md" ofType:nil];
    NSString *articleText = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
    return articleText;
}



- (NSAttributedString *)parseMarkDownText:(NSString *)sourceText
{
    if (sourceText) {
        NSAttributedStringMarkdownParser *parser = [[NSAttributedStringMarkdownParser alloc] init];
        NSAttributedString *string = [parser attributedStringFromMarkdownString:sourceText];
        return string;
    }
    return nil;
}

#pragma mark - getter
- (UITextView *)textView
{
    if (_textView == nil) {
        _textView = [[UITextView alloc] init];
        _textView.editable = NO;
        _textView.backgroundColor = [UIColor orangeColor];
        _textView.frame = CGRectMake(0, 20, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame));
    }
    return _textView;
}

@end
