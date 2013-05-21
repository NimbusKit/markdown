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

#import "CatalogViewController.h"

// Controllers
#import "EmphasisViewController.h"
#import "HeadersViewController.h"
#import "LinksViewController.h"
#import "ParagraphsViewController.h"
#import "ComplexViewController.h"

#import "NimbusModels.h"

@implementation CatalogViewController {
  NITableViewModel* _model;
  NITableViewActions* _actions;
}

- (id)initWithStyle:(UITableViewStyle)style {
  if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
    self.title = @"Catalog";

    _actions = [[NITableViewActions alloc] initWithTarget:self];

    NSArray* contents =
  @[[_actions attachToObject:[NITitleCellObject objectWithTitle:@"Emphasis"]
     navigationBlock:NIPushControllerAction([EmphasisViewController class])],
    [_actions attachToObject:[NITitleCellObject objectWithTitle:@"Headers"]
             navigationBlock:NIPushControllerAction([HeadersViewController class])],
    [_actions attachToObject:[NITitleCellObject objectWithTitle:@"Links"]
             navigationBlock:NIPushControllerAction([LinksViewController class])],
    [_actions attachToObject:[NITitleCellObject objectWithTitle:@"Paragraphs"]
             navigationBlock:NIPushControllerAction([ParagraphsViewController class])],
    [_actions attachToObject:[NITitleCellObject objectWithTitle:@"Complex"]
             navigationBlock:NIPushControllerAction([ComplexViewController class])]
    ];
    _model = [[NITableViewModel alloc] initWithSectionedArray:contents
                                                     delegate:(id)[NICellFactory class]];
  }
  return self;
}

- (void)viewDidLoad {
  [super viewDidLoad];

  self.tableView.dataSource = _model;
  self.tableView.delegate = [_actions forwardingTo:self];
}

@end
