//
//  ViewController.m
//  TTSBackPlayerLocation
//
//  Created by 李闯 on 2021/2/4.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import <CoreLocation/CoreLocation.h>

@interface ViewController ()<AVSpeechSynthesizerDelegate>


@property (nonatomic, strong) AVSpeechSynthesizer *synthesizer;

@property (nonatomic, strong) CLLocationManager *locationManager;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    // 模拟socket 接收消息
    [self socketReceiveMessage];
    [self logTime];
    [self registerAllNotifications];
}

#pragma mark - 监听APP进入前/后台(处理APP进入后台，音乐播放暂停问题)
- (void)registerAllNotifications
{
    // 后台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apllicationWillResignActiveNotification:) name:UIApplicationWillResignActiveNotification object:nil];

    // 进入前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(apllicationWillEnterForegroundNotification:) name:UIApplicationWillEnterForegroundNotification object:nil];
}


#pragma mark - 移除监听
- (void)removeAllNotifications {

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillEnterForegroundNotification object:nil];

}

#pragma mark - 进入后台通知
- (void)apllicationWillResignActiveNotification:(NSNotification *)n
{
    NSLog(@"进入后台");
    
    NSError *error = nil;
    // 后台播放代码
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:&error];
    if(error) {
        NSLog(@"ListenPlayView background error0: %@", error.description);
    }
    //后台播放
    [session setCategory:AVAudioSessionCategoryPlayback error:&error];
//    [session setCategory:AVAudioSessionCategoryPlayback mode:AVAudioSessionModeMoviePlayback options:AVAudioSessionCategoryOptionMixWithOthers error:&error];
    if(error) {
        NSLog(@"ListenPlayView background error1: %@", error.description);
    }
    //开启后台处理多媒体事件
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self keepBackgroundTask];
}

#pragma mark - 申请30秒
- (UIBackgroundTaskIdentifier)backgroundPlayerID:(UIBackgroundTaskIdentifier)backTaskId
{
    NSError *error = nil;
    // 设置并激活音频会话类别
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setActive:YES error:nil];
    if(error) {
        NSLog(@"ListenPlayView background error3: %@", error.description);
    }
    [session setCategory:AVAudioSessionCategoryPlayback error:nil];
    if(error) {
        NSLog(@"ListenPlayView background error2: %@", error.description);
    }
    // 允许应用程序接收远程控制
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

    // 设置后台任务ID
    UIBackgroundTaskIdentifier newTaskId = UIBackgroundTaskInvalid;
    
    newTaskId = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];
    
    if(newTaskId != UIBackgroundTaskInvalid && backTaskId != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:backTaskId];
    }

    return newTaskId;
}

#pragma mark - 进入前台通知
- (void)apllicationWillEnterForegroundNotification:(NSNotification *)n {
    // 进前台 设置不接受远程控制
    [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
    NSLog(@"进入前台");
}



- (void)keepBackgroundTask
{
    if (!self.locationManager) {
        self.locationManager = [[CLLocationManager alloc] init];
        self.locationManager.delegate = self;
        [self.locationManager setDesiredAccuracy:kCLLocationAccuracyBest];
        [self.locationManager requestAlwaysAuthorization];
        self.locationManager.allowsBackgroundLocationUpdates = YES;
        self.locationManager.pausesLocationUpdatesAutomatically = NO;
    }
    
    NSLog(@"开始定位");
     [self.locationManager startUpdatingLocation];
}



- (void)logTime
{
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (ino64_t)(1 * NSEC_PER_SEC));
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(time, dispatch_get_main_queue(), ^{
        NSLog(@"%f", [[NSDate date] timeIntervalSinceNow]);
        [weakSelf logTime];
    });
}

#pragma mark - 模拟socket接收消息
- (void)socketReceiveMessage
{
    int number = random() % 60+60;
    NSLog(@"%d 秒后 tts播报", number);
    dispatch_time_t time = dispatch_time(DISPATCH_TIME_NOW, (ino64_t)(number * NSEC_PER_SEC));
    
    __weak __typeof__(self) weakSelf = self;
    dispatch_after(time, dispatch_get_main_queue(), ^{
        [weakSelf speekWithString: [NSString stringWithFormat:@"新客户来了 %ld", random() % 100]];
        
        NSLog(@"%f", [[NSDate date] timeIntervalSinceNow]);
        [weakSelf socketReceiveMessage];
    });
}

#pragma mark - 初始化tts播放器
-(AVSpeechSynthesizer *)synthesizer
{
    if (!_synthesizer) {
        _synthesizer = [[AVSpeechSynthesizer alloc]init];
        _synthesizer.delegate = self;
    }
    return _synthesizer;
}

#pragma mark - tts播报
- (void)speekWithString:(NSString *)value
{
    AVSpeechUtterance *utterance = [AVSpeechUtterance speechUtteranceWithString:value];
    utterance.pitchMultiplier=0.8;
    //中式发音
    AVSpeechSynthesisVoice *voice = [AVSpeechSynthesisVoice voiceWithLanguage:@"zh-CN"];
    utterance.voice = voice;
    [self.synthesizer speakUtterance:utterance];
}

#pragma mark - AVSpeechSynthesizerDelegate
- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didStartSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"开始tts播报");
}

- (void)speechSynthesizer:(AVSpeechSynthesizer *)synthesizer didFinishSpeechUtterance:(AVSpeechUtterance *)utterance
{
    NSLog(@"结束tts播报");
}


@end
