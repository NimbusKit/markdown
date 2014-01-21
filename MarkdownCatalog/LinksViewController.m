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

#import "LinksViewController.h"

#import "NSAttributedStringMarkdownParser.h"
#import "NimbusAttributedLabel.h"

@implementation LinksViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  NSAttributedStringMarkdownParser* parser = [[NSAttributedStringMarkdownParser alloc] init];
  NSAttributedString* string = [parser attributedStringFromMarkdownString:
                                @"Here's a link to nimbus: http://www.nimbuskit.info\n"
                                @"And a link to github: http://www.github.com\n"
                                @"[A link to MTDirectionsKit](http://mtdirectionsk.it)\n"
                                @"[And another link](http://twitter.com/myell0w 'myell0w on twitter')"];

  NIAttributedLabel* label = [[NIAttributedLabel alloc] init];
  label.attributedString = string;
  label.numberOfLines = 0;
  label.frame = self.view.bounds;
  [self.view addSubview:label];

  for (NSAttributedStringMarkdownLink* link in parser.links) {
    [label addLink:link.url range:link.range];
  }
}

// For iOS 7 layouts causing the views to appear beneath the nav bar.
- (UIRectEdge)edgesForExtendedLayout {
  return UIRectEdgeNone;
}

@end
