//
//  ViewController.m
//  TweetfavMachine
//
//  Created by 真有 津坂 on 12/05/16.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize keywordInput;
@synthesize tweetIconImg;
@synthesize twAccount;
@synthesize tweetText;

//以下追加
@synthesize userNameArray;
@synthesize tweetTextArray;
@synthesize iconDataArray;
@synthesize encodStr;
@synthesize idDataArray;

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    //データを受け取る準備をする。userNameArrayy・tweetTextArray・iconDataArrayはユーザ名・実際のツイート・アイコン
    accountStore = [[ACAccountStore alloc] init];
    accountType = [accountStore accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];
    
    userNameArray = [[NSMutableArray alloc] initWithCapacity:0];
    tweetTextArray = [[NSMutableArray alloc] initWithCapacity:0];
    iconDataArray = [[NSMutableArray alloc] initWithCapacity:0];
    idDataArray = [[NSMutableArray alloc] initWithCapacity:0];
    
    //最初はユーザ名・テキスト・アイコンの配列の1番目を取得する
    twindex = 1;

}

- (void)viewDidUnload
{
    [self setTweetIconImg:nil];
    [self setTwAccount:nil];
    [self setTweetText:nil];
    [self setKeywordInput:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}


- (IBAction)searchStart:(id)sender {
    //Twitterのタイムラインを取得、整形する
    [self loadTimeline];
    
    //タイマー設定。5秒ごとに- (void)loadTimelineView の内容を繰り返す
    myTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(loadTimelineView) userInfo:nil repeats:YES];
}

//追加、Twitterのタイムラインを取得・整形
- (void)loadTimeline{
    [accountStore requestAccessToAccountsWithType:accountType withCompletionHandler:^(BOOL granted, NSError *error) {
        if (granted) {
            if (account == nil) {
                NSArray *accountArray = [accountStore accountsWithAccountType:accountType];
                account = [accountArray objectAtIndex:0];
            }
            if (account != nil) {
                //ここをTextFieldで入力した言葉ではなく指定したい場合はNSString *searchString = @"ほげほげ";にする
                //検索語を指定する。日本語を検索する場合は、UTF-8でURLエンコードした文字列を渡す
                //英語で入力しても大丈夫
                NSString *searchString = keywordInput.text;
                //UTF-8でURLエンコード
                encodStr = [searchString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                //TwitterのSearchAPIを使用する
                NSString *twurlString = [NSString stringWithFormat:@"http://search.twitter.com/search.json?q=%@rpp=50",encodStr];
                
                //URLWithStringでNSURLのインスタンスを生成
                NSURL *twurl = [NSURL URLWithString:twurlString];
                
                
                
                //NSURLRequestとurlStringで設定したアドレスにアクセスする設定をする
                NSURLRequest *twrequest = [NSURLRequest requestWithURL:twurl];
                //NSURLConnectionで実際にアクセスする
                [NSURLConnection sendAsynchronousRequest:twrequest queue:[NSOperationQueue mainQueue]completionHandler:^(NSURLResponse *twresponse, NSData *twdata, NSError *twerror) {
                    if (twerror) {
                        NSLog(@"error: %@", [twerror localizedDescription]);
                        return;
                    }
                    
                    //jsonで解析する
                    NSDictionary *twdictionary =[NSJSONSerialization JSONObjectWithData:twdata options:NSJSONReadingAllowFragments error:nil];
                    //resultsにTweetが配列の形で入っている
                    NSArray *tweets = [twdictionary objectForKey:@"results"];
                    
                    
                    //Tweetをひとつずつ取り出して表示する準備をする
                    for (NSDictionary *tweet in tweets) {
                        [tweetTextArray addObject:[tweet objectForKey:@"text"]];
                        [userNameArray addObject:[tweet objectForKey:@"from_user_name"]];
                        [iconDataArray addObject:[tweet objectForKey:@"profile_image_url"]];
                        [idDataArray addObject:[tweet objectForKey:@"id"]];
                        
                        
                        
                        
                        
                    }
                    
                    
                }];
            }
        }
    }];
    
}

//5秒ごとにつぶやきを表示(以下の{}内の動作を5秒ごとに繰り返す)
-(void)loadTimelineView {
    twindex = twindex + 1;
    
    //50件表示したら最初から繰り返して表示(ここでAPIにアクセスしてもいいんですが、負荷を考慮して)
   
    if (twindex == 50) {
        
        twindex = 1;
    }   
    
    
    //配列userNameArray(ユーザ名)のtwindex番目(3秒ごとに増えていく。最初は1で次は2)の要素を取り出す
    NSString *twAstr = [userNameArray objectAtIndex:twindex];
    //配列tweetTextArray(テキスト)のtwindex番目(3秒ごとに増えていく。最初は1で次は2)の要素を取り出す
    NSString *twTstr = [tweetTextArray objectAtIndex:twindex];
    //配列iconDataArray(アイコン)のtwindex番目(3秒ごとに増えていく。最初は1で次は2)の要素を取り出す
    NSURL *iconurl = [NSURL URLWithString:[iconDataArray objectAtIndex:twindex]];
    //iconを表示
    NSData *iconData = [NSData dataWithContentsOfURL:iconurl];
    tweetIconImg.image = [UIImage imageWithData:iconData];
    
    //アカウント名を表示
    twAccount.text = twAstr;
    //テキスト表示
    tweetText.text = twTstr;
    
    
}

//お気に入り追加ボタン
  - (IBAction)favButton:(id)sender {
        //今表示されているつぶやきのIDを取得
        NSString *twAstr = [idDataArray objectAtIndex:twindex];
        //「お気に入り」に追加するアドレス
        //リツイートにしたい場合はstringWithFormat:をhttp://api.twitter.com/1/statuses/retweet/%@.jsonにする
        NSString *favurlString = [NSString stringWithFormat:@"http://api.twitter.com/1/favorites/create/%@.json",twAstr];
        
        //parametersをnilにするのがポイント
        TWRequest *postRequest = [[TWRequest alloc] initWithURL:[NSURL URLWithString:favurlString] parameters:nil requestMethod:TWRequestMethodPOST];
        
        //ツイートできるようアカウント等を準備する
        [postRequest setAccount:account];
        
        //ツイートできたかどうか
        [postRequest performRequestWithHandler:^(NSData *responseData, NSHTTPURLResponse *urlResponse, NSError *poerror) {
            NSString *output = [NSString stringWithFormat:@"HTTP response status: %i", [urlResponse statusCode]];
            if ([urlResponse statusCode] == 200) {
                NSLog(@"fav OK");    
                
            } else {
                NSLog(@"fav NG");    
            }
            
            NSLog(@"%@",output);
            
            
        }];

    }

@end
