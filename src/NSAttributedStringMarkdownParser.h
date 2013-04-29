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

typedef enum {
  NSAttributedStringMarkdownParserHeader1,
  NSAttributedStringMarkdownParserHeader2,
  NSAttributedStringMarkdownParserHeader3,
  NSAttributedStringMarkdownParserHeader4,
  NSAttributedStringMarkdownParserHeader5,
  NSAttributedStringMarkdownParserHeader6,

} NSAttributedStringMarkdownParserHeader;

@protocol NSAttributedStringMarkdownStylesheet;

@interface NSAttributedStringMarkdownParser : NSObject

- (NSAttributedString *)attributedStringFromMarkdownString:(NSString *)string links:(NSMutableArray *)links;

@property (nonatomic, strong) UIFont* paragraphFont; // Default: systemFontOfSize:12
@property (nonatomic, strong) NSString* boldFontName; // Default: boldSystemFont
@property (nonatomic, strong) NSString* italicFontName; // Default: Helvetica-Oblique
@property (nonatomic, strong) NSString* boldItalicFontName; // Default: Helvetica-BoldOblique

- (void)setFont:(UIFont *)font forHeader:(NSAttributedStringMarkdownParserHeader)header;
- (UIFont *)fontForHeader:(NSAttributedStringMarkdownParserHeader)header;

@end
