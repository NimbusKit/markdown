//
//  MarkdownOSXTests.m
//  MarkdownOSXTests
//
//  Created by Stefan Paychère on 31/03/14.
//  Copyright (c) 2014 Epyx SA. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSAttributedStringMarkdownParser.h"

@interface MarkdownOSXTests : XCTestCase

@end

@implementation MarkdownOSXTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testMarkdown
{
    NSString *testString = @"# Header 1\n"\
    "## Header 2\n"\
    "### Header 3\n"\
    "#### Header 4\n"\
    "##### Header 5\n"\
    "###### Header 6\n"\
    "\n"\
    "*italics*\n"\
    "**bold**\n"\
    "***bold italic***\n"\
    "~~strikethrough~~\n"\
    "\n"\
    "http://google.com urls\n"\
    "[Text] (http://apple.com \"alt text\") urls\n";
    
    NSAttributedStringMarkdownParser *parser = [[NSAttributedStringMarkdownParser alloc]init];
    
    NSAttributedString *result = [parser attributedStringFromMarkdownString:testString];
    XCTAssertNotNil(result, @"parser should return something");
    XCTAssertTrue([result isKindOfClass:[NSAttributedString class]], @"Result should be an NSAttributedString");
    //TODO: Add some content checking
    
    NSArray *links = [parser links];
    XCTAssertNotNil(links, @"parser should return an Array of links");
    XCTAssertTrue([links isKindOfClass:[NSArray class]], @"links should be an NSArray");
    XCTAssertTrue([links count] == 2, @"There should be 2 links in the sample text");
    
    NSAttributedStringMarkdownLink *link = [links objectAtIndex:0];
    XCTAssertTrue([link isKindOfClass:[NSAttributedStringMarkdownLink class]], @"link should be an NSAttributedStringMarkdownLink");
    XCTAssertNotNil(link.url, @"There should be an NSURL attribute");
    XCTAssertTrue([link.url isKindOfClass:[NSURL class]], @"link should be an NSURL");
    XCTAssertTrue([link.url isEqualTo:[NSURL URLWithString:@"http://google.com"]], @"URL should point to http://google.com (%@)", link.url);
    XCTAssertTrue(link.range.location == 100, @"range.location should be 100 (%lu)", (unsigned long)link.range.location);
    XCTAssertTrue(link.range.length == 17, @"range.length should be 17 (%lu)", (unsigned long)link.range.length);
    
    link = [links objectAtIndex:1];
    XCTAssertTrue([link isKindOfClass:[NSAttributedStringMarkdownLink class]], @"link should be an NSAttributedStringMarkdownLink");
    XCTAssertNotNil(link.url, @"There should be an NSURL attribute");
    XCTAssertTrue([link.url isKindOfClass:[NSURL class]], @"link should be an NSURL");
    XCTAssertTrue([link.url isEqualTo:[NSURL URLWithString:@"http://apple.com"]], @"URL should point to http://apple.com (%@)", link.url);
    XCTAssertTrue(link.range.location == 131, @"range.location should be 100 (%lu)", (unsigned long)link.range.location);
    XCTAssertTrue(link.range.length == 16, @"range.length should be 17 (%lu)", (unsigned long)link.range.length);
}

@end
