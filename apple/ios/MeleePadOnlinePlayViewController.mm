#import "MeleePadOnlinePlayViewController.h"
#import "MeleePadPublicLobbyClient.h"

#include <cmath>

@interface MeleePadOnlinePlayViewController () <UITextFieldDelegate>
@end

@implementation MeleePadOnlinePlayViewController {
    UISegmentedControl *_connectionControl;
    UISegmentedControl *_roleControl;
    UITextField *_nicknameField;
    UITextField *_addressField;
    UITextField *_portField;
    UILabel *_connectionHelp;
    UISwitch *_automaticBufferSwitch;
    UIStepper *_bufferStepper;
    UILabel *_bufferValueLabel;
    UIButton *_connectButton;
    UIButton *_publicHostButton;
    UIButton *_refreshButton;
    UILabel *_publicStatusLabel;
    UIStackView *_publicRoomsStack;
    UIStackView *_publicStack;
    UIStackView *_privateStack;
    UIStackView *_bufferStack;
    UILabel *_stateLabel;
    UILabel *_roomCodeLabel;
    UIStackView *_playersStack;
    UIStackView *_messagesStack;
    UIButton *_quickChatButton;
    UIButton *_readyButton;
    UIButton *_startButton;
    UIStackView *_setupStack;
    UIStackView *_lobbyStack;
    MeleePadPublicLobbyClient *_publicLobbyClient;
    BOOL _localReady;
    BOOL _publicHostPending;
    BOOL _publicAutoJoinConsumed;
    NSUInteger _lastMessageID;
    NSTimeInterval _lastMessagePoll;
    NSTimeInterval _lastHeartbeat;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Online Play";
    self.view.backgroundColor = [UIColor colorWithRed:0.035 green:0.055 blue:0.10 alpha:1.0];
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.whiteColor,
    };
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    _publicLobbyClient = [MeleePadPublicLobbyClient new];

    UILabel *intro = [UILabel new];
    intro.text = @"Play MeleePad Together";
    intro.textColor = UIColor.whiteColor;
    intro.font = [UIFont systemFontOfSize:24.0 weight:UIFontWeightBold];
    UILabel *detail = [UILabel new];
    detail.text = @"Find a compatible public game, share a private room code, or connect directly. The match still runs peer-to-peer through MeleePad's deterministic netplay.";
    detail.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    detail.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular];
    detail.numberOfLines = 0;

    _connectionControl = [[UISegmentedControl alloc]
        initWithItems:@[@"Public Games", @"Private Room", @"Direct IP"]];
    _connectionControl.selectedSegmentIndex = 0;
    _connectionControl.accessibilityLabel = @"Connection type";
    [_connectionControl addTarget:self action:@selector(connectionChanged:)
                 forControlEvents:UIControlEventValueChanged];
    _nicknameField = [self textFieldWithPlaceholder:@"Nickname"];
    _nicknameField.text = @"Player";
    _nicknameField.textContentType = UITextContentTypeNickname;
    _nicknameField.returnKeyType = UIReturnKeyDone;

    UILabel *openGamesLabel = [UILabel new];
    openGamesLabel.text = @"Open games";
    openGamesLabel.textColor = UIColor.whiteColor;
    openGamesLabel.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    _refreshButton = [self secondaryButtonWithTitle:@"Refresh" action:@selector(refreshPublicGames:)];
    _refreshButton.accessibilityIdentifier = @"public-lobby-refresh";
    UIStackView *publicHeader = [[UIStackView alloc]
        initWithArrangedSubviews:@[openGamesLabel, _refreshButton]];
    publicHeader.axis = UILayoutConstraintAxisHorizontal;
    publicHeader.alignment = UIStackViewAlignmentCenter;
    publicHeader.distribution = UIStackViewDistributionEqualSpacing;
    _publicStatusLabel = [self mutedLabel];
    _publicStatusLabel.accessibilityIdentifier = @"public-lobby-status";
    _publicRoomsStack = [UIStackView new];
    _publicRoomsStack.axis = UILayoutConstraintAxisVertical;
    _publicRoomsStack.spacing = 10.0;
    _publicHostButton = [self primaryButtonWithTitle:@"Host Public Game"
                                              action:@selector(hostPublicGame:)];
    _publicHostButton.accessibilityIdentifier = @"public-lobby-host";
    _publicStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        publicHeader, _publicStatusLabel, _publicRoomsStack, _publicHostButton,
    ]];
    _publicStack.axis = UILayoutConstraintAxisVertical;
    _publicStack.spacing = 12.0;

    _roleControl = [[UISegmentedControl alloc] initWithItems:@[@"Host", @"Join"]];
    _roleControl.selectedSegmentIndex = 0;
    _roleControl.accessibilityLabel = @"Host or join";
    [_roleControl addTarget:self action:@selector(roleChanged:)
           forControlEvents:UIControlEventValueChanged];
    _addressField = [self textFieldWithPlaceholder:@"8-character room code"];
    _addressField.keyboardType = UIKeyboardTypeURL;
    _addressField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _addressField.autocorrectionType = UITextAutocorrectionTypeNo;
    _addressField.returnKeyType = UIReturnKeyNext;
    _portField = [self textFieldWithPlaceholder:@"UDP port (default 2626)"];
    _portField.text = @"2626";
    _portField.keyboardType = UIKeyboardTypeNumberPad;
    _connectionHelp = [self mutedLabel];
    _connectButton = [self primaryButtonWithTitle:@"Host Private Room" action:@selector(connect:)];
    _privateStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        _roleControl, _addressField, _portField, _connectionHelp, _connectButton,
    ]];
    _privateStack.axis = UILayoutConstraintAxisVertical;
    _privateStack.spacing = 12.0;

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
    _bufferValueLabel.textColor = [UIColor colorWithWhite:0.50 alpha:1.0];
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
    _bufferStack = [[UIStackView alloc] initWithArrangedSubviews:@[automaticRow, bufferRow]];
    _bufferStack.axis = UILayoutConstraintAxisVertical;
    _bufferStack.spacing = 10.0;

    _setupStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        _connectionControl, _nicknameField, _publicStack, _privateStack, _bufferStack,
    ]];
    _setupStack.axis = UILayoutConstraintAxisVertical;
    _setupStack.spacing = 14.0;

    UILabel *playersTitle = [UILabel new];
    playersTitle.text = @"Players";
    playersTitle.textColor = UIColor.whiteColor;
    playersTitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    _playersStack = [UIStackView new];
    _playersStack.axis = UILayoutConstraintAxisVertical;
    _playersStack.spacing = 8.0;
    _roomCodeLabel = [UILabel new];
    _roomCodeLabel.textColor = UIColor.whiteColor;
    _roomCodeLabel.font = [UIFont monospacedSystemFontOfSize:18.0 weight:UIFontWeightSemibold];
    _roomCodeLabel.numberOfLines = 0;
    _roomCodeLabel.hidden = YES;
    _stateLabel = [self mutedLabel];
    _stateLabel.text = @"Connecting…";
    _stateLabel.accessibilityIdentifier = @"online-play-status";

    UILabel *messagesTitle = [UILabel new];
    messagesTitle.text = @"Quick chat";
    messagesTitle.textColor = UIColor.whiteColor;
    messagesTitle.font = [UIFont systemFontOfSize:18.0 weight:UIFontWeightBold];
    _messagesStack = [UIStackView new];
    _messagesStack.axis = UILayoutConstraintAxisVertical;
    _messagesStack.spacing = 6.0;
    _quickChatButton = [self secondaryButtonWithTitle:@"Send a message" action:@selector(noop:)];
    _quickChatButton.menu = [self quickChatMenu];
    _quickChatButton.showsMenuAsPrimaryAction = YES;
    UIStackView *quickChatStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[messagesTitle, _messagesStack, _quickChatButton]];
    quickChatStack.axis = UILayoutConstraintAxisVertical;
    quickChatStack.spacing = 8.0;
    quickChatStack.tag = 7001;
    quickChatStack.hidden = YES;

    _readyButton = [self secondaryButtonWithTitle:@"Ready" action:@selector(toggleReady:)];
    _startButton = [self primaryButtonWithTitle:@"Start Match" action:@selector(start:)];
    _startButton.enabled = NO;
    UIStackView *lobbyActions = [[UIStackView alloc]
        initWithArrangedSubviews:@[_readyButton, _startButton]];
    lobbyActions.axis = UILayoutConstraintAxisHorizontal;
    lobbyActions.spacing = 12.0;
    lobbyActions.distribution = UIStackViewDistributionFillEqually;
    _lobbyStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        playersTitle, _roomCodeLabel, _playersStack, _stateLabel, quickChatStack, lobbyActions,
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
    [self connectionChanged:_connectionControl];
}

- (UILabel *)mutedLabel {
    UILabel *label = [UILabel new];
    label.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    label.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightRegular];
    label.numberOfLines = 0;
    return label;
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

- (void)connectionChanged:(UISegmentedControl *)sender {
    BOOL publicGames = sender.selectedSegmentIndex == 0;
    _publicStack.hidden = !publicGames;
    _privateStack.hidden = publicGames;
    if (publicGames) {
        if (_publicLobbyClient.isAvailable)
            [self refreshPublicGames:nil];
        else {
            _publicStatusLabel.text = @"Public games are not configured in this build. Private rooms and Direct IP are available now.";
            _publicHostButton.enabled = NO;
        }
        return;
    }
    [self roleChanged:_roleControl];
}

- (void)roleChanged:(UISegmentedControl *)sender {
    BOOL joining = sender.selectedSegmentIndex == MeleePadOnlinePlayRoleJoin;
    BOOL privateRoom = _connectionControl.selectedSegmentIndex == 1;
    _addressField.hidden = !joining;
    _addressField.placeholder = privateRoom ? @"8-character room code" : @"Host IP or hostname";
    _addressField.accessibilityLabel = _addressField.placeholder;
    _portField.hidden = privateRoom;
    _connectionHelp.text = privateRoom
        ? @"Private rooms use Dolphin's public traversal service. Share the ephemeral room code only with people you trust."
        : @"Direct IP uses UDP port 2626 by default. Internet hosts may need UDP forwarding or a private VPN.";
    NSString *title = joining ? @"Join Game" : (privateRoom ? @"Host Private Room" : @"Host Direct Game");
    UIButtonConfiguration *configuration = _connectButton.configuration;
    configuration.title = title;
    _connectButton.configuration = configuration;
}

- (void)bufferModeChanged:(UISwitch *)sender {
    _bufferStepper.enabled = !sender.on;
    _bufferValueLabel.textColor = [UIColor colorWithWhite:(sender.on ? 0.50 : 0.80) alpha:1.0];
}

- (void)bufferChanged:(UIStepper *)sender {
    _bufferValueLabel.text = [NSString stringWithFormat:@"%lu frames", (unsigned long)llround(sender.value)];
}

- (NSString *)validatedNickname {
    NSString *nickname = [_nicknameField.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (nickname.length == 0 || nickname.length > 20) {
        [self showError:@"Enter a nickname of 1–20 letters, numbers, spaces, dots, dashes, or underscores."];
        return nil;
    }
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ._-"];
    if ([nickname rangeOfCharacterFromSet:allowed.invertedSet].location != NSNotFound) {
        [self showError:@"That nickname contains an unsupported character."];
        return nil;
    }
    return nickname;
}

- (NSUInteger)bufferFrames {
    return (NSUInteger)llround(_bufferStepper.value);
}

- (void)refreshPublicGames:(id)sender {
    (void)sender;
    NSString *nickname = [self validatedNickname];
    if (nickname.length == 0)
        return;
    _refreshButton.enabled = NO;
    _publicStatusLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    _publicStatusLabel.text = @"Finding compatible games…";
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    [_publicLobbyClient prepareWithNickname:nickname completion:^(NSDictionary *result, NSString *error) {
        (void)result;
        MeleePadOnlinePlayViewController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        if (error.length > 0) {
            strongSelf->_refreshButton.enabled = YES;
            strongSelf->_publicStatusLabel.textColor = UIColor.systemRedColor;
            strongSelf->_publicStatusLabel.text = error;
            return;
        }
        [strongSelf->_publicLobbyClient fetchRoomsWithCompletion:^(NSDictionary *roomsResult,
                                                                    NSString *roomsError) {
            strongSelf->_refreshButton.enabled = YES;
            if (roomsError.length > 0) {
                strongSelf->_publicStatusLabel.textColor = UIColor.systemRedColor;
                strongSelf->_publicStatusLabel.text = roomsError;
                return;
            }
            NSArray *rooms = [roomsResult[@"rooms"] isKindOfClass:NSArray.class]
                ? roomsResult[@"rooms"] : @[];
            [strongSelf renderPublicRooms:rooms];
        }];
    }];
}

- (void)renderPublicRooms:(NSArray<NSDictionary<NSString *, id> *> *)rooms {
    for (UIView *view in _publicRoomsStack.arrangedSubviews) {
        [_publicRoomsStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    _publicStatusLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    _publicStatusLabel.text = rooms.count == 0
        ? @"No open games yet. Start one and it will appear here for compatible players."
        : [NSString stringWithFormat:@"%lu open game%@ · room codes stay private until Join",
            (unsigned long)rooms.count, rooms.count == 1 ? @"" : @"s"];
    for (NSDictionary<NSString *, id> *room in rooms)
        [_publicRoomsStack addArrangedSubview:[self cardForRoom:room]];

    if (!_publicAutoJoinConsumed &&
        [NSProcessInfo.processInfo.environment[@"MELEEPAD_PUBLIC_LOBBY_AUTO_JOIN_FIRST"]
            isEqualToString:@"1"]) {
        for (NSDictionary *room in rooms) {
            if ([room[@"compatible"] boolValue] && [room[@"state"] isEqual:@"waiting"]) {
                _publicAutoJoinConsumed = YES;
                [self joinPublicRoom:room];
                break;
            }
        }
    }
}

- (UIView *)cardForRoom:(NSDictionary<NSString *, id> *)room {
    NSString *host = [room[@"host"] isKindOfClass:NSString.class] ? room[@"host"] : @"Player";
    BOOL compatible = [room[@"compatible"] boolValue];
    BOOL waiting = [room[@"state"] isEqual:@"waiting"];
    NSInteger players = [room[@"players"] integerValue];
    NSInteger capacity = [room[@"capacity"] integerValue];
    UILabel *hostLabel = [UILabel new];
    hostLabel.text = host;
    hostLabel.textColor = UIColor.whiteColor;
    hostLabel.font = [UIFont systemFontOfSize:16.0 weight:UIFontWeightSemibold];
    UILabel *badge = [UILabel new];
    badge.text = compatible ? @"  Compatible  " : @"  Version mismatch  ";
    badge.textColor = compatible ? UIColor.systemGreenColor : UIColor.systemOrangeColor;
    badge.backgroundColor = [badge.textColor colorWithAlphaComponent:0.12];
    badge.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    badge.layer.cornerRadius = 8.0;
    badge.clipsToBounds = YES;
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[hostLabel, badge]];
    header.axis = UILayoutConstraintAxisHorizontal;
    header.distribution = UIStackViewDistributionEqualSpacing;
    header.alignment = UIStackViewAlignmentCenter;
    UILabel *metadata = [self mutedLabel];
    NSString *state = waiting ? @"Waiting" : @"In match";
    metadata.text = [NSString stringWithFormat:@"%@ · %ld/%ld · %@\nMeleePad %@ (%@) · %@ %@",
        room[@"region"] ?: @"auto", (long)players, (long)capacity, state,
        room[@"app_version"] ?: @"?", room[@"build"] ?: @"?",
        room[@"game_id"] ?: @"?", room[@"game_revision"] ?: @"?"];

    UIButton *join = [self primaryButtonWithTitle:@"Join" action:@selector(noop:)];
    join.enabled = compatible && waiting && players < capacity;
    join.accessibilityIdentifier = [NSString stringWithFormat:@"join-public-room-%@", room[@"room_id"] ?: @""];
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    [join addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
        (void)action;
        [weakSelf joinPublicRoom:room];
    }] forControlEvents:UIControlEventTouchUpInside];
    UIButton *more = [self secondaryButtonWithTitle:@"More" action:@selector(noop:)];
    more.menu = [self moderationMenuForRoom:room];
    more.showsMenuAsPrimaryAction = YES;
    UIStackView *actions = [[UIStackView alloc] initWithArrangedSubviews:@[more, join]];
    actions.axis = UILayoutConstraintAxisHorizontal;
    actions.spacing = 8.0;
    actions.distribution = UIStackViewDistributionFillEqually;
    UIStackView *card = [[UIStackView alloc] initWithArrangedSubviews:@[header, metadata, actions]];
    card.axis = UILayoutConstraintAxisVertical;
    card.spacing = 10.0;
    card.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
    card.layoutMarginsRelativeArrangement = YES;
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    card.layer.cornerRadius = 14.0;
    return card;
}

- (UIMenu *)moderationMenuForRoom:(NSDictionary<NSString *, id> *)room {
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    UIAction *hide = [UIAction actionWithTitle:@"Hide Player"
        image:[UIImage systemImageNamed:@"eye.slash"] identifier:nil
        handler:^(__kindof UIAction *action) { (void)action; [weakSelf hidePublicRoom:room]; }];
    UIAction *offensive = [UIAction actionWithTitle:@"Report Offensive Name"
        image:[UIImage systemImageNamed:@"exclamationmark.bubble"]
        identifier:nil handler:^(__kindof UIAction *action) {
        (void)action; [weakSelf reportPublicRoom:room reason:@"offensive_name"];
    }];
    offensive.attributes = UIMenuElementAttributesDestructive;
    UIAction *spam = [UIAction actionWithTitle:@"Report Spam"
        image:[UIImage systemImageNamed:@"exclamationmark.triangle"]
        identifier:nil handler:^(__kindof UIAction *action) {
        (void)action; [weakSelf reportPublicRoom:room reason:@"spam"];
    }];
    spam.attributes = UIMenuElementAttributesDestructive;
    return [UIMenu menuWithTitle:@"Safety" children:@[hide, offensive, spam]];
}

- (void)hidePublicRoom:(NSDictionary<NSString *, id> *)room {
    [_publicLobbyClient hideSessionID:room[@"host_id"] completion:^(NSDictionary *result, NSString *error) {
        (void)result;
        if (error.length > 0) [self showError:error]; else [self refreshPublicGames:nil];
    }];
}

- (void)reportPublicRoom:(NSDictionary<NSString *, id> *)room reason:(NSString *)reason {
    [_publicLobbyClient reportSessionID:room[@"host_id"] roomID:room[@"room_id"] reason:reason
        completion:^(NSDictionary *result, NSString *error) {
        (void)result;
        if (error.length > 0) [self showError:error]; else [self refreshPublicGames:nil];
    }];
}

- (void)hostPublicGame:(id)sender {
    (void)sender;
    NSString *nickname = [self validatedNickname];
    if (nickname.length == 0) return;
    _publicHostButton.enabled = NO;
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    [_publicLobbyClient prepareWithNickname:nickname completion:^(NSDictionary *result, NSString *error) {
        (void)result;
        MeleePadOnlinePlayViewController *strongSelf = weakSelf;
        strongSelf->_publicHostButton.enabled = YES;
        if (error.length > 0) { [strongSelf showError:error]; return; }
        strongSelf->_publicHostPending = YES;
        [strongSelf showConnectingWithMessage:@"Opening a traversal room…"];
        [strongSelf.delegate onlinePlayViewController:strongSelf
                              requestsHostWithNickname:nickname port:2626 internetRoom:YES
                               automaticBuffer:strongSelf->_automaticBufferSwitch.on
                                  bufferFrames:[strongSelf bufferFrames]];
    }];
}

- (void)joinPublicRoom:(NSDictionary<NSString *, id> *)room {
    NSString *roomID = room[@"room_id"];
    if (roomID.length == 0) return;
    _publicStatusLabel.text = [NSString stringWithFormat:@"Joining %@…", room[@"host"] ?: @"game"];
    [_publicLobbyClient joinRoomID:roomID completion:^(NSDictionary *result, NSString *error) {
        if (error.length > 0) {
            self->_publicStatusLabel.textColor = UIColor.systemRedColor;
            self->_publicStatusLabel.text = error;
            return;
        }
        NSString *code = result[@"traversal_code"];
        if (code.length != 8) {
            self->_publicStatusLabel.text = @"The lobby did not return a valid room code.";
            return;
        }
        [self showConnectingWithMessage:@"Connecting to the public game…"];
        [self.delegate onlinePlayViewController:self requestsJoinWithNickname:[self validatedNickname]
                                        address:code.lowercaseString port:2626 internetRoom:YES
                                automaticBuffer:self->_automaticBufferSwitch.on
                                   bufferFrames:[self bufferFrames]];
    }];
}

- (void)connect:(id)sender {
    (void)sender;
    [self.view endEditing:YES];
    NSString *nickname = [self validatedNickname];
    if (nickname.length == 0) return;
    BOOL internetRoom = _connectionControl.selectedSegmentIndex == 1;
    NSInteger portValue = internetRoom ? 2626 : _portField.text.integerValue;
    if (!internetRoom && (portValue < 1 || portValue > UINT16_MAX)) {
        [self showError:@"Enter a valid UDP port."];
        return;
    }
    if (_roleControl.selectedSegmentIndex == MeleePadOnlinePlayRoleHost) {
        [self.delegate onlinePlayViewController:self requestsHostWithNickname:nickname
            port:(uint16_t)portValue internetRoom:internetRoom
            automaticBuffer:_automaticBufferSwitch.on bufferFrames:[self bufferFrames]];
        return;
    }
    NSString *address = [_addressField.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (internetRoom) address = address.lowercaseString;
    if (address.length == 0) {
        [self showError:internetRoom ? @"Enter the eight-character room code shared by the host."
                                      : @"Enter the host address shared by your friend."];
        return;
    }
    NSCharacterSet *nonHex = [[NSCharacterSet characterSetWithCharactersInString:@"0123456789abcdef"] invertedSet];
    if (internetRoom && (address.length != 8 ||
        [address rangeOfCharacterFromSet:nonHex].location != NSNotFound)) {
        [self showError:@"Room codes contain exactly eight hexadecimal characters."];
        return;
    }
    [self.delegate onlinePlayViewController:self requestsJoinWithNickname:nickname
        address:address port:(uint16_t)portValue internetRoom:internetRoom
        automaticBuffer:_automaticBufferSwitch.on bufferFrames:[self bufferFrames]];
}

- (UIMenu *)quickChatMenu {
    NSArray<NSArray<NSString *> *> *messages = @[
        @[@"Hello!", @"hello"], @[@"Ready when you are.", @"ready"],
        @[@"One moment, please.", @"moment"], @[@"Good luck—have fun!", @"good_luck"],
        @[@"Good games!", @"good_games"], @[@"Rematch?", @"rematch"],
    ];
    NSMutableArray<UIAction *> *actions = [NSMutableArray array];
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    for (NSArray<NSString *> *message in messages) {
        [actions addObject:[UIAction actionWithTitle:message[0] image:nil identifier:nil
            handler:^(__kindof UIAction *action) {
            (void)action; [weakSelf sendQuickMessage:message[1]];
        }]];
    }
    return [UIMenu menuWithTitle:@"Preset messages" children:actions];
}

- (void)sendQuickMessage:(NSString *)kind {
    [_publicLobbyClient sendQuickMessage:kind completion:^(NSDictionary *result, NSString *error) {
        (void)result;
        if (error.length > 0) self->_stateLabel.text = error;
        else [self pollPublicMessagesIfNeeded:YES];
    }];
}

- (void)pollPublicMessagesIfNeeded:(BOOL)force {
    if (_publicLobbyClient.activeRoomID.length == 0) return;
    NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate;
    if (!force && now - _lastMessagePoll < 2.0) return;
    _lastMessagePoll = now;
    [_publicLobbyClient fetchMessagesAfter:_lastMessageID completion:^(NSDictionary *result, NSString *error) {
        if (error.length > 0) return;
        NSArray *messages = [result[@"messages"] isKindOfClass:NSArray.class] ? result[@"messages"] : @[];
        for (NSDictionary *message in messages) {
            self->_lastMessageID = MAX(self->_lastMessageID, [message[@"id"] unsignedIntegerValue]);
            UILabel *row = [self mutedLabel];
            row.textColor = UIColor.whiteColor;
            row.text = [NSString stringWithFormat:@"%@: %@", message[@"sender"] ?: @"Player",
                message[@"text"] ?: @""];
            [self->_messagesStack addArrangedSubview:row];
            while (self->_messagesStack.arrangedSubviews.count > 6) {
                UIView *oldest = self->_messagesStack.arrangedSubviews.firstObject;
                [self->_messagesStack removeArrangedSubview:oldest];
                [oldest removeFromSuperview];
            }
        }
    }];
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
    [_publicLobbyClient heartbeatInGame:YES completion:nil];
    [self.delegate onlinePlayViewControllerRequestsStart:self];
}

- (void)cancel:(id)sender {
    (void)sender;
    [self closePublicPresence];
    [self.delegate onlinePlayViewControllerRequestsCancel:self];
}

- (void)closePublicPresence {
    _publicHostPending = NO;
    if (_publicLobbyClient.activeRoomID.length == 0) return;
    [_publicLobbyClient closeHostedRoomWithCompletion:nil];
    [_publicLobbyClient leaveActiveRoomWithCompletion:nil];
}

- (void)noop:(id)sender { (void)sender; }

- (void)showConnectingWithMessage:(NSString *)message {
    _setupStack.hidden = YES;
    _lobbyStack.hidden = NO;
    _readyButton.hidden = YES;
    _startButton.hidden = YES;
    _roomCodeLabel.hidden = YES;
    _roomCodeLabel.text = @"";
    _stateLabel.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    _stateLabel.text = message;
}

- (void)showLobbyForRole:(MeleePadOnlinePlayRole)role
                 players:(NSArray<NSDictionary<NSString *,id> *> *)players
            bufferFrames:(NSUInteger)bufferFrames
         automaticBuffer:(BOOL)automaticBuffer
                canStart:(BOOL)canStart
                roomCode:(NSString *)roomCode
                  status:(NSString *)status {
    _setupStack.hidden = YES;
    _lobbyStack.hidden = NO;
    _readyButton.hidden = NO;
    _startButton.hidden = role != MeleePadOnlinePlayRoleHost;
    _startButton.enabled = canStart;
    BOOL publicRoom = _publicLobbyClient.activeRoomID.length > 0 || _publicHostPending;
    _roomCodeLabel.hidden = publicRoom || roomCode.length == 0;
    _roomCodeLabel.text = (!publicRoom && roomCode.length > 0)
        ? [NSString stringWithFormat:@"Room code: %@", roomCode] : @"";
    _stateLabel.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    _stateLabel.text = status.length > 0 ? status : [NSString stringWithFormat:
        @"Input buffer: %lu frame%@%@", (unsigned long)bufferFrames,
        bufferFrames == 1 ? @"" : @"s", automaticBuffer ? @" (automatic)" : @""];
    for (UIView *view in _playersStack.arrangedSubviews) {
        [_playersStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    for (NSDictionary<NSString *, id> *player in players) {
        UILabel *row = [UILabel new];
        row.numberOfLines = 2;
        row.textColor = UIColor.whiteColor;
        row.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightSemibold];
        row.text = [NSString stringWithFormat:@"%@  ·  %@ ms  ·  %@\nCompatibility: %@  ·  %@",
            player[@"name"] ?: @"Player", player[@"ping"] ?: @0,
            player[@"controller"] ?: @"No controller",
            [player[@"compatible"] boolValue] ? @"Match" : @"Mismatch",
            [player[@"ready"] boolValue] ? @"Ready" : @"Not ready"];
        row.accessibilityLabel = row.text;
        [_playersStack addArrangedSubview:row];
    }
    UIStackView *quickChatStack = (UIStackView *)[_lobbyStack viewWithTag:7001];
    quickChatStack.hidden = !publicRoom;
    if (_publicHostPending && roomCode.length == 8) {
        _publicHostPending = NO;
        [_publicLobbyClient publishRoomWithTraversalCode:roomCode region:@"auto"
            completion:^(NSDictionary *result, NSString *error) {
            (void)result;
            if (error.length > 0) {
                self->_stateLabel.textColor = UIColor.systemRedColor;
                self->_stateLabel.text = [NSString stringWithFormat:
                    @"Connected privately, but public listing failed: %@", error];
                return;
            }
            self->_stateLabel.text = @"Public game listed. Waiting for a compatible player…";
            self->_lastHeartbeat = NSDate.timeIntervalSinceReferenceDate;
            [self pollPublicMessagesIfNeeded:YES];
        }];
    }
    if (_publicLobbyClient.activeRoomID.length > 0) {
        NSTimeInterval now = NSDate.timeIntervalSinceReferenceDate;
        if (now - _lastHeartbeat >= 15.0) {
            _lastHeartbeat = now;
            [_publicLobbyClient heartbeatInGame:NO completion:nil];
        }
        [self pollPublicMessagesIfNeeded:NO];
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
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Online Play"
            message:message preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }
}

- (void)resetToSetup {
    [self closePublicPresence];
    _localReady = NO;
    _lastMessageID = 0;
    _lastMessagePoll = 0;
    _lastHeartbeat = 0;
    _setupStack.hidden = NO;
    _lobbyStack.hidden = YES;
    UIButtonConfiguration *configuration = _readyButton.configuration;
    configuration.title = @"Ready";
    _readyButton.configuration = configuration;
    [self connectionChanged:_connectionControl];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _addressField && !_portField.hidden) [_portField becomeFirstResponder];
    else [textField resignFirstResponder];
    return YES;
}

@end
