#import "SsbmPadOnlinePlayViewController.h"

#include <cmath>

@interface SsbmPadOnlinePlayViewController () <UITextFieldDelegate>
@end

@implementation SsbmPadOnlinePlayViewController {
    UISegmentedControl *_roleControl;
    UITextField *_nicknameField;
    UITextField *_addressField;
    UITextField *_portField;
    UISwitch *_automaticBufferSwitch;
    UIStepper *_bufferStepper;
    UILabel *_bufferValueLabel;
    UIButton *_connectButton;
    UILabel *_stateLabel;
    UIStackView *_playersStack;
    UIButton *_readyButton;
    UIButton *_startButton;
    UIStackView *_setupStack;
    UIStackView *_lobbyStack;
    BOOL _localReady;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Experimental Multiplayer";
    self.view.backgroundColor = [UIColor colorWithRed:0.035 green:0.055 blue:0.10 alpha:1.0];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain
               target:self action:@selector(cancel:)];

    UILabel *intro = [UILabel new];
    intro.text = @"Direct Peer Connection";
    intro.textColor = UIColor.whiteColor;
    intro.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];

    UILabel *detail = [UILabel new];
    detail.text = @"Each device runs the same Melee match locally and exchanges controller input; the other player appears on another GameCube port. The host creates a direct lobby, the friend joins with the host's address, both mark Ready, and the host starts. There are no room codes or matchmaking servers yet, and complete matches are not yet reliable.";
    detail.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    detail.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    detail.numberOfLines = 0;

    _roleControl = [[UISegmentedControl alloc] initWithItems:@[@"Host", @"Join"]];
    _roleControl.selectedSegmentIndex = 0;
    _roleControl.accessibilityLabel = @"Host or join";
    [_roleControl addTarget:self action:@selector(roleChanged:)
           forControlEvents:UIControlEventValueChanged];

    _nicknameField = [self textFieldWithPlaceholder:@"Nickname"];
    _nicknameField.text = UIDevice.currentDevice.name.length > 0 ? @"Player" : @"Player";
    _nicknameField.textContentType = UITextContentTypeNickname;
    _nicknameField.returnKeyType = UIReturnKeyNext;

    _addressField = [self textFieldWithPlaceholder:@"Host IP or hostname"];
    _addressField.keyboardType = UIKeyboardTypeURL;
    _addressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _addressField.autocorrectionType = UITextAutocorrectionTypeNo;
    _addressField.returnKeyType = UIReturnKeyNext;

    _portField = [self textFieldWithPlaceholder:@"UDP port (default 2626)"];
    _portField.text = @"2626";
    _portField.keyboardType = UIKeyboardTypeNumberPad;

    UILabel *portHelp = [UILabel new];
    portHelp.text = @"2626 is Dolphin's standard direct-NetPlay UDP port, not a server address. Both players use the same value. Same Wi-Fi is simplest; internet hosts usually need UDP forwarding or a private VPN.";
    portHelp.textColor = [UIColor colorWithWhite:0.68 alpha:1.0];
    portHelp.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightRegular];
    portHelp.numberOfLines = 0;

    UILabel *automaticLabel = [UILabel new];
    automaticLabel.text = @"Automatic input buffer";
    automaticLabel.textColor = UIColor.whiteColor;
    automaticLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightMedium];
    _automaticBufferSwitch = [UISwitch new];
    _automaticBufferSwitch.on = YES;
    _automaticBufferSwitch.accessibilityLabel = @"Automatic input buffer";
    [_automaticBufferSwitch addTarget:self action:@selector(bufferModeChanged:)
                       forControlEvents:UIControlEventValueChanged];
    UIStackView *automaticRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[automaticLabel, _automaticBufferSwitch]];
    automaticRow.axis = UILayoutConstraintAxisHorizontal;
    automaticRow.distribution = UIStackViewDistributionEqualSpacing;
    automaticRow.alignment = UIStackViewAlignmentCenter;

    _bufferValueLabel = [UILabel new];
    _bufferValueLabel.text = @"2 frames";
    _bufferValueLabel.textColor = [UIColor colorWithWhite:0.80 alpha:1.0];
    _bufferValueLabel.font = [UIFont monospacedDigitSystemFontOfSize:14.0
                                                               weight:UIFontWeightRegular];
    _bufferStepper = [UIStepper new];
    _bufferStepper.minimumValue = 1;
    _bufferStepper.maximumValue = 20;
    _bufferStepper.value = 2;
    _bufferStepper.enabled = NO;
    _bufferStepper.accessibilityLabel = @"Manual input buffer frames";
    [_bufferStepper addTarget:self action:@selector(bufferChanged:)
               forControlEvents:UIControlEventValueChanged];
    UIStackView *bufferRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[_bufferValueLabel, _bufferStepper]];
    bufferRow.axis = UILayoutConstraintAxisHorizontal;
    bufferRow.distribution = UIStackViewDistributionEqualSpacing;
    bufferRow.alignment = UIStackViewAlignmentCenter;

    _connectButton = [self primaryButtonWithTitle:@"Host Game"
                                           action:@selector(connect:)];

    _setupStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        _roleControl, _nicknameField, _addressField, _portField, portHelp,
        automaticRow, bufferRow, _connectButton,
    ]];
    _setupStack.axis = UILayoutConstraintAxisVertical;
    _setupStack.spacing = 12.0;

    UILabel *playersTitle = [UILabel new];
    playersTitle.text = @"Players";
    playersTitle.textColor = UIColor.whiteColor;
    playersTitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];

    _playersStack = [UIStackView new];
    _playersStack.axis = UILayoutConstraintAxisVertical;
    _playersStack.spacing = 8.0;

    _stateLabel = [UILabel new];
    _stateLabel.text = @"Connecting…";
    _stateLabel.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    _stateLabel.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    _stateLabel.numberOfLines = 0;
    _stateLabel.accessibilityIdentifier = @"online-play-status";

    _readyButton = [self secondaryButtonWithTitle:@"Ready"
                                            action:@selector(toggleReady:)];
    _startButton = [self primaryButtonWithTitle:@"Start Match"
                                          action:@selector(start:)];
    _startButton.enabled = NO;
    UIStackView *lobbyActions = [[UIStackView alloc]
        initWithArrangedSubviews:@[_readyButton, _startButton]];
    lobbyActions.axis = UILayoutConstraintAxisHorizontal;
    lobbyActions.spacing = 12.0;
    lobbyActions.distribution = UIStackViewDistributionFillEqually;

    _lobbyStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        playersTitle, _playersStack, _stateLabel, lobbyActions,
    ]];
    _lobbyStack.axis = UILayoutConstraintAxisVertical;
    _lobbyStack.spacing = 12.0;
    _lobbyStack.hidden = YES;

    UIStackView *content = [[UIStackView alloc]
        initWithArrangedSubviews:@[intro, detail, _setupStack, _lobbyStack]];
    content.axis = UILayoutConstraintAxisVertical;
    content.spacing = 14.0;
    content.translatesAutoresizingMaskIntoConstraints = NO;

    UIScrollView *scroll = [UIScrollView new];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:scroll];
    [scroll addSubview:content];
    UILayoutGuide *frame = scroll.frameLayoutGuide;
    UILayoutGuide *layout = scroll.contentLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [scroll.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [scroll.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        [scroll.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [scroll.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [content.leadingAnchor constraintEqualToAnchor:layout.leadingAnchor constant:24.0],
        [content.trailingAnchor constraintEqualToAnchor:layout.trailingAnchor constant:-24.0],
        [content.topAnchor constraintEqualToAnchor:layout.topAnchor constant:18.0],
        [content.bottomAnchor constraintEqualToAnchor:layout.bottomAnchor constant:-24.0],
        [content.widthAnchor constraintLessThanOrEqualToConstant:620.0],
        [content.centerXAnchor constraintEqualToAnchor:frame.centerXAnchor],
    ]];
    [self roleChanged:_roleControl];
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [UITextField new];
    field.placeholder = placeholder;
    field.accessibilityLabel = placeholder;
    field.delegate = self;
    field.textColor = UIColor.whiteColor;
    field.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    field.layer.cornerRadius = 10.0;
    field.layer.borderWidth = 1.0;
    field.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    field.leftViewMode = UITextFieldViewModeAlways;
    [field.heightAnchor constraintEqualToConstant:44.0].active = YES;
    return field;
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    configuration.baseBackgroundColor = [UIColor colorWithRed:0.22 green:0.43 blue:0.76 alpha:1.0];
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(11, 18, 11, 18);
    button.configuration = configuration;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (UIButton *)secondaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration tintedButtonConfiguration];
    configuration.title = title;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    configuration.baseBackgroundColor = [UIColor colorWithWhite:1.0 alpha:0.14];
    configuration.baseForegroundColor = UIColor.whiteColor;
    button.configuration = configuration;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)roleChanged:(UISegmentedControl *)sender {
    BOOL joining = sender.selectedSegmentIndex == SsbmPadOnlinePlayRoleJoin;
    _addressField.hidden = !joining;
    [_connectButton setTitle:(joining ? @"Join Game" : @"Host Game")
                    forState:UIControlStateNormal];
    UIButtonConfiguration *configuration = _connectButton.configuration;
    configuration.title = joining ? @"Join Game" : @"Host Game";
    _connectButton.configuration = configuration;
}

- (void)bufferModeChanged:(UISwitch *)sender {
    _bufferStepper.enabled = !sender.on;
    _bufferValueLabel.textColor = [UIColor colorWithWhite:(sender.on ? 0.50 : 0.80)
                                                    alpha:1.0];
}

- (void)bufferChanged:(UIStepper *)sender {
    _bufferValueLabel.text = [NSString stringWithFormat:@"%lu frames",
        (unsigned long)llround(sender.value)];
}

- (void)connect:(id)sender {
    (void)sender;
    [self.view endEditing:YES];
    NSString *nickname = [_nicknameField.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *portText = [_portField.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSInteger portValue = portText.integerValue;
    if (nickname.length == 0 || nickname.length > 20 || portValue < 1 || portValue > UINT16_MAX) {
        [self showError:@"Enter a nickname of 1–20 characters and a valid UDP port."];
        return;
    }
    NSUInteger frames = (NSUInteger)llround(_bufferStepper.value);
    if (_roleControl.selectedSegmentIndex == SsbmPadOnlinePlayRoleHost) {
        [self.delegate onlinePlayViewController:self requestsHostWithNickname:nickname
                                          port:(uint16_t)portValue
                               automaticBuffer:_automaticBufferSwitch.on
                                  bufferFrames:frames];
        return;
    }
    NSString *address = [_addressField.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (address.length == 0) {
        [self showError:@"Enter the host address shared by your friend."];
        return;
    }
    [self.delegate onlinePlayViewController:self requestsJoinWithNickname:nickname
                                    address:address port:(uint16_t)portValue
                            automaticBuffer:_automaticBufferSwitch.on
                               bufferFrames:frames];
}

- (void)toggleReady:(id)sender {
    (void)sender;
    _localReady = !_localReady;
    UIButtonConfiguration *configuration = _readyButton.configuration;
    configuration.title = _localReady ? @"Not Ready" : @"Ready";
    _readyButton.configuration = configuration;
    [self.delegate onlinePlayViewController:self requestsReady:_localReady];
}

- (void)start:(id)sender {
    (void)sender;
    [self.delegate onlinePlayViewControllerRequestsStart:self];
}

- (void)cancel:(id)sender {
    (void)sender;
    [self.delegate onlinePlayViewControllerRequestsCancel:self];
}

- (void)showConnectingWithMessage:(NSString *)message {
    _setupStack.hidden = YES;
    _lobbyStack.hidden = NO;
    _readyButton.hidden = YES;
    _startButton.hidden = YES;
    _stateLabel.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    _stateLabel.text = message;
}

- (void)showLobbyForRole:(SsbmPadOnlinePlayRole)role
                   players:(NSArray<NSDictionary<NSString *,id> *> *)players
              bufferFrames:(NSUInteger)bufferFrames
           automaticBuffer:(BOOL)automaticBuffer
                  canStart:(BOOL)canStart
                    status:(NSString *)status {
    _setupStack.hidden = YES;
    _lobbyStack.hidden = NO;
    _readyButton.hidden = NO;
    _startButton.hidden = role != SsbmPadOnlinePlayRoleHost;
    _startButton.enabled = canStart;
    _stateLabel.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    _stateLabel.text = status.length > 0 ? status : [NSString stringWithFormat:
        @"Input buffer: %lu frame%@%@", (unsigned long)bufferFrames,
        bufferFrames == 1 ? @"" : @"s", automaticBuffer ? @" (automatic)" : @""];

    for (UIView *view in _playersStack.arrangedSubviews) {
        [_playersStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    for (NSDictionary<NSString *, id> *player in players) {
        NSString *name = player[@"name"] ?: @"Player";
        NSNumber *ping = player[@"ping"] ?: @0;
        NSString *controller = player[@"controller"] ?: @"No controller";
        BOOL compatible = [player[@"compatible"] boolValue];
        BOOL ready = [player[@"ready"] boolValue];
        UILabel *row = [UILabel new];
        row.numberOfLines = 2;
        row.textColor = UIColor.whiteColor;
        row.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        row.text = [NSString stringWithFormat:@"%@  ·  %@ ms  ·  %@\nCompatibility: %@  ·  %@",
            name, ping, controller, compatible ? @"Match" : @"Mismatch",
            ready ? @"Ready" : @"Not ready"];
        row.accessibilityLabel = row.text;
        [_playersStack addArrangedSubview:row];
    }
}

- (void)showError:(NSString *)message {
    _stateLabel.textColor = UIColor.systemRedColor;
    _stateLabel.text = message;
    if (_setupStack.hidden) {
        _lobbyStack.hidden = NO;
        _readyButton.hidden = YES;
        _startButton.hidden = YES;
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Experimental Multiplayer"
            message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK"
            style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)resetToSetup {
    _localReady = NO;
    _setupStack.hidden = NO;
    _lobbyStack.hidden = YES;
    UIButtonConfiguration *configuration = _readyButton.configuration;
    configuration.title = @"Ready";
    _readyButton.configuration = configuration;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _nicknameField && !_addressField.hidden)
        [_addressField becomeFirstResponder];
    else if (textField == _nicknameField)
        [_portField becomeFirstResponder];
    else if (textField == _addressField)
        [_portField becomeFirstResponder];
    else
        [textField resignFirstResponder];
    return YES;
}

@end
