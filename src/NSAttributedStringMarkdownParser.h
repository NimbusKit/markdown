//
// Copyright 2012-2013 Jeff Verkoeyen
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, NSAttributedStringMarkdownParserHeader) {
  NSAttributedStringMarkdownParserHeader1 = 1, // value is important, internally used
  NSAttributedStringMarkdownParserHeader2,
  NSAttributedStringMarkdownParserHeader3,
  NSAttributedStringMarkdownParserHeader4,
  NSAttributedStringMarkdownParserHeader5,
  NSAttributedStringMarkdownParserHeader6,
};

@interface NSAttributedStringMarkdownLink : NSObject
@property (nonatomic, readonly, strong) NSURL* url;
@property (nonatomic, readonly, assign) NSRange range;
@property (nonatomic, readonly, copy) NSString *tooltip;
@end

@interface NSAttributedStringMarkdownParser : NSObject <NSCopying>

- (NSMutableAttributedString *)attributedStringFromMarkdownString:(NSString *)string;

@property (nonatomic, strong) UIFont* paragraphFont; // Default: systemFontOfSize:12
@property (nonatomic, copy) NSString* boldFontName; // Default: boldSystemFont
@property (nonatomic, copy) NSString* italicFontName; // Default: Helvetica-Oblique
@property (nonatomic, copy) NSString* boldItalicFontName; // Default: Helvetica-BoldOblique

@property (nonatomic, readonly) NSArray* links; // Array of NSAttributedStringMarkdownLink

/// These CoreText attributes get applied to paragraphs that are recognized as block quotes, e.g.
///
/// >This is a block quote
/// >>This is a block quote on level 2
///
/// The whole paragraph is indented to visualize the quoting, you can further style it by specifying
/// attributes here. Per default the font get's changed to italic and the text color gets set to dark gray.
@property (nonatomic, copy) NSDictionary *blockQuotesAttributes;

- (void)setFont:(UIFont *)font forHeader:(NSAttributedStringMarkdownParserHeader)header;
- (UIFont *)fontForHeader:(NSAttributedStringMarkdownParserHeader)header;

@end
