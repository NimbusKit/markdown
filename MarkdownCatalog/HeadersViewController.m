//
// Copyright 2013 Jeff Verkoeyen
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

#import "HeadersViewController.h"

#import "NSAttributedStringMarkdownParser.h"
#import "NimbusAttributedLabel.h"

@implementation HeadersViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  NSAttributedStringMarkdownParser* parser = [[NSAttributedStringMarkdownParser alloc] init];
  NSMutableArray* links = [NSMutableArray array];
  NSAttributedString* string = [parser attributedStringFromMarkdownString:
                                @"# Header 1\n"
                                @"Paragraph text that will likely wrap around the screen a little bit\n"
                                @"## Header 2\n"
                                @"Paragraph text that will likely wrap around the screen a little bit\n"
                                @"### Header 3\n"
                                @"Paragraph text that will likely wrap around the screen a little bit\n"
                                @"#### Header 4\n"
                                @"Paragraph text that will likely wrap around the screen a little bit\n"
                                @"##### Header 5\n"
                                @"Paragraph text that will likely wrap around the screen a little bit\n"
                                @"###### Header 6\n"
                                @"Paragraph text that will likely wrap around the screen a little bit\n"];

  NIAttributedLabel* label = [[NIAttributedLabel alloc] init];
  label.attributedString = string;
  label.numberOfLines = 0;
  label.frame = self.view.bounds;
  [self.view addSubview:label];

  for (NSValue* rangeValue in links) {
    NSRange range = [rangeValue rangeValue];
    NSString* linkString = [string.string substringWithRange:range];
    [label addLink:[NSURL URLWithString:linkString] range:range];
  }
}

@end
