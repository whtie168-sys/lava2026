//
//  ChatInputBar.m
//  WFChat UIKit
//
//  Created by WF Chat on 2017/10/28.
//  Copyright © 2017年 WildFireChat. All rights reserved.
//
#import <AVFoundation/AVFoundation.h>
#import <CoreText/CoreText.h>
#import "WDCARChatInputBar.h"

#import "WDCARFaceBoard.h"
#import "WDCARVoiceRecordView.h"
#import "WDCARPluginBoardView.h"
#import "QWERUtilities.h"
#import "WDCARLocationViewController.h"
#import "WDCARLocationPoint.h"
#import "UIView+Toast.h"
#import <LavaWFChatClient/WFCChatClient.h>
#import "FRSDAContactListVC.h"
#import "MBProgressHUD.h"
#import "UIColor+YH.h"
#import "WDCARPublicMenuButton.h"
#if WFCU_SUPPORT_VOIP
#import <Chat86AVEngineKit/Chat86AVEngineKit.h>
#endif
#import <Photos/Photos.h>
#import "QWASZShareMessageView.h"
#import "TYAlertController.h"
#import "UIView+TYAlertView.h"
#import <ZLPhotoBrowser/ZLPhotoBrowser-Swift.h>
#import "QWERConfigManager.h"
#import "QWERImage.h"

#import "WDCARTextView.h"

//#import <WildFireChat/HESIXCGATContactVC.h>

#define CHAT_INPUT_BAR_PADDING 8
#define CHAT_INPUT_BAR_ICON_SIZE (CHAT_INPUT_BAR_HEIGHT - CHAT_INPUT_BAR_PADDING - CHAT_INPUT_BAR_PADDING)

#define CHAT_INPUT_QUOTE_PADDING 5


#import "QWASZShareCardsPopView.h"

@implementation WFCUMetionInfo
- (instancetype)initWithType:(int)type target:(NSString *)target range:(NSRange)range {
    self = [super init];
    if (self) {
        self.mentionType = type;
        self.target = target;
        self.range = range;
    }
    return self;
}
-(void)setRange:(NSRange)range {
    _range = range;
}
@end

//@implementation TextInfo
//
//@end
@interface WDCARChatInputBar () <UITextViewDelegate, WDCARFaceBoardDelegate, UINavigationControllerDelegate, UIImagePickerControllerDelegate, AVAudioRecorderDelegate, AVAudioPlayerDelegate, WDCARPluginBoardViewDelegate, LocationViewControllerDelegate, UIActionSheetDelegate, UIDocumentPickerDelegate, WDCARPublicMenuButtonDelegate, WDCARTextViewDelegate>
{
    BOOL _isChinese;
    BOOL _isLineFeed; // 0510 新增 是否换行标志
}
@property (nonatomic, assign)BOOL textInput;
@property (nonatomic, assign)BOOL voiceInput;
@property (nonatomic, assign)BOOL emojInput;
@property (nonatomic, assign)BOOL pluginInput;

@property (nonatomic, strong)UIButton *publicSwitchBtn;
@property (nonatomic, strong)UIButton *voiceSwitchBtn;
@property (nonatomic, strong)UIButton *emojSwitchBtn;
@property (nonatomic, strong)UIButton *pluginSwitchBtn;

@property (nonatomic, assign) NSInteger cursorPosition;
@property (nonatomic, strong)WDCARTextView *textInputView;
@property (nonatomic, strong)UIView *inputCoverView;

@property (nonatomic, strong)UIButton *voiceInputBtn;

@property (nonatomic, strong)UIView *inputContainer;
@property (nonatomic, strong)UIView *publicContainer;

@property (nonatomic, strong)UIView *emojInputView;
@property (nonatomic, strong)UIView *pluginInputView;

@property (nonatomic, strong)UIView *asoucQuoteContainerView;
@property (nonatomic, strong)UILabel *asoucQuoteLabel;
@property (nonatomic, strong)UIButton *quoteDeleteBtn;

@property(nonatomic, weak)id<WDCARChatInputBarDelegate> delegate;

@property (nonatomic, strong)WDCARVoiceRecordView *recordView;

@property(nonatomic) AVAudioRecorder *recorder;
@property(nonatomic) NSTimer *recordingTimer;
@property(nonatomic) NSTimer *updateMeterTimer;
@property(nonatomic, assign) int seconds;
@property(nonatomic) BOOL recordCanceled;

@property(nonatomic, weak)UIView *parentView;

@property (nonatomic, strong)NSMutableArray<WFCUMetionInfo *> *mentionInfos;
@property (nonatomic, strong)WFCCConversation *conversation;

@property (nonatomic, assign)double lastTypingTime;

@property (nonatomic, strong)UIColor *textInputViewTintColor;

@property (nonatomic, assign)CGRect backupFrame;

@property (nonatomic, strong)WFCCQuoteInfo *quoteInfo;

@property(nonatomic, strong)NSTimer *saveDraftTimer;

@property(nonatomic, strong)NSMutableArray<WDCARPublicMenuButton *> *menuButtons;
@end

@implementation WDCARChatInputBar
- (instancetype)initWithSuperView:(UIView *)parentView conversation:(WFCCConversation *)conversation delegate:(id<WDCARChatInputBarDelegate>)delegate {
    self = [super initWithFrame:CGRectMake(0, parentView.bounds.size.height - CHAT_INPUT_BAR_HEIGHT, parentView.bounds.size.width, CHAT_INPUT_BAR_HEIGHT)];
    if (self) {
        [parentView addSubview:self];
        _isChinese = [WFCCIMService.main isChinese];
        self.delegate = delegate;
        self.parentView = parentView;
        self.mentionInfos = [[NSMutableArray alloc] init];
        self.conversation = conversation;
        self.lastTypingTime = 0;
        self.backupFrame = CGRectZero;
        [self initSubViews];
        self.cursorPosition = 0;
        _isLineFeed = NO;
    }
    return self;
}

- (void)initSubViews {
    _isChinese = [WFCCIMService.main isChinese];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillShow:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidHide:) name:UIKeyboardDidHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onAppResume)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    self.backgroundColor = [UIColor colorWithHexString:@"0xf7f7f7"];
    
    
    NSArray<WFCCChannelMenu *> *menus = nil;
    if (self.conversation.type == Channel_Type) {
        WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:self.conversation.target refresh:NO];
        menus = channelInfo.menus;
    }
    
    CGRect parentRect = self.bounds;
    
    
    if (menus.count) {
        self.publicSwitchBtn = [[UIButton alloc] initWithFrame:CGRectMake(CHAT_INPUT_BAR_PADDING, CHAT_INPUT_BAR_PADDING, CHAT_INPUT_BAR_ICON_SIZE, CHAT_INPUT_BAR_ICON_SIZE)];
        [self.publicSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_keyboard"] forState:UIControlStateNormal];
        [self.publicSwitchBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [self.publicSwitchBtn addTarget:self action:@selector(onSwitchBtn:) forControlEvents:UIControlEventTouchDown];
        [self addSubview:self.publicSwitchBtn];
        
        UIView *split = [[UIView alloc] initWithFrame:CGRectMake(CHAT_INPUT_BAR_PADDING + CHAT_INPUT_BAR_ICON_SIZE + CHAT_INPUT_BAR_PADDING/2, parentRect.size.height/2 - CHAT_INPUT_BAR_ICON_SIZE/2, 1, CHAT_INPUT_BAR_ICON_SIZE)];
        split.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
        [self addSubview:split];
        
        self.publicContainer = [[UIView alloc] initWithFrame:CGRectMake(CHAT_INPUT_BAR_PADDING + CHAT_INPUT_BAR_ICON_SIZE + CHAT_INPUT_BAR_PADDING/2+1, 0, parentRect.size.width - (CHAT_INPUT_BAR_PADDING + CHAT_INPUT_BAR_ICON_SIZE + CHAT_INPUT_BAR_PADDING/2+1), parentRect.size.height)];
        self.inputContainer = [[UIView alloc] initWithFrame:CGRectMake(CHAT_INPUT_BAR_PADDING + CHAT_INPUT_BAR_ICON_SIZE + CHAT_INPUT_BAR_PADDING/2+1, 0, parentRect.size.width - (CHAT_INPUT_BAR_PADDING + CHAT_INPUT_BAR_ICON_SIZE + CHAT_INPUT_BAR_PADDING/2+1), parentRect.size.height)];
        [self addSubview:self.publicContainer];
        [self addSubview:self.inputContainer];
        
        self.inputContainer.hidden = YES;
        [self setupInputContainer:YES];
        [self setupPublicContainer:menus];
    } else {
        self.inputContainer = [[UIView alloc] initWithFrame:CGRectMake(0, 0, parentRect.size.width, parentRect.size.height)];
        [self addSubview:self.inputContainer];
        [self setupInputContainer:NO];
    }
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event{
    UIView *view = [super hitTest:point withEvent:event];
    if (view == nil) {
        for (WDCARPublicMenuButton *menuButton in self.menuButtons) {
            CGPoint tempPoint = [menuButton convertPoint:point fromView:self];

            view = [menuButton hitTest:tempPoint withEvent:event];
            if (view ) {
                return view;
            }
        }
    }
    return view;
}

- (void)onAppResume {
    if((self.inputBarStatus == ChatInputBarKeyboardStatus || self.inputBarStatus == ChatInputBarEmojiStatus || self.inputBarStatus == ChatInputBarPluginStatus) && ![self.textInputView isFirstResponder]) {
        [self.textInputView becomeFirstResponder];
    }
}

- (void)setupPublicContainer:(NSArray<WFCCChannelMenu *> *)menus {
    CGRect parentRect = self.publicContainer.bounds;
    CGFloat butWidth = (parentRect.size.width - (menus.count - 1) * 1)/menus.count;
    self.menuButtons = [[NSMutableArray alloc] init];
    for (int i = 0; i < menus.count; ++i) {
        WDCARPublicMenuButton *menuButton = [[WDCARPublicMenuButton alloc] initWithFrame:CGRectMake(butWidth * i + (i > 0 ? (i-1):0), 0, butWidth, parentRect.size.height)];
        [menuButton setChannelMenu:[menus objectAtIndex:i] isSubMenu:NO];
        menuButton.delegate = self;
        [self.menuButtons addObject:menuButton];
        
        [self.publicContainer addSubview:menuButton];
        if (i > 0) {
            UIView *split = [[UIView alloc] initWithFrame:CGRectMake(i * butWidth, parentRect.size.height/2 - CHAT_INPUT_BAR_ICON_SIZE/2, 1, CHAT_INPUT_BAR_ICON_SIZE)];
            split.backgroundColor = [UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1];
            [self.publicContainer addSubview:split];
        }
    }
    _inputBarStatus = ChatInputBarPublicStatus;
}

- (void)setupInputContainer:(BOOL)hasPublic {
    CGRect parentRect = self.inputContainer.bounds;
    CGFloat asouVoiceBtnPaddingLeft = hasPublic ? CHAT_INPUT_BAR_PADDING/2 : CHAT_INPUT_BAR_PADDING;
    
    CGFloat voiceAndPttOffset;
    self.voiceSwitchBtn = [[UIButton alloc] initWithFrame:CGRectMake(asouVoiceBtnPaddingLeft, CHAT_INPUT_BAR_PADDING, CHAT_INPUT_BAR_ICON_SIZE, CHAT_INPUT_BAR_ICON_SIZE)];
    [self.voiceSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_voice"] forState:UIControlStateNormal];
    [self.voiceSwitchBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.voiceSwitchBtn addTarget:self action:@selector(onSwitchBtn:) forControlEvents:UIControlEventTouchDown];
    [self.inputContainer addSubview:self.voiceSwitchBtn];
    voiceAndPttOffset = asouVoiceBtnPaddingLeft + CHAT_INPUT_BAR_ICON_SIZE;
    
    
    self.pluginSwitchBtn = [[UIButton alloc] initWithFrame:CGRectMake(parentRect.size.width - CHAT_INPUT_BAR_HEIGHT + CHAT_INPUT_BAR_PADDING, CHAT_INPUT_BAR_PADDING, CHAT_INPUT_BAR_ICON_SIZE, CHAT_INPUT_BAR_ICON_SIZE)];
    [self.pluginSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_plugin"] forState:UIControlStateNormal];
    [self.pluginSwitchBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.pluginSwitchBtn addTarget:self action:@selector(onSwitchBtn:) forControlEvents:UIControlEventTouchDown];
    [self.inputContainer addSubview:self.pluginSwitchBtn];
    
    self.emojSwitchBtn = [[UIButton alloc] initWithFrame:CGRectMake(parentRect.size.width - CHAT_INPUT_BAR_HEIGHT - CHAT_INPUT_BAR_ICON_SIZE, CHAT_INPUT_BAR_PADDING, CHAT_INPUT_BAR_ICON_SIZE, CHAT_INPUT_BAR_ICON_SIZE)];
    [self.emojSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_emoj"] forState:UIControlStateNormal];
    [self.emojSwitchBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.emojSwitchBtn addTarget:self action:@selector(onSwitchBtn:) forControlEvents:UIControlEventTouchDown];
    [self.inputContainer addSubview:self.emojSwitchBtn];

    self.textInputView = [[WDCARTextView alloc] initWithFrame:CGRectMake(voiceAndPttOffset + CHAT_INPUT_BAR_PADDING, CHAT_INPUT_BAR_PADDING, self.inputContainer.bounds.size.width - voiceAndPttOffset - CHAT_INPUT_BAR_PADDING - CHAT_INPUT_BAR_HEIGHT - CHAT_INPUT_BAR_HEIGHT + CHAT_INPUT_BAR_PADDING, CHAT_INPUT_BAR_ICON_SIZE)];
    
    self.textInputView.wdcarDelegate = self;
    self.textInputView.delegate = self;
    self.textInputView.layoutManager.allowsNonContiguousLayout = NO;
    [self.textInputView setExclusiveTouch:YES];
    [self.textInputView setTextColor:[UIColor blackColor]];
    [self.textInputView setFont:[UIFont systemFontOfSize:16]];
    [self.textInputView setReturnKeyType:UIReturnKeySend];
    self.textInputView.backgroundColor = [UIColor whiteColor];
    self.textInputView.enablesReturnKeyAutomatically = YES;
    self.textInputView.userInteractionEnabled = YES;
    [self.inputContainer addSubview:self.textInputView];
    
    self.inputCoverView = [[UIView alloc] initWithFrame:self.textInputView.bounds];
    self.inputCoverView.backgroundColor = [UIColor clearColor];
    [self.textInputView addSubview:self.inputCoverView];
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onTapInputView:)];
        tap.numberOfTapsRequired = 1;
        [self.inputCoverView addGestureRecognizer:tap];
    
    
    self.voiceInputBtn = [[UIButton alloc] initWithFrame:self.textInputView.frame];
    [self.voiceInputBtn setTitle:(_isChinese?@"按下 说话":@"Bấm vào nói chuyện") forState:UIControlStateNormal];
    [self.voiceInputBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    self.voiceInputBtn.layer.cornerRadius = 4;
    self.voiceInputBtn.layer.masksToBounds = YES;
    self.voiceInputBtn.layer.borderWidth = 0.5f;
    self.voiceInputBtn.layer.borderColor = HEXCOLOR(0xdbdbdd).CGColor;
    [self.inputContainer addSubview:self.voiceInputBtn];
    
    self.layer.borderWidth = 0.5f;
    self.layer.borderColor = HEXCOLOR(0xdbdbdd).CGColor;
    
    self.inputBarStatus = ChatInputBarDefaultStatus;
    
    
    [self.voiceInputBtn addTarget:self action:@selector(onTouchDown:) forControlEvents:UIControlEventTouchDown];
    [self.voiceInputBtn addTarget:self action:@selector(onTouchDragExit:) forControlEvents:UIControlEventTouchDragExit];
    [self.voiceInputBtn addTarget:self action:@selector(onTouchDragEnter:) forControlEvents:UIControlEventTouchDragEnter];
    [self.voiceInputBtn addTarget:self action:@selector(onTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    [self.voiceInputBtn addTarget:self action:@selector(onTouchUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
    [self.voiceInputBtn addTarget:self action:@selector(onTouchUpOutside:) forControlEvents:UIControlEventTouchCancel];

    self.voiceInputBtn.hidden = YES;
    self.textInputView.returnKeyType = UIReturnKeySend;
    self.textInputView.delegate = self;
}
- (void)onTapInputView:(id)sender {
    NSLog(@"on tap input view");
    self.inputBarStatus = ChatInputBarKeyboardStatus;
}

- (void)onTouchDown:(id)sender {
    if ([self canRecord]) {
        _recordView = [[WDCARVoiceRecordView alloc] initWithFrame:CGRectMake(self.parentView.bounds.size.width/2 - 70, self.parentView.bounds.size.height/2 - 70, 140, 140)];
        _recordView.center = self.parentView.center;
        [self.parentView addSubview:_recordView];
        [self.parentView bringSubviewToFront:_recordView];
        [self recordStart];
    }
}

- (void)willAppear {
    if (self.backupFrame.size.height) {
        [self.delegate willChangeFrame:self.backupFrame withDuration:0.5 keyboardShowing:NO];
    }
}

- (void)recordStart {
    if (self.recorder.recording) {
        return;
    }
    
    __weak typeof(self)ws = self;
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            __block BOOL isViewExist = YES;
            if([NSThread isMainThread]) {
                if (!ws.recordView.superview) {
                    isViewExist = NO;
                }
            } else {
                dispatch_sync(dispatch_get_main_queue(), ^{
                    if (!ws.recordView.superview) {
                        isViewExist = NO;
                    }
                });
            }
            if(!isViewExist) {
                return;
            }
            {
                AVAudioSession *session = [AVAudioSession sharedInstance];
                [session setCategory:AVAudioSessionCategoryRecord error:nil];
                BOOL r = [session setActive:YES error:nil];
                if (!r) {
                    NSLog(@"activate audio session fail");
                    return;
                }
                NSLog(@"start record...");
                
                NSArray *pathComponents = [NSArray arrayWithObjects:
                                           [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject],
                                           @"voice.wav",
                                           nil];
                NSURL *outputFileURL = [NSURL fileURLWithPathComponents:pathComponents];
                
                // Define the recorder setting
                NSMutableDictionary *recordSetting = [[NSMutableDictionary alloc] init];
                
                [recordSetting setValue:[NSNumber numberWithInt:kAudioFormatLinearPCM] forKey:AVFormatIDKey];
                [recordSetting setValue:[NSNumber numberWithFloat:8000] forKey:AVSampleRateKey];
                [recordSetting setValue:[NSNumber numberWithInt:2] forKey:AVNumberOfChannelsKey];
                
                self.recorder = [[AVAudioRecorder alloc] initWithURL:outputFileURL settings:recordSetting error:NULL];
                self.recorder.delegate = self;
                self.recorder.meteringEnabled = YES;
                if (![self.recorder prepareToRecord]) {
                    NSLog(@"prepare record fail");
                    return;
                }
                if (![self.recorder record]) {
                    NSLog(@"start record fail");
                    return;
                }
                
                
                self.recordCanceled = NO;
                self.seconds = 0;
                self.recordingTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerFired:) userInfo:nil repeats:YES];
                
                self.updateMeterTimer = [NSTimer scheduledTimerWithTimeInterval:0.05
                                                                         target:self
                                                                       selector:@selector(updateMeter:)
                                                                       userInfo:nil
                                                                        repeats:YES];
                }
        } else {
            dispatch_async(dispatch_get_main_queue(), ^{
                [[[UIAlertView alloc] initWithTitle:@"警告" message:@"无法录音,请到设置-隐私-麦克风,允许程序访问" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] show];
            });
        }
    }];
}

- (void)recordCancel {
    NSLog(@"touch cancel");
    if (self.recorder.recording) {
        NSLog(@"cancel record...");
        self.recordCanceled = YES;
        [self stopRecord];
    }
}

- (void)onTouchDragExit:(id)sender {
    [self.recordView recordButtonDragOutside];
}

- (void)onTouchDragEnter:(id)sender {
    [self.recordView recordButtonDragInside];
}

- (void)onTouchUpInside:(id)sender {
    [self.recordView removeFromSuperview];
    [self recordEnd];
}

- (void)onTouchUpOutside:(id)sender {
    [self.recordView removeFromSuperview];
    [self recordCancel];
}

- (BOOL)canRecord {
    __block BOOL bCanRecord = YES;
    
    if ([[AVAudioSession sharedInstance]
         respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            bCanRecord = granted;
            dispatch_async(dispatch_get_main_queue(), ^{
                bCanRecord = granted;
                if (granted) {
                    bCanRecord = YES;
                } else {
                    
                }
            });
        }];
    }
    
    return bCanRecord;
}

- (void)timerFired:(NSTimer*)timer {
    self.seconds = self.seconds + 1;
    int minute = self.seconds/60;
    int s = self.seconds%60;
    NSString *str = [NSString stringWithFormat:@"%02d:%02d", minute, s];
    NSLog(@"timer:%@", str);
    int countdown = 60 - self.seconds;
    if (countdown <= 10) {
        [self.recordView setCountdown:countdown];
    }
    if (countdown <= 0) {
        [self.recordView removeFromSuperview];
        [self recordEnd];
    } else {
        [self notifyTyping:1];
    }
}

- (void)updateMeter:(NSTimer*)timer {
    double voiceMeter = 0;
    if ([self.recorder isRecording]) {
        [self.recorder updateMeters];
        //获取音量的平均值  [recorder averagePowerForChannel:0];
        //音量的最大值  [recorder peakPowerForChannel:0];
        double lowPassResults = pow(10, (0.05 * [self.recorder peakPowerForChannel:0]));
        voiceMeter = lowPassResults;
    }
    [self.recordView setVoiceImage:voiceMeter];
}

-(void)recordEnd {
    if (self.recorder.recording) {
        NSLog(@"stop record...");
        self.recordCanceled = NO;
        [self stopRecord];
    }
}

-(void)stopRecord {
    [self.recorder stop];
    [self.recordingTimer invalidate];
    self.recordingTimer = nil;
    [self.updateMeterTimer invalidate];
    self.updateMeterTimer = nil;
    
    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    BOOL r = [audioSession setActive:NO error:nil];
    if (!r) {
        NSLog(@"deactivate audio session fail");
    }
}

- (void)resetInputBarStatue {
    if (self.inputBarStatus != ChatInputBarRecordStatus && self.inputBarStatus != ChatInputBarMuteStatus
        && self.inputBarStatus != ChatInputBarPublicStatus
        ) {
        self.inputBarStatus = ChatInputBarDefaultStatus;
    }
    for (WDCARPublicMenuButton *menuButton in self.menuButtons) {
        menuButton.expended = NO;
    }
}

- (void)onSwitchBtn:(id)sender {
    if (sender == self.voiceSwitchBtn) {
        if (self.inputBarStatus == ChatInputBarRecordStatus) {
            self.inputBarStatus = ChatInputBarKeyboardStatus;
        } else {
            self.inputBarStatus = ChatInputBarRecordStatus;
        }
    } else if(sender == self.emojSwitchBtn) {
        if (self.emojInput && self.inputBarStatus != ChatInputBarDefaultStatus) {
            self.inputBarStatus = ChatInputBarKeyboardStatus;
        } else {
            self.inputBarStatus = ChatInputBarEmojiStatus;
        }
    } else if (sender == self.pluginSwitchBtn) {
        if (self.pluginInput && self.inputBarStatus != ChatInputBarDefaultStatus) {
            self.inputBarStatus = ChatInputBarKeyboardStatus;
        } else {
            self.inputBarStatus = ChatInputBarPluginStatus;
        }
    } else if (sender == self.publicSwitchBtn) {
        if (self.inputBarStatus == ChatInputBarPublicStatus) {
            self.inputBarStatus = ChatInputBarDefaultStatus;
        } else {
            self.inputBarStatus = ChatInputBarPublicStatus;
        }
    }
}

- (void)setInputBarStatus:(ChatInputBarStatus)inputBarStatus {
    if (inputBarStatus == _inputBarStatus) {
        return;
    }
    if (_inputBarStatus == ChatInputBarMuteStatus) {
        [self.textInputView setUserInteractionEnabled:YES];
        self.textInputView.text = @"";
        [self.voiceInputBtn setEnabled:YES];
        [self.voiceSwitchBtn setEnabled:YES];
        [self.emojSwitchBtn setEnabled:YES];
        [self.pluginSwitchBtn setEnabled:YES];
    }
    
    _inputBarStatus = inputBarStatus;
    if (inputBarStatus != ChatInputBarPublicStatus && self.publicContainer) {
        self.inputContainer.hidden = NO;
        self.publicContainer.hidden = YES;
        [self.publicSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_menu"] forState:UIControlStateNormal];
    }
    self.textInputView.textColor = UIColor.blackColor;
    switch (inputBarStatus) {
        case ChatInputBarKeyboardStatus:
            self.voiceInput = NO;
            self.emojInput = NO;
            self.pluginInput = NO;
            self.textInput = YES;
            break;
        case ChatInputBarPluginStatus:
            self.voiceInput = NO;
            self.emojInput = NO;
            self.pluginInput = YES;
            self.textInput = NO;
            break;
        case ChatInputBarEmojiStatus:
            self.voiceInput = NO;
            self.emojInput = YES;
            self.pluginInput = NO;
            self.textInput = NO;
            break;
        case ChatInputBarRecordStatus:
            self.voiceInput = YES;
            self.emojInput = NO;
            self.pluginInput = NO;
            self.textInput = NO;
            break;
        case ChatInputBarPublicStatus:
            self.inputContainer.hidden = YES;
            self.publicContainer.hidden = NO;
            [self.publicSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_keyboard"] forState:UIControlStateNormal];
            [self.textInputView resignFirstResponder];
            break;
        case ChatInputBarDefaultStatus:
            self.voiceInput = NO;
            self.emojInput = NO;
            self.pluginInput = NO;
            self.textInput = YES;
            [self.textInputView resignFirstResponder];
            break;
        case ChatInputBarMuteStatus:
            self.voiceInput = NO;
            self.emojInput = NO;
            self.pluginInput = NO;
            self.textInput = YES;
            [self.textInputView setUserInteractionEnabled:NO];
            self.textInputView.text = @"Không thể trò chuyện";
            self.textInputView.textColor = RGBCOLOR(200.0, 200.0, 200.0);
            [self.voiceInputBtn setEnabled:NO];
            [self.voiceSwitchBtn setEnabled:NO];
            [self.emojSwitchBtn setEnabled:NO];
            [self.pluginSwitchBtn setEnabled:NO];
            break;
        default:
            break;
    }
    if (inputBarStatus != ChatInputBarKeyboardStatus) {
        if (self.textInputView.tintColor != [UIColor clearColor]) {
            self.textInputViewTintColor = self.textInputView.tintColor;
        }
        self.textInputView.tintColor = [UIColor clearColor];
        self.inputCoverView.hidden = NO;
    } else {
        self.textInputView.tintColor = self.textInputViewTintColor;
        self.inputCoverView.hidden = YES;
    }
}

- (void)setVoiceInput:(BOOL)voiceInput {
    _voiceInput = voiceInput;
    if (voiceInput) {
        [self.textInputView setHidden:YES];
        [self.voiceInputBtn setHidden:NO];
        if (self.textInputView.isFirstResponder) {
            [self.textInputView resignFirstResponder];
        }

            [self.voiceSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_keyboard"] forState:UIControlStateNormal];
            
        CGFloat diff = 0;
        if (self.textInputView.frame.size.height != CHAT_INPUT_BAR_ICON_SIZE) {
            diff = self.textInputView.frame.size.height - CHAT_INPUT_BAR_ICON_SIZE;
        }
        if (self.asoucQuoteContainerView && !self.asoucQuoteContainerView.hidden) {
            self.asoucQuoteContainerView.hidden = YES;
            diff += self.asoucQuoteContainerView.frame.size.height + CHAT_INPUT_QUOTE_PADDING;
        }
        [self extendUp:-diff];
    } else {
        [self.textInputView setHidden:NO];
        self.asoucQuoteContainerView.hidden = NO;
        [self.voiceInputBtn setHidden:YES];
        [self.voiceSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_voice"] forState:UIControlStateNormal];
    }
}
- (void)setEmojInput:(BOOL)emojInput {
    _emojInput = emojInput;
    if (emojInput) {
        [self.textInputView setHidden:NO];
        self.asoucQuoteContainerView.hidden = NO;
        [self.voiceInputBtn setHidden:YES];
        self.textInputView.inputView = self.emojInputView;
        if (!self.textInputView.isFirstResponder) {
            [self.textInputView becomeFirstResponder];
        }
        [self.textInputView reloadInputViews];
        [self.emojSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_keyboard"] forState:UIControlStateNormal];
        if (self.textInputView.frame.size.height+self.asoucQuoteContainerView.frame.size.height > self.frame.size.height) {
            [self textView:self.textInputView shouldChangeTextInRange:NSMakeRange(self.textInputView.text.length, 0) replacementText:@""];
        }
    } else {
        [self.emojSwitchBtn setImage:[QWERImage imageNamed:@"chat_input_bar_emoj"] forState:UIControlStateNormal];
    }
}

- (void)setPluginInput:(BOOL)pluginInput {
    _pluginInput = pluginInput;
    if (pluginInput) {
        [self.textInputView setHidden:NO];
        self.asoucQuoteContainerView.hidden = NO;
        [self.voiceInputBtn setHidden:YES];
        self.textInputView.inputView = self.pluginInputView;
        if (!self.textInputView.isFirstResponder) {
            [self.textInputView becomeFirstResponder];
        }
        [self.textInputView reloadInputViews];
        self.asoucQuoteContainerView.hidden = NO;
        if (self.textInputView.frame.size.height+self.asoucQuoteContainerView.frame.size.height > self.frame.size.height) {
            [self textView:self.textInputView shouldChangeTextInRange:NSMakeRange(self.textInputView.text.length, 0) replacementText:@""];
        }
    }
}

- (void)setTextInput:(BOOL)textInput {
    _textInput = textInput;
    if (textInput) {
        [self.textInputView setHidden:NO];
        self.asoucQuoteContainerView.hidden = NO;
        [self.voiceInputBtn setHidden:YES];
        self.textInputView.inputView = nil;
        
        // 避免不必要的 reloadInputViews 调用
        if (self.textInputView.inputView == nil && _inputBarStatus == ChatInputBarKeyboardStatus) {
            [self.textInputView reloadInputViews];
        }
        
        // 避免 becomeFirstResponder 多次调用导致 UI 卡顿
        if (!self.textInputView.isFirstResponder) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.textInputView becomeFirstResponder];
            });
        }
        
        // 避免不必要的 textView:shouldChangeTextInRange: 调用
        CGFloat totalHeight = self.textInputView.frame.size.height + self.asoucQuoteContainerView.frame.size.height;
        if (totalHeight > self.frame.size.height && self.textInputView.text.length > 0) {
            [self textView:self.textInputView shouldChangeTextInRange:NSMakeRange(self.textInputView.text.length, 0) replacementText:@""];
        }

        
//        if (!self.textInputView.isFirstResponder && _inputBarStatus == ChatInputBarKeyboardStatus) {
//            [self.textInputView becomeFirstResponder];
//        }
//        if (_inputBarStatus == ChatInputBarKeyboardStatus) {
//            [self.textInputView reloadInputViews];
//        }
//        if (self.textInputView.frame.size.height+self.asoucQuoteContainerView.frame.size.height > self.frame.size.height) {
//            [self textView:self.textInputView shouldChangeTextInRange:NSMakeRange(self.textInputView.text.length, 0) replacementText:@""];
//        }
    }
    
}

- (void)resetTyping {
    self.lastTypingTime = 0;
}

- (void)notifyTyping:(WFCCTypingType)type {
    double now = [[NSDate date] timeIntervalSince1970];
    if (self.lastTypingTime + TYPING_INTERVAL < now) {
        if ([self.delegate respondsToSelector:@selector(onTyping:)]) {
            [self.delegate onTyping:type];
        }
        self.lastTypingTime = now;
    }
}
- (void)setDraft:(NSString *)draft {
    if (![WFCCIMService.sharedWFCIMService isEnableSyncDraft]) {
//        self.textInputView.text = @"";
        if (_inputBarStatus == ChatInputBarMuteStatus) { // 1008新增
            self.textInputView.text = @"Không thể trò chuyện";
            self.textInputView.textColor = RGBCOLOR(200.0, 200.0, 200.0);
        }else {
            self.textInputView.text = @"";
            self.textInputView.textColor = UIColor.blackColor;
        }
        return;
    }
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[draft dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:kNilOptions
                                                                 error:&__error];

    BOOL textDraft = YES;
    NSString *text = draft;
    NSMutableArray<WFCUMetionInfo *> *mentionInfos = [[NSMutableArray alloc] init];
    WFCCQuoteInfo *quoteInfo = nil;

    if (!__error) {
        if ([dictionary[@"mentions"] isKindOfClass:[NSArray class]]) {
            textDraft = NO;
            NSArray *mentions = dictionary[@"mentions"];
            [mentions enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSDictionary *dic = (NSDictionary *)obj;
                WFCUMetionInfo *mentionInfo = [[WFCUMetionInfo alloc] init];
                if(dic[@"uid"] || dic[@"isMentionAll"]) {
                    mentionInfo.target = dic[@"uid"];
                    mentionInfo.mentionType = [dic[@"isMentionAll"] boolValue] ? 2 : 1;
                    mentionInfo.range = NSMakeRange([dic[@"start"] integerValue], [dic[@"end"] integerValue]-[dic[@"start"] integerValue]);
                } else {
                    mentionInfo.target = dic[@"target"];
                    mentionInfo.mentionType = [dic[@"type"] intValue];
                    mentionInfo.range = NSMakeRange([dic[@"loc"] integerValue], [dic[@"len"] integerValue]);
                }
                [mentionInfos addObject:mentionInfo];
            }];
        }

        if ([dictionary[@"quote"] isKindOfClass:[NSDictionary class]] || [dictionary[@"quoteInfo"] isKindOfClass:[NSDictionary class]]) {
            textDraft = NO;
            quoteInfo = [[WFCCQuoteInfo alloc] init];
            if([dictionary[@"quoteInfo"] isKindOfClass:[NSDictionary class]])
                [quoteInfo decode:dictionary[@"quoteInfo"]];
            else if([dictionary[@"quote"] isKindOfClass:[NSDictionary class]])
                [quoteInfo decode:dictionary[@"quote"]];
        }

        if([dictionary[@"content"] isKindOfClass:[NSString class]]) {
            //兼容android与web端
            text = dictionary[@"content"];
        } else if([dictionary[@"text"] isKindOfClass:[NSString class]]) {
            text = dictionary[@"text"];
        }
    }

    //防止弹出@选项
    if ([text isEqualToString:@"@"]) {
        text = @"@ ";
    }

    self.mentionInfos = mentionInfos;
    if (quoteInfo) {
        self.quoteInfo = quoteInfo;
        [self updateQuoteView:NO showKeyboard:NO];
    }

    [self textView:self.textInputView shouldChangeTextInRange:NSMakeRange(0, 0) replacementText:text];
//    self.textInputView.text = text;
    
    if (_inputBarStatus == ChatInputBarMuteStatus) { // 1008新增
        self.textInputView.text = @"Không thể trò chuyện";
        self.textInputView.textColor = RGBCOLOR(200.0, 200.0, 200.0);
    }else {
        self.textInputView.text = text;
        self.textInputView.textColor = UIColor.blackColor;
    }
}

- (NSString *)draft {
    if (self.mentionInfos.count || self.quoteInfo) {
        NSMutableDictionary *dataDict = [NSMutableDictionary dictionary];
        [dataDict setObject:self.textInputView.text forKey:@"content"];
        if (self.mentionInfos.count) {
            NSMutableArray *mentions = [[NSMutableArray alloc] init];
            [self.mentionInfos enumerateObjectsUsingBlock:^(WFCUMetionInfo * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
                [dic setObject:obj.target forKey:@"uid"];
                [dic setObject:obj.mentionType==2?@(YES):@(NO) forKey:@"isMentionAll"];
                [dic setObject:@(obj.range.location) forKey:@"start"];
                [dic setObject:@(obj.range.location+obj.range.length) forKey:@"end"];
                [mentions addObject:dic];
            }];
            [dataDict setObject:mentions forKey:@"mentions"];
        }
        if (self.quoteInfo) {
            NSDictionary *quoteDict = [self.quoteInfo encode];
            [dataDict setObject:quoteDict forKey:@"quoteInfo"];
        }
        
        NSData *data = [NSJSONSerialization dataWithJSONObject:dataDict
                                                                options:kNilOptions
                                                                  error:nil];
        return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    } else {
        return self.textInputView.text;
    }
}

- (void)appendText:(NSString *)text {
    [self textView:self.textInputView shouldChangeTextInRange:NSMakeRange(self.textInputView.text.length, 0) replacementText:text];
    self.textInputView.text = [self.textInputView.text stringByAppendingString:text];
}

- (NSString *)getDraftText:(NSString *)draft {
    if(!draft) {
        return nil;
    }
    NSError *__error = nil;
    NSDictionary *dictionary = [NSJSONSerialization JSONObjectWithData:[draft dataUsingEncoding:NSUTF8StringEncoding]
                                                               options:kNilOptions
                                                                 error:&__error];
    
    NSString *text = draft;
    if (!__error) {
        if([dictionary[@"content"] isKindOfClass:[NSString class]]) {
            //兼容android与web端
            text = dictionary[@"content"];
        } else if ([dictionary[@"text"] isKindOfClass:[NSString class]]) {
            text = dictionary[@"text"];
        }
    }
    return text;
}

- (UIView *)emojInputView {
    if (!_emojInputView) {
        _emojInputView = [[WDCARFaceBoard alloc] init];
        ((WDCARFaceBoard*)_emojInputView).delegate = self;
    }
    return _emojInputView;
}

- (UIView *)pluginInputView {
    if (!_pluginInputView) {
#if WFCU_SUPPORT_VOIP
        BOOL hasVoip = self.conversation.type == Single_Type || self.conversation.type == SecretChat_Type || (self.conversation.type == Group_Type && [Chat86AVEngineKit sharedEngineKit].supportMultiCall);
#else
        BOOL hasVoip = NO;
#endif
        BOOL hasPtt = NO;
        _pluginInputView = [[WDCARPluginBoardView alloc] initWithDelegate:self withVoip:hasVoip withPtt:hasPtt];
    }
    return _pluginInputView;
}

- (void)keyboardWillShow:(NSNotification *)notification {
    if (![self.textInputView isFirstResponder]) {
        return;
    }
    NSDictionary *userInfo = [notification userInfo];
    NSValue *value = [userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
    CGRect keyboardRect = [value CGRectValue];
    int height = keyboardRect.size.height - [QWERUtilities wf_safeDistanceBottom];
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect frame = CGRectMake(0, self.superview.bounds.size.height - self.bounds.size.height - height, self.superview.bounds.size.width, self.bounds.size.height);
    [self.delegate willChangeFrame:frame withDuration:duration keyboardShowing:YES];
    self.backupFrame = frame;
    [UIView animateWithDuration:duration animations:^{
        self.frame = frame;
        self.inputContainer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification {
    NSDictionary *userInfo = [notification userInfo];
    
    CGFloat duration = [[userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey] floatValue];
    CGRect frame = CGRectMake(0, self.superview.bounds.size.height - self.bounds.size.height, self.superview.bounds.size.width, self.bounds.size.height);
    [self.delegate willChangeFrame:frame withDuration:duration keyboardShowing:NO];
    self.backupFrame = frame;
    [UIView animateWithDuration:duration animations:^{
        self.frame = frame;
        self.inputContainer.frame = CGRectMake(0, 0, frame.size.width, frame.size.height);
    }];
    
    if(self.inputBarStatus == ChatInputBarKeyboardStatus || self.inputBarStatus == ChatInputBarPluginStatus || self.inputBarStatus == ChatInputBarEmojiStatus) {
        _inputBarStatus = ChatInputBarDefaultStatus;
    }
}

-(void)keyboardDidHide:(NSNotification *)notification{
    if ((self.emojInput || self.pluginInput || self.textInput) && self.inputBarStatus != ChatInputBarDefaultStatus && self.inputBarStatus != ChatInputBarPublicStatus) {
        [self.textInputView becomeFirstResponder];
    }
}

- (BOOL)appendMention:(NSString *)userId name:(NSString *)userName {
    if (self.conversation.type == Group_Type) {
        NSString *mentionText = [NSString stringWithFormat:@"@%@ ", userName];
        BOOL needDelay = NO;
        if(self.inputBarStatus == ChatInputBarDefaultStatus || self.inputBarStatus == ChatInputBarPluginStatus ||
           self.inputBarStatus == ChatInputBarRecordStatus) {
            self.inputBarStatus = ChatInputBarKeyboardStatus;
            needDelay = YES;
        }
        if (needDelay) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self didMentionType:1 user:userId range:NSMakeRange(self.textInputView.selectedRange.location, mentionText.length) text:mentionText];
            });
        } else {
            [self didMentionType:1 user:userId range:NSMakeRange(self.textInputView.selectedRange.location, mentionText.length) text:mentionText];
        }
        
        return YES;
    } else {
        return NO;
    }
}
- (void)clearQuoteInfo {
    self.quoteInfo = nil;
}
- (void)onQuoteDelBtn:(id)sender {
    if (self.quoteInfo.messageUid) {
        [self clearQuoteInfo];
        [self updateQuoteView:YES showKeyboard:YES];
    }
}

- (void)updateQuoteView:(BOOL)updateFrame showKeyboard:(BOOL)showKeyboard {
    if (self.inputBarStatus == ChatInputBarMuteStatus) {
        return;
    }
    
    if (showKeyboard && (self.inputBarStatus == ChatInputBarDefaultStatus || self.inputBarStatus == ChatInputBarRecordStatus
                         )) {
        self.inputBarStatus = ChatInputBarKeyboardStatus;
    }
    
    if (self.quoteInfo.messageUid) {
        NSString *textContent = [NSString stringWithFormat:@"%@:%@", self.quoteInfo.userDisplayName, self.quoteInfo.messageDigest];
        
        CGFloat deleteBtnWidth = 10;
        CGRect textViewFrame = self.textInputView.frame;
        CGSize size = [QWERUtilities getTextDrawingSize:textContent font:[UIFont systemFontOfSize:12] constrainedSize:CGSizeMake(textViewFrame.size.width-CHAT_INPUT_QUOTE_PADDING-CHAT_INPUT_QUOTE_PADDING-deleteBtnWidth-CHAT_INPUT_QUOTE_PADDING, 30)];
        size.height += 4;
        
        self.asoucQuoteLabel = [[UILabel alloc] initWithFrame:CGRectMake(CHAT_INPUT_QUOTE_PADDING, 0, textViewFrame.size.width-CHAT_INPUT_QUOTE_PADDING-CHAT_INPUT_QUOTE_PADDING-deleteBtnWidth, size.height)];
        self.asoucQuoteLabel.font = [UIFont systemFontOfSize:12];
        self.asoucQuoteLabel.textColor = [UIColor grayColor];
        self.asoucQuoteLabel.text = textContent;
        self.asoucQuoteLabel.numberOfLines = 0;
        self.quoteDeleteBtn = [[UIButton alloc] initWithFrame:CGRectMake(textViewFrame.size.width-deleteBtnWidth-CHAT_INPUT_QUOTE_PADDING, (size.height-deleteBtnWidth)/2, deleteBtnWidth, deleteBtnWidth)];
        [self.quoteDeleteBtn setTitle:@"x" forState:UIControlStateNormal];
        [self.quoteDeleteBtn addTarget:self action:@selector(onQuoteDelBtn:) forControlEvents:UIControlEventTouchUpInside];
        
        self.asoucQuoteContainerView = [[UIView alloc] initWithFrame:CGRectMake(textViewFrame.origin.x, textViewFrame.origin.y+textViewFrame.size.height+CHAT_INPUT_QUOTE_PADDING, textViewFrame.size.width, size.height)];
        self.asoucQuoteContainerView.backgroundColor = [UIColor colorWithRed:0.85 green:0.85 blue:0.85 alpha:1.f];
        
        [self.asoucQuoteContainerView addSubview:self.asoucQuoteLabel];
        [self.asoucQuoteContainerView addSubview:self.quoteDeleteBtn];
        [self addSubview:self.asoucQuoteContainerView];
        if (updateFrame) {
            [self extendUp:(size.height + CHAT_INPUT_QUOTE_PADDING)];
        }
    } else {
        CGFloat quoteHeight = self.asoucQuoteContainerView.frame.size.height;
        [self.asoucQuoteLabel removeFromSuperview];
        self.asoucQuoteLabel = nil;
        [self.quoteDeleteBtn removeFromSuperview];
        self.quoteDeleteBtn = nil;
        [self.asoucQuoteContainerView removeFromSuperview];
        self.asoucQuoteContainerView = nil;
        if (updateFrame) {
            [self extendUp: -quoteHeight - CHAT_INPUT_QUOTE_PADDING];
        }
    }
}

- (BOOL)appendQuote:(WFCCMessage *)message {
    if (self.quoteInfo) {
        [self clearQuoteInfo];
        [self updateQuoteView:YES showKeyboard:YES];
    }
    self.quoteInfo = [[WFCCQuoteInfo alloc] initWithMessage:message];
    [self updateQuoteView:YES showKeyboard:YES];
    return self.quoteInfo != nil;
}

- (void)extendUp:(CGFloat)diff {
    CGRect baseFrame = self.frame;
    CGRect voiceFrame = self.voiceSwitchBtn.frame;
    CGRect emojFrame = self.emojSwitchBtn.frame;
    CGRect extendFrame = self.pluginSwitchBtn.frame;
    
    baseFrame.size.height += diff;
    baseFrame.origin.y -= diff;
    
    voiceFrame.origin.y += diff;
    emojFrame.origin.y += diff;
    extendFrame.origin.y += diff;
    
    [UIView animateWithDuration:0.5 animations:^{
        self.frame = baseFrame;
        self.inputContainer.frame = CGRectMake(0, 0, baseFrame.size.width, baseFrame.size.height);
        self.voiceSwitchBtn.frame = voiceFrame;
        self.emojSwitchBtn.frame = emojFrame;
        self.pluginSwitchBtn.frame = extendFrame;
    }];
    [self.delegate willChangeFrame:baseFrame withDuration:0.5 keyboardShowing:YES];
}

- (void)paste:(id)sender {
    [self.textInputView paste:sender];
}

#pragma mark - AVAudioRecorderDelegate
- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"record finish:%d", flag);
    if (!flag) {
        return;
    }
    if (self.recordCanceled) {
        return;
    }
    if (self.seconds < 1) {
        NSLog(@"record time too short");
        [[[UIAlertView alloc] initWithTitle:(_isChinese?@"警告":@"Cảnh báo") message:(_isChinese?@"录音时间太短了":@"Thời gian ghi âm quá ngắn") delegate:nil cancelButtonTitle:(_isChinese?@"确定":@"Chắc chắn") otherButtonTitles:nil, nil] show];
        
        return;
    }
    [self.delegate recordDidEnd:[recorder.url path] duration:self.seconds error:nil];
    [[NSFileManager defaultManager] removeItemAtURL:recorder.url error:nil];
}

#pragma mark - FaceBoardDelegate
- (void)didTouchEmoj:(NSString *)emojString {
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc]initWithString:emojString];
    UIFont *font = [UIFont fontWithName:@"Heiti SC-Bold" size:16];
    [attStr addAttribute:(__bridge NSString*)kCTFontAttributeName value:(id)CFBridgingRelease(CTFontCreateWithName((CFStringRef)font.fontName,
                                                                                                                   16,
                                                                                                                   NULL)) range:NSMakeRange(0, emojString.length)];
    
    NSUInteger cursorPosition = self.textInputView.textStorage.length;
    [self.textInputView.textStorage insertAttributedString:attStr  atIndex:cursorPosition];
    
    self.textInputView.selectedRange = NSMakeRange(cursorPosition + emojString.length, 0);
}

- (void)didTouchBackEmoj {
    [self.textInputView deleteBackward];
}

- (void)didTouchSendEmoj {
    [self sendAndCleanTextView];
}

- (void)sendAndCleanTextView {
    if(self.saveDraftTimer) {
        [self.saveDraftTimer invalidate];
        self.saveDraftTimer = nil;
    }
    
    [self.delegate didTouchSend:self.textInputView.text withMentionInfos:self.mentionInfos withQuoteInfo:self.quoteInfo];
    self.textInputView.text = nil;
    [self clearQuoteInfo];
    [self updateQuoteView:NO showKeyboard:YES];
    [self.mentionInfos removeAllObjects];
    [self changeTextViewHeight:32 needUpdateText:NO updateRange:NSMakeRange(0, 0)];
}


- (void)didSelectedSticker:(NSString *)stickerPath {
    if ([self.delegate respondsToSelector:@selector(didSelectSticker:)]) {
        [self.delegate didSelectSticker:stickerPath];
    }
}

#pragma mark - UITextViewDelegate
- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if (_isLineFeed) { // 这个因果条件 0510 新增   用于筛选主动换行的问题
        
    }else {
        if ([text isEqualToString:@"\n"]) { //判断输入的字是否是回车，即按下return
            [self sendAndCleanTextView];
            return NO;
        }
    }
    _isLineFeed = NO;
    
    BOOL needUpdateText = NO;
    if(self.conversation.type == Group_Type) {
        if ([text isEqualToString:@"@"]) {
            // @ 选择@的联系人
            FRSDAContactListVC *pvc = [[FRSDAContactListVC alloc] init];
            pvc.selectContact = YES;
            pvc.multiSelect = NO;
            NSMutableArray *disabledUser = [[NSMutableArray alloc] init];
            [disabledUser addObject:[WFCCNetworkService sharedInstance].userId];
            pvc.disableUsers = disabledUser;
            NSMutableArray *candidateUser = [[NSMutableArray alloc] init];
            NSArray<WFCCGroupMember *> *members = [[WFCCIMService sharedWFCIMService] getGroupMembers:self.conversation.target forceUpdate:NO];
            for (WFCCGroupMember *member in members) {
                if ([member.memberId isEqualToString:[WFCCNetworkService sharedInstance].userId]) {
                    continue;
                }
                [candidateUser addObject:member.memberId];
            }
            pvc.candidateUsers = candidateUser;
            pvc.withoutCheckBox = YES;
            pvc.groupId = self.conversation.target;
            
            
            __weak typeof(self)ws = self;
            WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:self.conversation.target refresh:NO];
            WFCCGroupMember *member = [[WFCCIMService sharedWFCIMService] getGroupMember:self.conversation.target memberId:[WFCCNetworkService sharedInstance].userId];
            if ([groupInfo.owner isEqualToString:[WFCCNetworkService sharedInstance].userId] || member.type == Member_Type_Manager) {
                pvc.showMentionAll = YES;
                pvc.mentionAll = ^{
                    NSString *text = (self->_isChinese?@"@所有人":@"@Mọi người ");
                    [ws didMentionType:2 user:@"" range:NSMakeRange(range.location, text.length) text:text];
                };
            }
            
            
            pvc.selectResult = ^(NSArray<NSString *> *contacts) {
                if (contacts.count == 1) {
                    WFCCUserInfo *userInfo = [[WFCCIMService sharedWFCIMService] getUserInfo:[contacts objectAtIndex:0] inGroup:self.conversation.target refresh:NO];
                    NSString *name = userInfo.displayName;
                    // 0522新增 用于@显示名称为备注名称  群备注昵称 > 备注昵称 > 本身昵称
//                    NSString *name = (userInfo.friendAlias.length > 0 ? userInfo.friendAlias : userInfo.displayName);
                    if (userInfo.groupAlias.length) {
                        name = userInfo.groupAlias;
                    }
                    
                    NSString *text = [NSString stringWithFormat:@"@%@ ", name];
                    [ws didMentionType:1 user:[contacts objectAtIndex:0] range:NSMakeRange(range.location, text.length) text:text];
                } else {
                    [ws didCancelMentionAtRange:range];
                }
            };
            
            pvc.cancelSelect = ^(void) {
                [ws didCancelMentionAtRange:range];
            };
            
            pvc.disableUsersSelected = YES;
            
            UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
            [[self.delegate requireNavi] presentViewController:navi animated:YES completion:nil];
            return NO;
        }
        
        if (text.length == 0) {
            WFCUMetionInfo *deletedMention;
            for (WFCUMetionInfo *mentionInfo in self.mentionInfos) {
                if ((mentionInfo.range.location >= range.location && mentionInfo.range.location < range.location + range.length) ||
                    (range.location >= mentionInfo.range.location && range.location < mentionInfo.range.location + mentionInfo.range.length)) {
                    deletedMention = mentionInfo;
                }
            }
            
            if (deletedMention) {
                range = deletedMention.range;
                [self.mentionInfos removeObject:deletedMention];
                needUpdateText = YES;
            }
        } else {
            if(self.textInputView.text.length) {
                for (WFCUMetionInfo *mentionInfo in self.mentionInfos) {
                    if (range.location <= mentionInfo.range.location) {
                        mentionInfo.range = NSMakeRange(mentionInfo.range.location - range.length + text.length, mentionInfo.range.length);
                    }
                }
            }
        }
        
    }
    
  NSString *oldStr = textView.text;
  NSString *newStr = [oldStr stringByReplacingCharactersInRange:range withString:text];
  CGFloat textAreaWidth = textView.frame.size.width - 2 * textView.textContainer.lineFragmentPadding;
  CGSize size = [QWERUtilities getTextDrawingSize:newStr font:[UIFont systemFontOfSize:16] constrainedSize:CGSizeMake(textAreaWidth, 1000)];
  
    [self changeTextViewHeight:size.height needUpdateText:needUpdateText updateRange:range];
  
    return YES;
}
- (void)changeTextViewHeight:(CGFloat)height needUpdateText:(BOOL)needUpdateText updateRange:(NSRange)range {
    CGRect tvFrame = self.textInputView.frame;
    CGRect baseFrame = self.frame;
    CGRect voiceFrame = self.voiceSwitchBtn.frame;
    CGRect emojFrame = self.emojSwitchBtn.frame;
    CGRect extendFrame = self.pluginSwitchBtn.frame;
    
    CGFloat diff = 0;
    CGFloat quoteHeight = 0;
    if (self.asoucQuoteContainerView) {
        quoteHeight = self.asoucQuoteContainerView.frame.size.height + CHAT_INPUT_QUOTE_PADDING;
    }
    if (height <= 32.f) {
        tvFrame.size.height = 32.f;
        diff = (48.f - baseFrame.size.height + quoteHeight);
        baseFrame.size.height = 48.f;
    } else if (height > 32.f && height < 50.f) {
        tvFrame.size.height = 50.f;
        diff = (66.f - baseFrame.size.height + quoteHeight);
        baseFrame.size.height = 66.f;
    } else {
        tvFrame.size.height = 65.f;
        diff = (81.f - baseFrame.size.height + quoteHeight);
        baseFrame.size.height = 81.f;
    }
    if (self.asoucQuoteContainerView) {
        baseFrame.size.height += quoteHeight;
        CGRect quoteFrame = self.asoucQuoteContainerView.frame;
        quoteFrame.origin.y = tvFrame.origin.y + tvFrame.size.height + CHAT_INPUT_QUOTE_PADDING;
        self.asoucQuoteContainerView.frame = quoteFrame;
    }
    
    baseFrame.origin.y -= diff;
    voiceFrame.origin.y += diff;
    emojFrame.origin.y += diff;
    extendFrame.origin.y += diff;
    
    float duration = 0.5f;
    [self.delegate willChangeFrame:baseFrame withDuration:duration keyboardShowing:YES];
    self.backupFrame = baseFrame;
    __weak typeof(self)ws = self;
    [UIView animateWithDuration:duration animations:^{
        ws.textInputView.frame = tvFrame;
        ws.inputCoverView.frame = ws.textInputView.bounds;
        self.frame = baseFrame;
        self.inputContainer.frame = CGRectMake(0, 0, baseFrame.size.width, baseFrame.size.height);
        self.voiceSwitchBtn.frame = voiceFrame;
        self.emojSwitchBtn.frame = emojFrame;
        self.pluginSwitchBtn.frame = extendFrame;
        if(needUpdateText) {
            [ws.textInputView.textStorage replaceCharactersInRange:range withString:@" "];
        }
    }];
}

- (void)textViewDidLineFeed:(WDCARTextView *)textView {
    if (self.textInputView == textView) {
        _isLineFeed = YES;
        NSInteger cursorPosition;
        if (self.textInputView.selectedTextRange) {
            cursorPosition = self.textInputView.selectedRange.location ;
        } else {
            cursorPosition = 0;
        }
        //获取光标位置
        if (cursorPosition > self.textInputView.textStorage.length) {
            cursorPosition = self.textInputView.textStorage.length;
        }
//        NSAttributedString *str = [[NSAttributedString alloc] initWithString:@"\n"];
//        [self.textInputView.textStorage insertAttributedString:str atIndex:cursorPosition];
        NSMutableString *str = [NSMutableString stringWithString:self.textInputView.text];
        [str insertString:@"\n" atIndex:cursorPosition];
        self.textInputView.text = str;
        
        NSRange range;
//        range.location = self.textInputView.selectedRange.location + str.length;
        range.location = cursorPosition + 1;
        range.length = 0;

        self.textInputView.selectedRange = range;
        
        [self textView:self.textInputView shouldChangeTextInRange:range replacementText:@"\n"];
//        [self changeTextViewHeight:_textInputView.frame.size.height + 6.0 needUpdateText:YES updateRange:range];
        return;
    }
}
- (void)textViewDidChangeSelection:(UITextView *)textView {
//    NSLog(@"Jian=====7=%ld===%ld",textView.selectedRange.length, textView.selectedRange.location);
    _cursorPosition = textView.selectedRange.location;
    if (self.textInputView == textView && self.conversation.type == Group_Type) {
        NSRange range = textView.selectedRange;
        for (WFCUMetionInfo *mention in self.mentionInfos) {
            if (range.location > mention.range.location && range.location < mention.range.location + mention.range.length) {
                if (range.length == 0) {
                    if(range.location == mention.range.location + mention.range.length - 1) {
                        range.location = mention.range.location;
                    } else {
                        range = NSMakeRange(mention.range.location + mention.range.length, 0);
                    }
                } else {
                    long length = range.length - (mention.range.location + mention.range.length) + range.location;
                    if (length < 0) {
                        length = 0;
                    }
                    range = NSMakeRange(mention.range.location + mention.range.length, length);
                }
                
                textView.selectedRange = range;
                break;
            }
        }
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    if (textView.text.length > 0) {
        [self notifyTyping:0];
    }
    
    if(self.saveDraftTimer) {
        [self.saveDraftTimer invalidate];
        self.saveDraftTimer = nil;
    }
    if ([WFCCIMService.sharedWFCIMService isEnableSyncDraft]) {
        if([self.delegate respondsToSelector:@selector(needSaveDraft)]) {
            __weak typeof(self)ws = self;
            if (@available(iOS 10.0, *)) {
                self.saveDraftTimer = [NSTimer scheduledTimerWithTimeInterval:3 repeats:NO block:^(NSTimer * _Nonnull timer) {
                    [ws.delegate needSaveDraft];
                }];
            } else {
                // Fallback on earlier versions
            }
        }
    }
}

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView {
    if (self.inputBarStatus == ChatInputBarDefaultStatus) {
        self.inputBarStatus = ChatInputBarKeyboardStatus;
    }
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView {
    return YES;
}

- (BOOL)isGroupManager {
    if (self.conversation.type != Group_Type) {
        return NO;
    }
    __block BOOL isManager = NO;
    NSArray<WFCCGroupMember *> *groupMembers = [[WFCCIMService sharedWFCIMService] getGroupMembers:_conversation.target forceUpdate:NO];
    [groupMembers enumerateObjectsUsingBlock:^(WFCCGroupMember * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([obj.memberId isEqualToString:WFCCNetworkService.sharedInstance.userId]) {
            if (obj.type == Member_Type_Owner || obj.type == Member_Type_Manager) {
                isManager = YES;
            }
            *stop = YES;
        }
    }];
    return isManager;
}
#pragma mark - PluginBoardViewDelegate
- (void)onItemClicked:(NSUInteger)itemTag {
    if (itemTag == 4) { // 视频
        if (_conversation.type == Group_Type) { // 群聊的视频只允许群主和管理员发起
            if (![self isGroupManager]) {
                [self.parentView makeToast:(_isChinese ? @"你无权限发起通话" : @"Bạn không được phép bắt đầu cuộc gọi") duration:1.0 position:CSToastPositionCenter];
                return;
            }
        }
    }
    UINavigationController *navi = [self.delegate requireNavi];
  
    __weak typeof(self)weakself = self;
    self.inputBarStatus = ChatInputBarDefaultStatus;
    if (itemTag == 1) {
        [ZLPhotoConfiguration default].allowSelectImage = YES;
        [ZLPhotoConfiguration default].allowSelectVideo = YES;
        [ZLPhotoConfiguration default].maxSelectCount = 9;
        [ZLPhotoConfiguration default].maxVideoSelectCount = 9;
        [ZLPhotoConfiguration default].allowMixSelect = YES;
        [ZLPhotoConfiguration default].allowTakePhotoInLibrary = YES;
//        [ZLPhotoConfiguration default].alwaysRequestOriginal = YES;
//        [ZLPhotoConfiguration default].allowSelectOriginal = YES;
        //视频最大时长，默认是5分钟，可以更改为更大
        [ZLPhotoConfiguration default].maxSelectVideoDuration = 300;
        [ZLPhotoConfiguration default].maxEditVideoTime = 300;
//        [ZLPhotoConfiguration default].cameraConfiguration.sessionPreset = CaptureSessionPresetVga640x480;
        [ZLPhotoConfiguration default].cameraConfiguration.sessionPreset = CaptureSessionPresetHd1280x720; // 0229更新
        [ZLPhotoConfiguration default].cameraConfiguration.videoExportType = VideoExportTypeMp4;
        // 相册、图片  视频视频上传
        ZLPhotoPreviewSheet *ps = [[ZLPhotoPreviewSheet alloc] initWithSelectedAssets:@[]];
        ps.selectImageBlock = ^(NSArray<ZLResultModel *> *models, BOOL isOriginal) {
            NSMutableArray *photos = [[NSMutableArray alloc] init];
            [models enumerateObjectsUsingBlock:^(ZLResultModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [photos addObject:obj.asset];
            }];
// 上传图片视频
            [weakself recursiveHandle:photos isFullImage:isOriginal];
        };
        [ps showPhotoLibraryWithSender:[self.delegate requireNavi]];
    } else if(itemTag == 2) {
#if TARGET_IPHONE_SIMULATOR
        [self makeToast:(_isChinese?@"模拟器不支持相机":@"The emulator does not support cameras") duration:1 position:CSToastPositionCenter];
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.delegate = self;
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [navi presentViewController:picker animated:YES completion:nil];
#else
        [self checkAndAlertCameraAccessRight];
        
        [ZLPhotoConfiguration default].allowEditVideo = YES;
        ZLCustomCamera *cc = [[ZLCustomCamera alloc] init];
        cc.takeDoneBlock = ^(UIImage * _Nullable image, NSURL * _Nullable url) {
            NSLog(@"select the image");
            if (image) {
                [self.delegate imageDidCapture:image fullImage:NO];
            } else {
                NSData *data = [[NSData alloc] initWithContentsOfURL:url];
                NSString *cacheDir = [[QWERConfigManager globalManager] cachePathOf:self.conversation mediaType:Media_Type_VIDEO];
                NSString *desFileName = [cacheDir stringByAppendingPathComponent:[url lastPathComponent]];
                [data writeToFile:desFileName atomically:YES];
                
                UIImage *thumb = [self getVideoThumbnailWithUrl:url second:1];
                
                AVURLAsset * asset = [AVURLAsset assetWithURL:url];
                CMTime   time = [asset duration];
                int seconds = ceil(time.value/time.timescale);
                
                [self.delegate videoDidCapture:desFileName thumbnail:thumb duration:seconds];
            }
        };
        [[self.delegate requireNavi] showDetailViewController:cc sender:nil];
        [self notifyTyping:2];
#endif
    } else if(itemTag == 3){
        WDCARLocationViewController *vc = [[WDCARLocationViewController alloc] initWithDelegate:self];
        
        UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:vc];
        [navi presentViewController:nav animated:YES completion:nil];
        [self notifyTyping:3];
        return;
    } else if(itemTag == 4) {
#if WFCU_SUPPORT_VOIP
        UIActionSheet *actionSheet =
        [[UIActionSheet alloc] initWithTitle:nil
                                    delegate:self
                           cancelButtonTitle:(_isChinese?@"取消":@"Hủy")
                      destructiveButtonTitle:(_isChinese?@"视频":@"Video")
                           otherButtonTitles:(_isChinese?@"音频":@"Gọi thoại"), nil];
        [actionSheet showInView:self.parentView];
#endif
    } else if(itemTag == 5) {
        NSArray*documentTypes =@[
                @"public.content",
                @"public.data",
                @"com.microsoft.powerpoint.ppt",
                @"com.microsoft.word.doc",
                @"com.microsoft.excel.xls",
                @"com.microsoft.powerpoint.pptx",
                @"com.microsoft.word.docx",
                @"com.microsoft.excel.xlsx",
                @"public.avi",
                @"public.3gpp",
                @"public.mpeg-4",
                @"com.compuserve.gif",
                @"public.jpeg",
                @"public.png",
                @"public.plain-text",
                @"com.adobe.pdf"
                ];

        UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:documentTypes inMode:UIDocumentPickerModeOpen];
        picker.delegate = self;
        
        if (@available(iOS 11.0, *)) {
            picker.allowsMultipleSelection = YES;
        }
        
        picker.modalPresentationStyle = UIModalPresentationFullScreen;
        [navi presentViewController:picker animated:YES completion:nil];
        
        [self notifyTyping:4];
        
    } else if(itemTag == 6) {
        
        if (_delegate) {
            [_delegate didClickCard];
        }
        return;
        
        FRSDAContactListVC *pvc = [[FRSDAContactListVC alloc] init];
        pvc.selectContact = YES;
        pvc.multiSelect = NO;
        
        pvc.withoutCheckBox = YES;
        
        __weak typeof(self)ws = self;
        
        pvc.selectResult = ^(NSArray<NSString *> *contacts) {
            if (contacts.count == 1) {
                WFCCCardMessageContent *card = [WFCCCardMessageContent cardWithTarget:contacts[0] type:CardType_User from:[WFCCNetworkService sharedInstance].userId];
                
//                WFCCMessage *message = [[WFCCMessage alloc] init];
//                message.content = card;
                
                /** 1124日注销
                QWASZShareMessageView *shareView = [QWASZShareMessageView createViewFromNib];
                    
                shareView.conversation = ws.conversation;
                shareView.message = message;
                shareView.forwardDone = ^(BOOL success) {
                    if (success) {
                        [[ws.delegate requireNavi] dismissViewControllerAnimated:YES completion:nil];
                    } else {
                        [ws makeToast:WFCString(@"SendFailure") duration:1 position:CSToastPositionCenter];
                    }
                };
                TYAlertController *alertController = [TYAlertController alertControllerWithAlertView:shareView preferredStyle:TYAlertControllerStyleAlert]
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[ws.delegate requireNavi] presentViewController:alertController animated:YES completion:nil];
                });
                 */
                
                QWASZShareCardsPopView *popView = [[QWASZShareCardsPopView alloc] init];
                [popView setCardsBlock:^{
                    WFCCCardMessageContent *card = [WFCCCardMessageContent cardWithTarget:contacts[0] type:CardType_User from:[WFCCNetworkService sharedInstance].userId];
                    
                    [[WFCCIMService sharedWFCIMService] send:ws.conversation content:card success:^(long long messageUid, long long timestamp) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[ws.delegate requireNavi] dismissViewControllerAnimated:YES completion:nil];
                        });
                    } error:^(int error_code) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [ws makeToast:(_isChinese?@"发送失败":@"Thất bại!") duration:1 position:CSToastPositionCenter];
                        });
                    }];
                }];
                
                WFCCUserInfo *userinfo = [[WFCCIMService sharedWFCIMService] getUserInfo:contacts[0] refresh:NO]; // 发送给他
                
                NSString *nameA = (userinfo.friendAlias.length > 0 ? userinfo.friendAlias : userinfo.displayName);
                NSString *imgA = userinfo.portrait;
                NSString *nameB = @"";
                NSString *imgB = @"";
                if (ws.conversation.type == Single_Type) {
                    WFCCUserInfo *targetUserinfo = [[WFCCIMService sharedWFCIMService] getUserInfo:ws.conversation.target refresh:YES];
                    
                    nameB = (targetUserinfo.friendAlias.length > 0 ? targetUserinfo.friendAlias : targetUserinfo.displayName);
                    imgB = targetUserinfo.portrait;
                }else if (ws.conversation.type == Group_Type) {
                    WFCCGroupInfo *groupInfo = [[WFCCIMService sharedWFCIMService] getGroupInfo:ws.conversation.target refresh:NO];
                    
                    nameB = groupInfo.displayName;
                    imgB = groupInfo.portrait;
                }else if (ws.conversation.type == Channel_Type) {
                    WFCCChannelInfo *channelInfo = [[WFCCIMService sharedWFCIMService] getChannelInfo:ws.conversation.target refresh:NO];
                    
                    nameB = channelInfo.name;
                    imgB = channelInfo.portrait;
                }else if (ws.conversation.type == SecretChat_Type) {
                    NSString *userId = [[WFCCIMService sharedWFCIMService] getSecretChatInfo:ws.conversation.target].userId;
                    WFCCUserInfo *targetUserinfo = [[WFCCIMService sharedWFCIMService] getUserInfo:userId refresh:NO];
                    
                    nameB = (targetUserinfo.friendAlias.length > 0 ? targetUserinfo.friendAlias : targetUserinfo.displayName);
                    imgB = targetUserinfo.portrait;
                }
                if (self->_isChinese) {
                    [popView showCommand:[NSString stringWithFormat:@"将%@发送给%@",nameA, nameB] imgA: imgA imB: imgB];
                }else {
//                    [popView showCommand:[NSString stringWithFormat:@"%@ gửi %@",nameA, nameB] imgA: imgA imB: imgB];
                    
                    [popView showCommand:[NSString stringWithFormat:@"Của %@ đến %@",nameA, nameB] imgA: imgA imB: imgB];

                }
                
                
                /**
                 
                 WFCCUserInfo *targetUserinfo = [[WFCCIMService sharedWFCIMService] getUserInfo:self.targetId refresh:NO];
                 
                 WFCCUserInfo *userinfo = _dataArray[indexPath.section][indexPath.row];
                 
                 SendBusinessCardsPopView *popView = [[SendBusinessCardsPopView alloc] init];
                 WS(weakself)
                 [popView setCardsBlock:^{
         //            @param targetId 目标Id
         //            @param type 类型，0 用户，1 群组， 3 频道。
         //            @param fromUser 分享用户。
                     WFCCCardMessageContent *card = [WFCCCardMessageContent cardWithTarget:targetUserinfo.userId type:CardType_User from:userinfo.userId];
                     
                     WFCCConversation *conversation = [WFCCConversation conversationWithType:Single_Type target:userinfo.userId line:0];
                     
                     [[WFCCIMService sharedWFCIMService] send:conversation content:card success:^(long long messageUid, long long timestamp) {
                         dispatch_async(dispatch_get_main_queue(), ^{
                             [self.navigationController popViewControllerAnimated:YES];
                         });
                     } error:^(int error_code) {
                         
                     }];
                 }];
                 [popView showCommand:[NSString stringWithFormat:@"推荐%@给%@",(targetUserinfo.friendAlias.length > 0 ? targetUserinfo.friendAlias : targetUserinfo.displayName), (userinfo.friendAlias.length > 0 ? userinfo.friendAlias : userinfo.displayName)] imgA:targetUserinfo.portrait imB:userinfo.portrait];
                 
                 */
                
            }
        };
        
        pvc.cancelSelect = ^(void) {
            NSLog(@"canceled");
        };
        
        
        UINavigationController *navi = [[UINavigationController alloc] initWithRootViewController:pvc];
        [[self.delegate requireNavi] presentViewController:navi animated:YES completion:nil];
    } else if(itemTag == 7) {
    }
}

- (void)checkAndAlertCameraAccessRight {
    AVAuthorizationStatus authStatus =
    [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusDenied ||
        authStatus == AVAuthorizationStatusRestricted) {
        UIAlertView *alertView = [[UIAlertView alloc]
                                  initWithTitle:(_isChinese?@"拍照权限":@"Quyền chụp ảnh")
                                  message:(_isChinese?@"需要拍照权限，请在设置里打开":@"Cần có quyền chụp ảnh, vui lòng bật thiết lập")
                                  delegate:nil
                                  cancelButtonTitle:(_isChinese?@"确认":@"Xác nhận")
                                  otherButtonTitles:nil, nil];
        [alertView show];
    }
}

#define k_THUMBNAIL_IMG_WIDTH  120//缩略图及cell大小
#define k_FPS 1//一秒想取多少帧

//这本来是个异步调用，但写成这种方便大家看和复制来直接测试
- (UIImage*)getVideoThumbnailWithUrl:(NSURL*)videoUrl second:(CGFloat)second
{
    if (!videoUrl)
    {
        NSLog(@"WARNING:videoUrl为空");
        return nil;
    }
    AVURLAsset *urlSet = [AVURLAsset assetWithURL:videoUrl];
    AVAssetImageGenerator *imageGenerator = [AVAssetImageGenerator assetImageGeneratorWithAsset:urlSet];
    imageGenerator.appliesPreferredTrackTransform = YES;
    imageGenerator.apertureMode = AVAssetImageGeneratorApertureModeEncodedPixels;
    
    /*
     如果不需要获取缩略图，就设置为NO，如果需要获取缩略图，则maximumSize为获取的最大尺寸。
     以BBC为例，getThumbnail = NO时，打印宽高数据为：1920*1072。
     getThumbnail = YES时，maximumSize为100*100。打印宽高数据为：100*55.
     注：不乘[UIScreen mainScreen].scale，会发现缩略图在100*100很虚。
     */
    BOOL getThumbnail = YES; // 默认为YES  0229改为NO
    if (getThumbnail)
    {
        CGFloat width = [UIScreen mainScreen].scale * k_THUMBNAIL_IMG_WIDTH;
        imageGenerator.maximumSize =  CGSizeMake(width, width);
    }
    NSError *error = nil;
    CMTime time = CMTimeMake(second,k_FPS);
    CMTime actucalTime;
    CGImageRef cgImage = [imageGenerator copyCGImageAtTime:time actualTime:&actucalTime error:&error];
    if (error) {
        NSLog(@"ERROR:获取视频图片失败,%@",error.domain);
    }
    CMTimeShow(actucalTime);
    UIImage *image = [UIImage imageWithCGImage:cgImage];
    NSLog(@"imageWidth=%f,imageHeight=%f",image.size.width,image.size.height);
    CGImageRelease(cgImage);
    return image;
}

#pragma mark  UIDocumentDelegate 文件选择回调
- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    [controller dismissViewControllerAnimated:NO completion:nil];
    __block NSMutableArray *arr = [NSMutableArray array];

    [MBProgressHUD showHUDAddedTo:self.parentView animated:YES];
    [MBProgressHUD HUDForView:self.parentView].mode = MBProgressHUDModeDeterminate;
    [MBProgressHUD HUDForView:self.parentView].label.text = (_isChinese?@"处理中...":@"Xử lý …");
    
    for (NSURL *url in urls) {
       //获取授权
       BOOL fileUrlAuthozied = [url startAccessingSecurityScopedResource];
       if(fileUrlAuthozied){
           //通过文件协调工具来得到新的文件地址，以此得到文件保护功能
           NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
           NSError *error;
           
           [fileCoordinator coordinateReadingItemAtURL:url options:0 error:&error byAccessor:^(NSURL *newURL) {
               if (!error) {
                   NSData *fileData = [NSData dataWithContentsOfURL:newURL];
                   NSString *cacheDir = [[QWERConfigManager globalManager] cachePathOf:self.conversation mediaType:Media_Type_FILE];
                   NSString *desFileName = [cacheDir stringByAppendingPathComponent:[newURL lastPathComponent]];
                   [fileData writeToFile:desFileName atomically:YES];
                   [arr addObject:desFileName];
               }
           }];
           
           [url stopAccessingSecurityScopedResource];

       }else{
           NSLog(@"授权失败");
       }
    }
    [MBProgressHUD hideHUDForView:self.parentView animated:YES];
    [self.delegate didSelectFiles:arr];
}

#pragma mark - UIImagePickerControllerDelegate<NSObject>
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<UIImagePickerControllerInfoKey, id> *)info {
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    if ([mediaType isEqualToString:@"public.movie"]) {
        NSURL *videoURL = [info objectForKey:UIImagePickerControllerMediaURL];
        NSString *url = [videoURL absoluteString];
        url = [url stringByReplacingOccurrencesOfString:@"file:///private" withString:@""];
        //获取视频的thumbnail
        AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:videoURL options:nil];
        AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
        generate1.appliesPreferredTrackTransform = YES;
        NSError *err = NULL;
        CMTime time = CMTimeMake(1, 2);
        CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:&err];
        UIImage *thumbnail = [[UIImage alloc] initWithCGImage:oneRef];
        thumbnail = [WFCCUtilities generateThumbnail:thumbnail withWidth:301 withHeight:301];
        
        AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:videoURL options:nil];
//        NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
        
        NSString *CompressionVideoPaht = [WFCCUtilities getDocumentPathWithComponent:@"/VIDEO"];
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:@"AVAssetExportPreset960x540"];
        
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];// 用时间, 给文件重新命名, 防止视频存储覆盖,
        
        [formater setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];
        
        NSFileManager *manager = [NSFileManager defaultManager];
        
        BOOL isExists = [manager fileExistsAtPath:CompressionVideoPaht];
        if (!isExists) {
             [manager createDirectoryAtPath:CompressionVideoPaht withIntermediateDirectories:YES attributes:nil error:nil];
         }
//        
        NSString *resultPath = [CompressionVideoPaht stringByAppendingPathComponent:[NSString stringWithFormat:@"outputJFVideo-%@.mov", [formater stringFromDate:[NSDate date]]]];
        
        NSLog(@"resultPath = %@",resultPath);
        
        exportSession.outputURL = [NSURL fileURLWithPath:resultPath];
        
        exportSession.outputFileType = AVFileTypeMPEG4;
        
        exportSession.shouldOptimizeForNetworkUse = YES;
        
        // 0807注销
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:picker.view animated:YES];
        hud.label.text = (_isChinese?@"处理中...":@"Xử lý…");
        [hud showAnimated:YES];
        
        __weak typeof(self)ws = self;
        [exportSession exportAsynchronouslyWithCompletionHandler:^(void){
             if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                 NSData *data = [NSData dataWithContentsOfFile:resultPath];
                 float memorySize = (float)data.length / 1024 / 1024;
                 NSLog(@"视频压缩后大小 %f", memorySize);
                 dispatch_async(dispatch_get_main_queue(), ^{
//                     [hud hideAnimated:YES];
                     [picker dismissViewControllerAnimated:YES completion:nil];
                     [ws.delegate videoDidCapture:resultPath thumbnail:thumbnail duration:10];
                 });
             } else {
                 dispatch_async(dispatch_get_main_queue(), ^{
//                     [hud hideAnimated:YES];
                     [picker dismissViewControllerAnimated:YES completion:nil];
                 });
                 NSLog(@"压缩失败");
             }
         }];
        

    } else if ([mediaType isEqualToString:@"public.image"]) {
        [picker dismissViewControllerAnimated:YES completion:nil];
        UIImage* image = [info objectForKey:UIImagePickerControllerEditedImage];
        if (!image)
            image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [self.delegate imageDidCapture:image fullImage:NO];
    }
}
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - LocationViewControllerDelegate <NSObject>

- (void)onSendLocation:(WDCARLocationPoint *)locationPoint {
    [self.delegate locationDidSelect:locationPoint.coordinate locationName:locationPoint.title mapScreenShot:locationPoint.thumbnail];
}

#pragma mark - UIActionSheetDelegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
#if WFCU_SUPPORT_VOIP
        [self.delegate didTouchVideoBtn:NO];
#endif
    } else if(buttonIndex == 1) {
#if WFCU_SUPPORT_VOIP
        [self.delegate didTouchVideoBtn:YES];
#endif
    }
}

#pragma mark - WDCARPublicMenuButtonDelegate
- (void)didTapButton:(WDCARPublicMenuButton *)button menu:(WFCCChannelMenu *)channelMenu {
    for (WDCARPublicMenuButton *menuButton in self.menuButtons) {
        if (button != menuButton) {
            menuButton.expended = NO;
        }
    }
    WFCCChannelMenuEventMessageContent *content = [[WFCCChannelMenuEventMessageContent alloc] init];
    content.menu = channelMenu;
    [[WFCCIMService sharedWFCIMService] send:self.conversation content:content success:nil error:nil];
    if ([self.delegate respondsToSelector:@selector(didTapChannelMenu:)]) {
        [self.delegate didTapChannelMenu:channelMenu];
    }
}

#pragma mark - WFCUMentionUserDelegate
- (void)didMentionType:(int)type user:(NSString *)userId range:(NSRange)range text:(NSString *)text {
    [self textView:self.textInputView shouldChangeTextInRange:NSMakeRange(range.location, 0) replacementText:text];
    
    [self.mentionInfos addObject:[[WFCUMetionInfo alloc] initWithType:type target:userId range:NSMakeRange(range.location, range.length)]];
    
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc]initWithString:text];
    UIFont *font = [UIFont fontWithName:@"Heiti SC-Bold" size:16];
    [attStr addAttribute:(__bridge NSString*)kCTFontAttributeName value:(id)CFBridgingRelease(CTFontCreateWithName((CFStringRef)font.fontName,
                                                                                                                   16,
                                                                                                                   NULL)) range:NSMakeRange(0, text.length)];
    
    [self.textInputView.textStorage
     insertAttributedString:attStr  atIndex:range.location];
    range.location += range.length;
    range.length = 0;
    self.textInputView.selectedRange = range;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.textInputView.isFirstResponder) {
            [self.textInputView becomeFirstResponder];
        }
    });
}

- (void)didCancelMentionAtRange:(NSRange)range {
    NSMutableAttributedString *attStr = [[NSMutableAttributedString alloc]initWithString:@"@"];
    UIFont *font = [UIFont fontWithName:@"Heiti SC-Bold" size:16];
    [attStr addAttribute:(__bridge NSString*)kCTFontAttributeName value:(id)CFBridgingRelease(CTFontCreateWithName((CFStringRef)font.fontName,
                                                                                                                   16,
                                                                                                                   NULL)) range:NSMakeRange(0, 1)];
    

    [self.textInputView.textStorage
     insertAttributedString:attStr  atIndex:range.location];
    range.location += 1;
    range.length = 0;
    
    self.textInputView.selectedRange = range;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.textInputView.isFirstResponder) {
            [self.textInputView becomeFirstResponder];
        }
    });
}

- (void)convertAvcompositionToAvasset:(AVComposition *)composition completion:(void (^)(AVAsset *asset))completion {
    // 导出视频
    AVAssetExportSession *exporter = [AVAssetExportSession exportSessionWithAsset:composition presetName:AVAssetExportPresetHighestQuality];
    // 生成一个文件路径
    NSInteger randNumber = arc4random();
    NSString *exportPath = [NSTemporaryDirectory() stringByAppendingString:[NSString stringWithFormat:@"%ldvideo.mov", randNumber]];
    NSURL *exportURL = [NSURL fileURLWithPath:exportPath];
    // 导出
    if (exporter) {
        exporter.outputURL = exportURL;  // 设置路径
        exporter.outputFileType = AVFileTypeQuickTimeMovie;
        exporter.shouldOptimizeForNetworkUse = YES;
        [exporter exportAsynchronouslyWithCompletionHandler:^{
            dispatch_async(dispatch_get_main_queue(), ^{
                if (AVAssetExportSessionStatusCompleted == exporter.status) {   // 导出完成
                    NSURL *URL = exporter.outputURL;
                    AVAsset *avAsset = [AVAsset assetWithURL:URL];
                     if (completion) {
                        completion(avAsset);
                    }
                } else {
                    if (completion) {
                        completion(nil);
                    }
                }
            });
        }];
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion(nil);
            }
        });
    }
}
- (void)handleVideo:(NSURL *)url photos:(NSMutableArray<PHAsset *> *)photos isFullImage:(BOOL)isFullImage {
    AVURLAsset *asset1 = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *generate1 = [[AVAssetImageGenerator alloc] initWithAsset:asset1];
    generate1.appliesPreferredTrackTransform = YES;
    NSError *err = NULL;
    CMTime time = CMTimeMake(1, 2);
    CGImageRef oneRef = [generate1 copyCGImageAtTime:time actualTime:NULL error:&err];
    UIImage *thumbnail = [[UIImage alloc] initWithCGImage:oneRef];
//    thumbnail = [WFCCUtilities generateThumbnail:thumbnail withWidth:(UIScreen.mainScreen.bounds.size.width + 1) withHeight:(UIScreen.mainScreen.bounds.size.width + 1)];
    thumbnail = [WFCCUtilities generateThumbnail:thumbnail withWidth:750 withHeight:750];

    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:url options:nil];
//    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];

    NSString *CompressionVideoPaht = [WFCCUtilities getDocumentPathWithComponent:@"/VIDEO"];
    
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:(isFullImage ? @"AVAssetExportPresetHighestQuality" : @"AVAssetExportPreset960x540")];
//    AVAssetExportPreset1280x720
    NSDateFormatter *formater = [[NSDateFormatter alloc] init];// 用时间, 给文件重新命名, 防止视频存储覆盖,

    /**
     AVAssetExportPresetMediumQuality   0.9M
     AVAssetExportPreset640x480    2.916352M
     AVAssetExportPreset960x540    5.536203
     AVAssetExportPresetHighestQuality   11.173965
     
     
     AVAssetExportPresetHighestQuality
     51M
     */
    
    [formater setDateFormat:@"yyyy-MM-dd_HH-mm-ss"];

    NSFileManager *manager = [NSFileManager defaultManager];

    BOOL isExists = [manager fileExistsAtPath:CompressionVideoPaht];
    if (!isExists) {
         [manager createDirectoryAtPath:CompressionVideoPaht withIntermediateDirectories:YES attributes:nil error:nil];
     }
//
    NSString *resultPath = [CompressionVideoPaht stringByAppendingPathComponent:[NSString stringWithFormat:@"outputJFVideo-%@.mov", [formater stringFromDate:[NSDate date]]]];
    
    exportSession.outputURL = [NSURL fileURLWithPath:resultPath];
    
    NSLog(@"resultPath = %@",resultPath);
    
    exportSession.outputFileType = AVFileTypeMPEG4;

    exportSession.shouldOptimizeForNetworkUse = YES;

    CMTime time2 = [asset1 duration];
    int seconds = ceil(time2.value/time2.timescale);
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [MBProgressHUD showHUDAddedTo:self.parentView animated:YES];
        [MBProgressHUD HUDForView:self.parentView].mode = MBProgressHUDModeDeterminate;
        [MBProgressHUD HUDForView:self.parentView].label.text = (self->_isChinese?@"处理中...":@"Xử lý …");
    });
    
    __weak typeof(self)ws = self;
    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (exportSession.status == AVAssetExportSessionStatusCompleted) {
                NSData *data = [NSData dataWithContentsOfFile:resultPath];
                float memorySize = (float)data.length / 1024 / 1024;
                NSLog(@"resultPath===%@\n视频压缩后大小 %f",resultPath, memorySize);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:ws.parentView animated:YES];
                    [ws.delegate videoDidCapture:resultPath thumbnail:thumbnail duration:seconds];
                });
                    // 0529 解决多个视频处理失败的问题、有了延迟就没问题了
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                        [ws recursiveHandle:photos isFullImage:isFullImage];
                    });
//                    [ws recursiveHandle:photos isFullImage:isFullImage];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [MBProgressHUD hideHUDForView:ws.parentView animated:YES];
                    [ws.parentView makeToast:(self->_isChinese?@"视频处理失败":@"Video xử lý thất bại") duration:1 position:CSToastPositionCenter];
                });
                NSLog(@"压缩失败");
            }
        });
     }];
//    [exportSession exportAsynchronouslyWithCompletionHandler:^(void) {
//         if (exportSession.status == AVAssetExportSessionStatusCompleted) {
//             NSData *data = [NSData dataWithContentsOfFile:resultPath];
//             float memorySize = (float)data.length / 1024 / 1024;
//             NSLog(@"resultPath===%@\n视频压缩后大小 %f",resultPath, memorySize);
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 [MBProgressHUD hideHUDForView:self.parentView animated:YES];
//                 [ws.delegate videoDidCapture:resultPath thumbnail:thumbnail duration:seconds];
//             });
//             [ws recursiveHandle:photos isFullImage:isFullImage];
//         } else {
//             dispatch_async(dispatch_get_main_queue(), ^{
//                 [MBProgressHUD hideHUDForView:self.parentView animated:YES];
//                 [self.parentView makeToast:(self->_isChinese?@"视频处理失败":@"Video processing failure") duration:1 position:CSToastPositionCenter];
//             });
//             NSLog(@"压缩失败");
//         }
//     }];
}
- (void)recursiveHandle:(NSMutableArray<PHAsset *> *)photos isFullImage:(BOOL)isFullImage {
    if (photos.count == 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [MBProgressHUD hideHUDForView:self.parentView animated:YES];
        });
    }else{
        PHAsset *phAsset = photos[0];
        [photos removeObjectAtIndex:0];
        __weak typeof(self) weakself = self;
        if (phAsset.mediaType == PHAssetMediaTypeVideo) {
            PHVideoRequestOptions *options = [[PHVideoRequestOptions alloc] init];
            options.networkAccessAllowed = YES;
            options.version = PHImageRequestOptionsVersionCurrent;
            options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
            
            PHImageManager *manager = [PHImageManager defaultManager];
            [manager requestAVAssetForVideo:phAsset options:options resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {

                if ([asset isKindOfClass:[AVComposition class]]) {
                    [weakself convertAvcompositionToAvasset:(AVComposition *)asset completion:^(AVAsset *asset) {
                        AVURLAsset *urlAsset = (AVURLAsset *)asset;
                        [weakself handleVideo:urlAsset.URL photos:photos isFullImage:isFullImage];
                    }];
                } else {
                    // 相册视频走这儿
                    AVURLAsset *urlAsset = (AVURLAsset *)asset;
                    [weakself handleVideo:urlAsset.URL photos:photos isFullImage:isFullImage];
                }
            }];
        } else if(phAsset.mediaType == PHAssetMediaTypeImage) {
            PHImageRequestOptions *imageRequestOption = [[PHImageRequestOptions alloc] init];
            imageRequestOption.networkAccessAllowed = YES;
            PHCachingImageManager *cachingImageManager = [[PHCachingImageManager alloc] init];
            cachingImageManager.allowsCachingHighQualityImages = NO;
            [cachingImageManager
             requestImageDataForAsset:phAsset
             
             options:imageRequestOption
             
             resultHandler:^(NSData *_Nullable imageData, NSString *_Nullable dataUTI,
                                                                   UIImageOrientation orientation, NSDictionary *_Nullable info) {
                   BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey] && ![[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
                   if (downloadFinined) {
                       if ([weakself isGifWithImageData:imageData] && [weakself.delegate respondsToSelector:@selector(gifDidCapture:)]) {
                           [weakself.delegate gifDidCapture:imageData];
                       } else if ([weakself.delegate respondsToSelector:@selector(imageDidCapture:fullImage:)]) {
                           [weakself.delegate imageDidCapture:[UIImage imageWithData:imageData] fullImage:isFullImage];
                       }
                       
                       [weakself recursiveHandle:photos isFullImage:isFullImage];
                   }

                   if ([info objectForKey:PHImageErrorKey]) {
                       [weakself.parentView makeToast:(self->_isChinese?@"下载图片失败":@"Tải về hình ảnh thất bại")];
                       [weakself recursiveHandle:photos isFullImage:isFullImage];
                   }
                                                       
            }];
        }
        
    }
        
}

- (BOOL)isGifWithImageData: (NSData *)data {
    if ([[self contentTypeWithImageData:data] isEqualToString:@"gif"]) {
        return YES;
    }
    return NO;
}

- (NSString *)contentTypeWithImageData: (NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    switch (c) {
        case 0xFF:
            return @"jpeg";
        case 0x89:
            return @"png";
        case 0x47:
            return @"gif";
        case 0x49:
        case 0x4D:
            return @"tiff";
        case 0x52:
            if ([data length] < 12) {
                return nil;
            }
            
            NSString *testString = [[NSString alloc] initWithData:[data subdataWithRange:NSMakeRange(0, 12)] encoding:NSASCIIStringEncoding];
            if ([testString hasPrefix:@"RIFF"] && [testString hasSuffix:@"WEBP"]) {
                return @"webp";
            }
            return nil;
    }
    return nil;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
