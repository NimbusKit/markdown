//
// Copyright 2013 Jeff Verkoeyen and Matthias Tretter
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

#import "ComplexViewController.h"

#import "NSAttributedStringMarkdownParser.h"
#import "NimbusAttributedLabel.h"


@implementation ComplexViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  NSAttributedStringMarkdownParser* parser = [[NSAttributedStringMarkdownParser alloc] init];
  NSAttributedString* string = [parser attributedStringFromMarkdownString:@"[Sourced from this thread on reddit\'s /r/Assistance subreddit](http://www.reddit.com/r/Assistance/comments/1eqryt/donation_links_to_help_with_the_recovery_from_the/).\n\n[Additional information is available in OSUTechie\'s submission to /r/oklahoma](http://www.reddit.com/r/oklahoma/comments/1epz3w/how_to_help/). \n \nAre you looking to donate to assistance groups to help with the recovery from today\'s horrible tornado? Several links are below. Please let me know if you would like some added, or if there is reason to remove any links.\n \nPlease choose one donation organization below and make a small contribution. Anything helps. I know there\'s a lot of organizations so it\'s a little overwhelming, but please choose one.\n \nIf you are applying to volunteer or donate local goods, [please click here](https://moore.recovers.org). h/t to /u/lifehacked.\n\nDONATION LINKS: \n\n***\n***RED CROSS***\n \n* Text REDCROSS to 90999 ($10)\n* [This website donation link](http://www.redcross.org/charitable-donations). \n* 1-800-RED CROSS (1-800-733-2767); for Spanish speakers, 1-800-257-7575; for TDD, 1-800-220-4095.\n \n***CATHOLIC CHARITIES***\n \n* [Tornado relief donations link](https://ccokc.ejoinme.org/?tabid=406485). Details about Catholic Charities Disaster Recovery Services [is available here](http://catholiccharitiesok.org/index.php?id=31#.UZrpz7V_58F).\n \n***SALVATION ARMY***\n \n* Text “STORM” to 80888 ($10)\n* [Website donation link here](https://donate.salvationarmyusa.org/uss/eds/aok)\n* Call 1-800-SAL-ARMY (1-800-725-2769)\n* Mail check to The Salvation Army PO Box 12600 Oklahoma City, OK 73157 (note: you **must** write \"Oklahoma Tornado Relief\" on the memo line of the check if you donate this way)\n \n***REGIONAL FOOD BANK OF OKLAHOMA***\n \n* Text \"FOOD\" to 32333 ($10)\n* [Website donation link here](https://secure3.convio.net/rfbo/site/Donation2?df_id=1320&amp;1320.donation=form1). Note: seems to be nonspecific to this particular disaster, but it seems likely most/all current funds from the group are headed that way.\n \n***UNITED WAY***\n \n* [Website donation link here](http://www.unitedwayokc.org/give/make-donation)\n* Send check by mail to United Way of Central Oklahoma, P.O. Box 837, Oklahoma City, OK  73101 (note: you **must** write \"May Tornado Relief\" on the memo line of the check if you donate in this fashion)\n \n***FEEDING AMERICA***\n \n>Through its network of more than 200 food banks, Feeding America, whose mission is to \"feed America\'s hungry through a nationwide network of member food banks,\" says it will deliver truckloads of food, water and supplies to communities in need, in Oklahoma, and will also \"set up additional emergency food and supply distribution sites as they are needed.\"\n* They do not have a donation link specific to Oklahoma tornado relief, but you [can donate here](https://secure.feedingamerica.org/site/SPageServer?pagename=giveonline&s_src=WXXOHOME&s_subsrc=About%2520Us).\n \n***OPERATION USA***\n \n>The international relief group, based in Los Angeles, says it is \"readying essential material aid — emergency, shelter and cleaning supplies\" to help Oklahoma\'s community health organizations and schools recover.\n* They do not seem to have a donation link specific to Oklahoma tornado relief. You can [donate through their website here](https://donate.opusa.org/).\n* Text the word AID to 50555 (Note: this is not necessarily specific to Oklahoma tornado victim relief)\n* Send check to: Operation USA, 7421 Beverly Blvd., PH, Los Angeles, CA 90036.\n \n***Oklahoma Baptist Disaster Relief***\n \n* [Website donation link](http://www.okdisasterhelp.com/donate/)\n* Send checks to BGCO, Attn: Disaster Relief, 3800 N. May Ave., Oklahoma City, OK 73112\n \n***TEAM RUBICON***\n\n* [Website donation link](https://fundraise.teamrubiconusa.org/checkout/donation?eid=25140)\n* [Information about the organization can be found here](http://teamrubiconusa.org/donate/).\n\n***\n \n***Unless you are personally affected by this disaster, please do not go to the following link so that server loads can be reserved for individuals who need to use the website***: Please spread this Red Cross website where people can list themselves as safe and well - \n\n    https://safeandwell.communityos.org/cms/index.php\n \n***"];


  UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
  NIAttributedLabel* label = [[NIAttributedLabel alloc] initWithFrame:CGRectMake(0.f, 0.f, CGRectGetWidth(self.view.bounds), 2000.f)];
  label.attributedString = string;
  label.numberOfLines = 0;

  for (NSAttributedStringMarkdownLink* link in parser.links) {
    [label addLink:link.url range:link.range];
  }

  // [label sizeToFit]; // doesn't work?
  [scrollView addSubview:label];
  scrollView.contentSize = CGSizeMake(1.f, label.bounds.size.height);
  [self.view addSubview:scrollView];
}

@end
