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

#import "NSAttributedStringMarkdownParser.h"

#import "MarkdownTokens.h"
#import <pthread.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "fmemopen.h"

int markdownConsume(char* text, int token, yyscan_t scanner);

@implementation NSAttributedStringMarkdownParser {
  NSMutableArray* _bulletStarts;
  NSMutableArray* _links;
  NSMutableAttributedString* _accum;
}

- (NSAttributedString *)parseString:(NSString *)string links:(NSMutableArray *)links {
  _links = links;
  _bulletStarts = [NSMutableArray array];
  _accum = [[NSMutableAttributedString alloc] init];

  const char* cstr = [string UTF8String];
  FILE* markdownin = fmemopen((void *)cstr, sizeof(char) * (string.length + 1), "r");

  yyscan_t scanner;

  markdownlex_init(&scanner);
  markdownset_extra((void *)CFBridgingRetain(self), scanner);
  markdownset_in(markdownin, scanner);
  markdownlex(scanner);
  markdownlex_destroy(scanner);

  fclose(markdownin);

  if (_bulletStarts.count > 0) {
    // Treat nested bullet points as flat ones...

    // Finish off the previous dash and start a new one.
    NSInteger lastBulletStart = [[_bulletStarts lastObject] intValue];
    [_bulletStarts removeLastObject];
    
    [_accum addAttributes:[self paragraphStyle]
                        range:NSMakeRange(lastBulletStart, _accum.length - lastBulletStart)];
  }

  return [_accum copy];
}

- (NSDictionary *)paragraphStyle {
  CTTextAlignment alignment = kCTLeftTextAlignment;
  CGFloat paragraphSpacing = 0.0;
  CGFloat paragraphSpacingBefore = 0.0;
  CGFloat firstLineHeadIndent = 15.0;
  CGFloat headIndent = 30.0;
  
  CGFloat firstTabStop = 35.0; // width of your indent
  CGFloat lineSpacing = 0.45;
  
  CTTextTabRef tabArray[] = { CTTextTabCreate(0, firstTabStop, NULL) };
  
  CFArrayRef tabStops = CFArrayCreate( kCFAllocatorDefault, (const void**) tabArray, 1, &kCFTypeArrayCallBacks );
  CFRelease(tabArray[0]);
  
  CTParagraphStyleSetting altSettings[] = 
  {
    { kCTParagraphStyleSpecifierLineSpacing, sizeof(CGFloat), &lineSpacing},
    { kCTParagraphStyleSpecifierAlignment, sizeof(CTTextAlignment), &alignment},
    { kCTParagraphStyleSpecifierFirstLineHeadIndent, sizeof(CGFloat), &firstLineHeadIndent},
    { kCTParagraphStyleSpecifierHeadIndent, sizeof(CGFloat), &headIndent},
    { kCTParagraphStyleSpecifierTabStops, sizeof(CFArrayRef), &tabStops},
    { kCTParagraphStyleSpecifierParagraphSpacing, sizeof(CGFloat), &paragraphSpacing},
    { kCTParagraphStyleSpecifierParagraphSpacingBefore, sizeof(CGFloat), &paragraphSpacingBefore}
  }; 
  
  CTParagraphStyleRef style;
  style = CTParagraphStyleCreate( altSettings, sizeof(altSettings) / sizeof(CTParagraphStyleSetting) );
  
  if ( style == NULL )
  {
    NSLog(@"*** Unable To Create CTParagraphStyle in apply paragraph formatting" );
    return nil;
  }
  
  return [NSDictionary dictionaryWithObjectsAndKeys:(__bridge id)style,(NSString*) kCTParagraphStyleAttributeName, nil];
}

- (void)consumeToken:(int)token text:(char*)text {
  NSString* textAsString = [[NSString alloc] initWithCString:text encoding:NSUTF8StringEncoding];

  NSMutableDictionary* attributes = [NSMutableDictionary dictionary];
  switch (token) {
    case MARKDOWNEM: {
      textAsString = [textAsString substringWithRange:NSMakeRange(1, textAsString.length - 2)];

      UIFont* font = [UIFont fontWithName:@"Helvetica-Oblique" size:[UIFont systemFontSize]];
      CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
      [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];
      break;
    }
    case MARKDOWNSTRONG: {
      textAsString = [textAsString substringWithRange:NSMakeRange(2, textAsString.length - 4)];
      
      UIFont* font = [UIFont boldSystemFontOfSize:[UIFont systemFontSize]];
      CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
      [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];
      break;
    }
    case MARKDOWNSTRONGEM: {
      textAsString = [textAsString substringWithRange:NSMakeRange(3, textAsString.length - 6)];
      
      UIFont* font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:[UIFont systemFontSize]];
      CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
      [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];
      break;
    }
    case MARKDOWNHEADER: {
      NSRange rangeOfNonHash = [textAsString rangeOfCharacterFromSet:[[NSCharacterSet characterSetWithCharactersInString:@"#"] invertedSet]];
      if (rangeOfNonHash.length > 0) {
        textAsString = [[textAsString substringFromIndex:rangeOfNonHash.location] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        UIFont* font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:6 - rangeOfNonHash.location + 16];
        CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
        [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];
        textAsString = [textAsString stringByAppendingString:@"\n"];
      }
      break;
    }
    case MARKDOWNMULTILINEHEADER: {
      NSArray* components = [textAsString componentsSeparatedByString:@"\n"];
      textAsString = [components objectAtIndex:0];
      UIFont* font = nil;
      if ([[components objectAtIndex:1] rangeOfString:@"="].length > 0) {
        font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:16];
      } else if ([[components objectAtIndex:1] rangeOfString:@"-"].length > 0) {
        font = [UIFont fontWithName:@"Helvetica-BoldOblique" size:15];
      }
      
      CTFontRef fontRef = CTFontCreateWithName((__bridge CFStringRef)font.fontName, font.pointSize, nil);
      [attributes setObject:(__bridge id)fontRef forKey:(__bridge NSString* )kCTFontAttributeName];

      textAsString = [textAsString stringByAppendingString:@"\n"];
      break;
    }
    case MARKDOWNPARAGRAPH: {
      textAsString = @"\n\n";
      
      if (_bulletStarts.count > 0) {
        // Treat nested bullet points as flat ones...
        
        // Finish off the previous dash and start a new one.
        NSInteger lastBulletStart = [[_bulletStarts lastObject] intValue];
        [_bulletStarts removeLastObject];
        
        [_accum addAttributes:[self paragraphStyle]
                            range:NSMakeRange(lastBulletStart, _accum.length - lastBulletStart)];
      }
      break;
    }
    case MARKDOWNBULLETSTART: {
      NSInteger numberOfDashes = [textAsString rangeOfString:@" "].location;
      if (_bulletStarts.count > 0 && _bulletStarts.count <= numberOfDashes) {
        // Treat nested bullet points as flat ones...

        // Finish off the previous dash and start a new one.
        NSInteger lastBulletStart = [[_bulletStarts lastObject] intValue];
        [_bulletStarts removeLastObject];

        [_accum addAttributes:[self paragraphStyle]
                            range:NSMakeRange(lastBulletStart, _accum.length - lastBulletStart)];
      }

      [_bulletStarts addObject:[NSNumber numberWithInt:_accum.length]];
      textAsString = @"•\t";
      break;
    }
    case MARKDOWNNEWLINE: {
      textAsString = @"";
      break;
    }
    case MARKDOWNURL: {
      [_links addObject:[NSValue valueWithRange:NSMakeRange(_accum.length, textAsString.length)]];
      break;
    }
    case MARKDOWNHREF: {
      NSRange rangeOfRightBracket = [textAsString rangeOfString:@"]"];
      textAsString = [textAsString substringWithRange:NSMakeRange(1, rangeOfRightBracket.location - 1)];
      [_links addObject:[NSValue valueWithRange:NSMakeRange(_accum.length, textAsString.length)]];
      break;
    }
    default: {
      break;
    }
  }

  if (textAsString.length > 0) {
    NSAttributedString* attributedString = [[NSAttributedString alloc] initWithString:textAsString attributes:attributes];
    [_accum appendAttributedString:attributedString];
  }
}

@end

int markdownConsume(char* text, int token, yyscan_t scanner) {
  NSAttributedStringMarkdownParser* string = CFBridgingRelease(markdownget_extra(scanner));
  [string consumeToken:token text:text];
  return 0;
}
