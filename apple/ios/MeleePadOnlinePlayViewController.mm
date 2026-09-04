#import "MeleePadOnlinePlayViewController.h"
#import "MeleePadDiagnostics.h"
#import "MeleePadPublicLobbyClient.h"

#import <QuartzCore/QuartzCore.h>

#include <cmath>

static UIFont *MeleePadScaledFont(UIFontTextStyle style, UIFontWeight weight) {
    UIFontDescriptor *descriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:style];
    UIFont *base = [UIFont systemFontOfSize:descriptor.pointSize weight:weight];
    return [[UIFontMetrics metricsForTextStyle:style] scaledFontForFont:base];
}

static void MeleePadStyleLabel(UILabel *label, UIFontTextStyle style, UIFontWeight weight) {
    label.font = MeleePadScaledFont(style, weight);
    label.adjustsFontForContentSizeCategory = YES;
}

static void MeleePadStyleSegmentedControl(UISegmentedControl *control) {
    UIFont *font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleFootnote]
        scaledFontForFont:[UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium]
        maximumPointSize:17.0];
    control.selectedSegmentTintColor = UIColor.whiteColor;
    [control setTitleTextAttributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.82 alpha:1.0],
        NSFontAttributeName: font,
    } forState:UIControlStateNormal];
    [control setTitleTextAttributes:@{
        NSForegroundColorAttributeName: [UIColor colorWithWhite:0.08 alpha:1.0],
        NSFontAttributeName: font,
    } forState:UIControlStateSelected];
    [control.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;
}

static UIColor *MeleePadOnlineAccentColor(void) {
    return [UIColor colorWithRed:0.20 green:0.72 blue:0.96 alpha:1.0];
}

static UIColor *MeleePadOnlineActionColor(void) {
    return [UIColor colorWithRed:0.16 green:0.46 blue:0.96 alpha:1.0];
}

static UIColor *MeleePadSeatColor(NSUInteger index) {
    NSArray<UIColor *> *colors = @[
        [UIColor colorWithRed:0.18 green:0.55 blue:0.98 alpha:1.0],
        [UIColor colorWithRed:0.96 green:0.29 blue:0.35 alpha:1.0],
        [UIColor colorWithRed:0.95 green:0.55 blue:0.13 alpha:1.0],
        [UIColor colorWithRed:0.23 green:0.75 blue:0.48 alpha:1.0],
    ];
    return colors[index % colors.count];
}

@interface MeleePadOnlinePlayViewController () <UITextFieldDelegate>
- (BOOL)renderPublicRooms:(NSArray<NSDictionary<NSString *, id> *> *)rooms;
- (void)renderCrossGameActivity:(NSArray<NSDictionary<NSString *, id> *> *)products;
- (void)reportSessionID:(NSString *)sessionID
                    room:(NSDictionary<NSString *, id> *)room
                  reason:(NSString *)reason;
@end

@implementation MeleePadOnlinePlayViewController {
    UISegmentedControl *_connectionControl;
    UISegmentedControl *_roleControl;
    UISegmentedControl *_capacityControl;
    UITextField *_nicknameField;
    UIButton *_confirmNameButton;
    UILabel *_nameStatusLabel;
    UITextField *_addressField;
    UITextField *_portField;
    UILabel *_connectionHelp;
    UISwitch *_automaticBufferSwitch;
    UIStepper *_bufferStepper;
    UILabel *_bufferValueLabel;
    UIButton *_connectButton;
    UIButton *_connectionFAQButton;
    UIButton *_advancedButton;
    UIButton *_publicHostButton;
    UIButton *_refreshButton;
    UIButton *_privateFallbackButton;
    UILabel *_publicStatusLabel;
    UIStackView *_publicRoomsStack;
    UIStackView *_crossGameStack;
    UIStackView *_crossGameRowsStack;
    UIStackView *_publicStack;
    UIStackView *_publicAvailableStack;
    UIStackView *_publicUnavailableStack;
    UIStackView *_privateStack;
    UIStackView *_bufferStack;
    UILabel *_stateLabel;
    UILabel *_roomCodeLabel;
    UIStackView *_playersStack;
    UIStackView *_messagesStack;
    UILabel *_chatEmptyLabel;
    UITextField *_chatField;
    UILabel *_chatCountLabel;
    UIButton *_sendChatButton;
    UIButton *_readyButton;
    UIButton *_startButton;
    UIButton *_leaveSessionButton;
    UIStackView *_setupStack;
    UIStackView *_lobbyStack;
    UIStackView *_educationStack;
    UIButton *_educationButton;
    NSTimer *_publicRefreshTimer;
    MeleePadPublicLobbyClient *_publicLobbyClient;
    BOOL _localReady;
    BOOL _publicHostPending;
    BOOL _publicAutoJoinConsumed;
    BOOL _advancedExpanded;
    BOOL _usesPublicChat;
    NSUInteger _lastMessageID;
    NSUInteger _lastPeerMessageID;
    NSTimeInterval _lastMessagePoll;
    NSTimeInterval _lastHeartbeat;
    NSUInteger _roomCapacity;
    NSString *_confirmedNickname;
    NSString *_lastLobbyDiagnosticSignature;
    NSString *_lastPublicRoomsSignature;
    UIStackView *_heroStack;
    UIStackView *_heroKickerRow;
    UILabel *_heroTitleLabel;
    UILabel *_heroDetailLabel;
    UIImageView *_heroWatermark;
    CAGradientLayer *_backgroundGradient;
    CAGradientLayer *_heroGradient;
}

- (instancetype)init {
    return [self initWithPublicLobbyClient:[MeleePadPublicLobbyClient new]];
}

- (instancetype)initWithPublicLobbyClient:(MeleePadPublicLobbyClient *)client {
    self = [super initWithNibName:nil bundle:nil];
    if (self != nil)
        _publicLobbyClient = client;
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"Online Play";
    self.view.backgroundColor = [UIColor colorWithRed:0.035 green:0.055 blue:0.10 alpha:1.0];
    _backgroundGradient = [CAGradientLayer layer];
    _backgroundGradient.colors = @[
        (id)[UIColor colorWithRed:0.030 green:0.060 blue:0.14 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.075 green:0.045 blue:0.18 alpha:1.0].CGColor,
        (id)[UIColor colorWithRed:0.020 green:0.030 blue:0.070 alpha:1.0].CGColor,
    ];
    _backgroundGradient.locations = @[@0.0, @0.48, @1.0];
    _backgroundGradient.startPoint = CGPointMake(0.0, 0.0);
    _backgroundGradient.endPoint = CGPointMake(1.0, 1.0);
    [self.view.layer insertSublayer:_backgroundGradient atIndex:0];
    self.navigationController.navigationBar.tintColor = UIColor.whiteColor;
    self.navigationController.navigationBar.titleTextAttributes = @{
        NSForegroundColorAttributeName: UIColor.whiteColor,
    };
    UINavigationBarAppearance *appearance = [UINavigationBarAppearance new];
    [appearance configureWithOpaqueBackground];
    appearance.backgroundColor = self.view.backgroundColor;
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName: UIColor.whiteColor};
    self.navigationController.navigationBar.standardAppearance = appearance;
    self.navigationController.navigationBar.scrollEdgeAppearance = appearance;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(cancel:)];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithImage:[UIImage systemImageNamed:@"questionmark.circle"]
        style:UIBarButtonItemStylePlain target:self action:@selector(showOnlinePlayHelp:)];
    self.navigationItem.rightBarButtonItem.accessibilityLabel = @"How Online Play works";
    if (_publicLobbyClient == nil)
        _publicLobbyClient = [MeleePadPublicLobbyClient new];

    UILabel *kicker = [UILabel new];
    kicker.text = @"MELEE ONLINE  ·  2–4 PLAYERS";
    kicker.textColor = MeleePadOnlineAccentColor();
    kicker.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleCaption1]
        scaledFontForFont:[UIFont systemFontOfSize:12.0 weight:UIFontWeightBold]
        maximumPointSize:18.0];
    kicker.adjustsFontForContentSizeCategory = YES;
    UIImageView *heroIcon = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:@"gamecontroller.fill"]];
    heroIcon.tintColor = MeleePadOnlineAccentColor();
    [heroIcon.widthAnchor constraintEqualToConstant:24.0].active = YES;
    [heroIcon.heightAnchor constraintEqualToConstant:24.0].active = YES;
    NSMutableArray<UIView *> *seatDots = [NSMutableArray arrayWithCapacity:4];
    for (NSUInteger index = 0; index < 4; ++index) {
        UIView *dot = [UIView new];
        dot.backgroundColor = MeleePadSeatColor(index);
        dot.layer.cornerRadius = 4.0;
        [dot.widthAnchor constraintEqualToConstant:8.0].active = YES;
        [dot.heightAnchor constraintEqualToConstant:8.0].active = YES;
        [seatDots addObject:dot];
    }
    UIStackView *seatPalette = [[UIStackView alloc] initWithArrangedSubviews:seatDots];
    seatPalette.axis = UILayoutConstraintAxisHorizontal;
    seatPalette.alignment = UIStackViewAlignmentCenter;
    seatPalette.spacing = 5.0;
    seatPalette.accessibilityElementsHidden = YES;
    UIView *heroSpacer = [UIView new];
    _heroKickerRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[heroIcon, kicker, heroSpacer, seatPalette]];
    _heroKickerRow.axis = UILayoutConstraintAxisHorizontal;
    _heroKickerRow.alignment = UIStackViewAlignmentCenter;
    _heroKickerRow.spacing = 8.0;
    _heroTitleLabel = [UILabel new];
    _heroTitleLabel.text = @"Play Melee Together";
    _heroTitleLabel.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(_heroTitleLabel, UIFontTextStyleLargeTitle, UIFontWeightBold);
    _heroTitleLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleLargeTitle]
        scaledFontForFont:[UIFont systemFontOfSize:34.0 weight:UIFontWeightBold]
        maximumPointSize:38.0];
    _heroTitleLabel.numberOfLines = 0;
    _heroDetailLabel = [UILabel new];
    _heroDetailLabel.text = @"Find a room or invite friends. Check the build, ready up, and play.";
    _heroDetailLabel.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    MeleePadStyleLabel(_heroDetailLabel, UIFontTextStyleBody, UIFontWeightRegular);
    _heroDetailLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody]
        scaledFontForFont:[UIFont systemFontOfSize:17.0 weight:UIFontWeightRegular]
        maximumPointSize:24.0];
    _heroDetailLabel.numberOfLines = 0;
    _heroStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[_heroKickerRow, _heroTitleLabel, _heroDetailLabel]];
    _heroStack.axis = UILayoutConstraintAxisVertical;
    _heroStack.spacing = 8.0;
    _heroStack.layoutMargins = UIEdgeInsetsMake(20, 20, 20, 20);
    _heroStack.layoutMarginsRelativeArrangement = YES;
    _heroStack.layer.cornerRadius = 18.0;
    _heroStack.layer.borderWidth = 1.0;
    _heroStack.layer.borderColor = [MeleePadOnlineAccentColor() colorWithAlphaComponent:0.42].CGColor;
    _heroStack.clipsToBounds = YES;
    _heroGradient = [CAGradientLayer layer];
    _heroGradient.colors = @[
        (id)[UIColor colorWithRed:0.03 green:0.38 blue:0.66 alpha:0.94].CGColor,
        (id)[UIColor colorWithRed:0.10 green:0.25 blue:0.58 alpha:0.94].CGColor,
        (id)[UIColor colorWithRed:0.31 green:0.10 blue:0.54 alpha:0.96].CGColor,
    ];
    _heroGradient.locations = @[@0.0, @0.55, @1.0];
    _heroGradient.startPoint = CGPointMake(0.0, 0.0);
    _heroGradient.endPoint = CGPointMake(1.0, 1.0);
    [_heroStack.layer insertSublayer:_heroGradient atIndex:0];
    _heroWatermark = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:@"gamecontroller.fill"]];
    _heroWatermark.tintColor = [UIColor colorWithWhite:1.0 alpha:0.14];
    _heroWatermark.contentMode = UIViewContentModeScaleAspectFit;
    _heroWatermark.isAccessibilityElement = NO;
    _heroWatermark.translatesAutoresizingMaskIntoConstraints = NO;
    [_heroStack insertSubview:_heroWatermark atIndex:0];
    [NSLayoutConstraint activateConstraints:@[
        [_heroWatermark.trailingAnchor constraintEqualToAnchor:_heroStack.trailingAnchor constant:-22.0],
        [_heroWatermark.centerYAnchor constraintEqualToAnchor:_heroStack.centerYAnchor],
        [_heroWatermark.widthAnchor constraintEqualToConstant:132.0],
        [_heroWatermark.heightAnchor constraintEqualToConstant:92.0],
    ]];

    _connectionControl = [[UISegmentedControl alloc]
        initWithItems:@[@"Public Games", @"Private Room", @"Direct IP"]];
    _connectionControl.selectedSegmentIndex = 0;
    _connectionControl.accessibilityLabel = @"Connection type";
    _connectionControl.accessibilityHint = @"Choose public discovery, a private room code, or an advanced direct address.";
    MeleePadStyleSegmentedControl(_connectionControl);
    [_connectionControl addTarget:self action:@selector(connectionChanged:)
                 forControlEvents:UIControlEventValueChanged];
    _nicknameField = [self textFieldWithPlaceholder:@"Nickname"];
    NSString *savedNickname = [NSUserDefaults.standardUserDefaults
        stringForKey:@"MeleePadOnlineNickname"];
    _nicknameField.text = savedNickname.length > 0 ? savedNickname : @"Player";
    _confirmedNickname = savedNickname.length > 0 ? [savedNickname copy] : nil;
    _nicknameField.textContentType = UITextContentTypeNickname;
    _nicknameField.returnKeyType = UIReturnKeyDone;
    [_nicknameField addTarget:self action:@selector(nicknameChanged:)
             forControlEvents:UIControlEventEditingChanged];
    UILabel *nameLabel = [UILabel new];
    nameLabel.text = @"Your player name";
    nameLabel.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(nameLabel, UIFontTextStyleHeadline, UIFontWeightSemibold);
    _confirmNameButton = [self secondaryButtonWithTitle:@"Confirm Name"
                                                 action:@selector(confirmNickname:)];
    _confirmNameButton.hidden = _confirmedNickname.length > 0;
    _confirmNameButton.accessibilityIdentifier = @"online-player-name-confirm";
    [_confirmNameButton setContentHuggingPriority:UILayoutPriorityRequired
                                          forAxis:UILayoutConstraintAxisHorizontal];
    UIStackView *nameEntry = [[UIStackView alloc]
        initWithArrangedSubviews:@[_nicknameField, _confirmNameButton]];
    nameEntry.axis = UILayoutConstraintAxisHorizontal;
    nameEntry.alignment = UIStackViewAlignmentFill;
    nameEntry.spacing = 10.0;
    _nameStatusLabel = [self mutedLabel];
    _nameStatusLabel.text = _confirmedNickname.length > 0
        ? [NSString stringWithFormat:@"Playing as %@", _confirmedNickname]
        : @"Confirm this name before you connect.";
    _nameStatusLabel.textColor = _confirmedNickname.length > 0
        ? UIColor.systemGreenColor : UIColor.systemOrangeColor;
    _nameStatusLabel.accessibilityIdentifier = @"online-player-name-status";
    UILabel *nameHelp = [self mutedLabel];
    nameHelp.text = @"Other players see this name. It stays on this device and out of diagnostics.";
    UIStackView *identityStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[nameLabel, nameEntry, _nameStatusLabel, nameHelp]];
    identityStack.axis = UILayoutConstraintAxisVertical;
    identityStack.spacing = 7.0;

    _educationButton = [self secondaryButtonWithTitle:@"How does Online Play work?"
                                              action:@selector(toggleEducation:)];
    _educationButton.accessibilityHint = @"Expands a three-step introduction.";
    _educationStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        [self educationRowWithSymbol:@"point.3.connected.trianglepath.dotted" title:@"1. Choose a connection"
            detail:@"Browse public games, share a private code, or use Direct IP on a trusted network."],
        [self educationRowWithSymbol:@"person.3.fill" title:@"2. Check the room"
            detail:@"Make sure the build matches and use room chat to coordinate."],
        [self educationRowWithSymbol:@"checkmark.circle.fill" title:@"3. Ready up"
            detail:@"Each player marks Ready. The host starts when everyone is set."],
    ]];
    _educationStack.axis = UILayoutConstraintAxisVertical;
    _educationStack.spacing = 8.0;
    _educationStack.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
    _educationStack.layoutMarginsRelativeArrangement = YES;
    _educationStack.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.06];
    _educationStack.layer.cornerRadius = 14.0;
    _educationStack.hidden = YES;

    UILabel *openGamesLabel = [UILabel new];
    openGamesLabel.text = @"Open games";
    openGamesLabel.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(openGamesLabel, UIFontTextStyleTitle2, UIFontWeightBold);
    _refreshButton = [self secondaryButtonWithTitle:@"Refresh" action:@selector(refreshPublicGames:)];
    _refreshButton.accessibilityIdentifier = @"public-lobby-refresh";
    _refreshButton.accessibilityHint = @"Updates public games now. The list also refreshes automatically.";
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

    UILabel *crossGameTitle = [UILabel new];
    crossGameTitle.text = @"Across Pad games";
    crossGameTitle.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(crossGameTitle, UIFontTextStyleHeadline, UIFontWeightBold);
    UILabel *crossGameHelp = [self mutedLabel];
    crossGameHelp.text = @"See where people are playing. Other games stay separate and cannot be joined from MeleePad.";
    _crossGameRowsStack = [UIStackView new];
    _crossGameRowsStack.axis = UILayoutConstraintAxisVertical;
    _crossGameRowsStack.spacing = 8.0;
    _crossGameStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        crossGameTitle, crossGameHelp, _crossGameRowsStack,
    ]];
    _crossGameStack.axis = UILayoutConstraintAxisVertical;
    _crossGameStack.spacing = 7.0;
    _crossGameStack.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
    _crossGameStack.layoutMarginsRelativeArrangement = YES;
    _crossGameStack.backgroundColor = [UIColor colorWithRed:0.22 green:0.12 blue:0.42 alpha:0.42];
    _crossGameStack.layer.cornerRadius = 14.0;
    _crossGameStack.layer.borderWidth = 1.0;
    _crossGameStack.layer.borderColor = [UIColor colorWithRed:0.62 green:0.38 blue:1.0 alpha:0.28].CGColor;
    _crossGameStack.hidden = YES;

    UILabel *roomSizeLabel = [UILabel new];
    roomSizeLabel.text = @"Room size";
    roomSizeLabel.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(roomSizeLabel, UIFontTextStyleHeadline, UIFontWeightSemibold);
    _capacityControl = [[UISegmentedControl alloc] initWithItems:@[@"2", @"3", @"4"]];
    _capacityControl.selectedSegmentIndex = 0;
    _capacityControl.accessibilityLabel = @"Room size";
    _capacityControl.accessibilityHint = @"Sets how many seats must fill before a public host can start.";
    MeleePadStyleSegmentedControl(_capacityControl);
    NSLayoutConstraint *capacityWidth = [_capacityControl.widthAnchor
        constraintGreaterThanOrEqualToConstant:160.0];
    capacityWidth.priority = UILayoutPriorityDefaultHigh;
    capacityWidth.active = YES;
    UIButton *roomSizeInfo = [self infoButtonWithAccessibilityLabel:@"About room size"
                                                            action:@selector(showRoomSizeHelp:)];
    UIStackView *roomSizeTitle = [[UIStackView alloc]
        initWithArrangedSubviews:@[roomSizeLabel, roomSizeInfo]];
    roomSizeTitle.axis = UILayoutConstraintAxisHorizontal;
    roomSizeTitle.alignment = UIStackViewAlignmentCenter;
    roomSizeTitle.spacing = 2.0;
    UIStackView *roomSizeRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[roomSizeTitle, _capacityControl]];
    roomSizeRow.axis = UILayoutConstraintAxisHorizontal;
    roomSizeRow.alignment = UIStackViewAlignmentCenter;
    roomSizeRow.distribution = UIStackViewDistributionEqualSpacing;
    roomSizeRow.spacing = 16.0;

    _publicHostButton = [self primaryButtonWithTitle:@"Create Public Game"
                                              action:@selector(hostPublicGame:)];
    _publicHostButton.accessibilityIdentifier = @"public-lobby-host";
    _privateFallbackButton = [self secondaryButtonWithTitle:@"Use Private Room"
                                                    action:@selector(showPrivateRoom:)];
    _privateFallbackButton.hidden = YES;
    UILabel *publicSafety = [self mutedLabel];
    publicSafety.text = @"Preview feature · Gameplay connects directly and is not encrypted.";
    publicSafety.textColor = UIColor.systemOrangeColor;
    UILabel *hostPublicLabel = [UILabel new];
    hostPublicLabel.text = @"Host a public game";
    hostPublicLabel.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(hostPublicLabel, UIFontTextStyleTitle3, UIFontWeightBold);
    UILabel *hostPublicHelp = [self mutedLabel];
    hostPublicHelp.text = @"Choose 2, 3, or 4 players. Compatible players can join without seeing the connection code.";
    UIStackView *hostPublicStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        hostPublicLabel, hostPublicHelp, roomSizeRow, publicSafety, _publicHostButton,
    ]];
    hostPublicStack.axis = UILayoutConstraintAxisVertical;
    hostPublicStack.spacing = 10.0;
    hostPublicStack.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
    hostPublicStack.layoutMarginsRelativeArrangement = YES;
    hostPublicStack.backgroundColor = [MeleePadOnlineAccentColor() colorWithAlphaComponent:0.07];
    hostPublicStack.layer.cornerRadius = 14.0;
    hostPublicStack.layer.borderWidth = 1.0;
    hostPublicStack.layer.borderColor = [MeleePadOnlineAccentColor() colorWithAlphaComponent:0.16].CGColor;
    _publicAvailableStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        publicHeader, _publicStatusLabel, _publicRoomsStack, _crossGameStack, hostPublicStack,
        _privateFallbackButton,
    ]];
    _publicAvailableStack.axis = UILayoutConstraintAxisVertical;
    _publicAvailableStack.spacing = 12.0;

    UIImageView *offlineIcon = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:@"lock.shield.fill"]];
    offlineIcon.tintColor = UIColor.systemOrangeColor;
    offlineIcon.contentMode = UIViewContentModeCenter;
    [offlineIcon.widthAnchor constraintEqualToConstant:28.0].active = YES;
    [offlineIcon.heightAnchor constraintEqualToConstant:28.0].active = YES;
    UILabel *offlineKicker = [UILabel new];
    offlineKicker.text = @"PUBLIC GAMES OFFLINE";
    offlineKicker.textColor = UIColor.systemOrangeColor;
    MeleePadStyleLabel(offlineKicker, UIFontTextStyleCaption1, UIFontWeightBold);
    UIStackView *offlineStatus = [[UIStackView alloc]
        initWithArrangedSubviews:@[offlineIcon, offlineKicker]];
    offlineStatus.axis = UILayoutConstraintAxisHorizontal;
    offlineStatus.alignment = UIStackViewAlignmentCenter;
    offlineStatus.spacing = 7.0;
    offlineStatus.isAccessibilityElement = YES;
    offlineStatus.accessibilityLabel = @"Public Games offline";

    UILabel *offlineTitle = [UILabel new];
    offlineTitle.text = @"Public Games needs a secure lobby service";
    offlineTitle.textColor = UIColor.whiteColor;
    offlineTitle.numberOfLines = 0;
    MeleePadStyleLabel(offlineTitle, UIFontTextStyleTitle2, UIFontWeightBold);
    UILabel *offlineDetail = [self mutedLabel];
    offlineDetail.text = @"This build has no MeleePad service for listing rooms, protecting room codes, limiting abuse, and receiving reports. Browsing and hosting stay off until that service is deployed over HTTPS.";
    UIView *lobbySafety = [self educationRowWithSymbol:@"checkmark.shield.fill"
        title:@"The lobby will use HTTPS"
        detail:@"Names, room listings, chat, and hidden connection codes will travel through the secured lobby service."];
    UIView *gameplaySafety = [self educationRowWithSymbol:@"network"
        title:@"Gameplay is still peer to peer"
        detail:@"The match does not pass through the lobby and is not encrypted. Play only with people you trust."];
    UILabel *offlineFallback = [self mutedLabel];
    offlineFallback.text = @"Want to play now? Private Room works without the public list. Create a code and share it directly with friends.";
    offlineFallback.textColor = [UIColor colorWithWhite:0.84 alpha:1.0];
    UIButton *usePrivateNow = [self primaryButtonWithTitle:@"Use Private Room"
                                                   action:@selector(showPrivateRoom:)];
    usePrivateNow.accessibilityIdentifier = @"public-lobby-use-private";
    UIButton *publicFAQ = [self secondaryButtonWithTitle:@"Public Games FAQ"
                                                  action:@selector(showPublicGamesAvailabilityHelp:)];
    publicFAQ.accessibilityIdentifier = @"public-lobby-availability-help";
    UIStackView *offlineActions = [[UIStackView alloc]
        initWithArrangedSubviews:@[usePrivateNow, publicFAQ]];
    offlineActions.axis = UILayoutConstraintAxisHorizontal;
    offlineActions.distribution = UIStackViewDistributionFillEqually;
    offlineActions.spacing = 10.0;
    _publicUnavailableStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        offlineStatus, offlineTitle, offlineDetail, lobbySafety, gameplaySafety,
        offlineFallback, offlineActions,
    ]];
    _publicUnavailableStack.axis = UILayoutConstraintAxisVertical;
    _publicUnavailableStack.spacing = 12.0;
    _publicUnavailableStack.layoutMargins = UIEdgeInsetsMake(18, 18, 18, 18);
    _publicUnavailableStack.layoutMarginsRelativeArrangement = YES;
    _publicUnavailableStack.backgroundColor = [UIColor colorWithRed:0.035 green:0.085 blue:0.17 alpha:0.96];
    _publicUnavailableStack.layer.cornerRadius = 16.0;
    _publicUnavailableStack.layer.borderWidth = 1.0;
    _publicUnavailableStack.layer.borderColor = [MeleePadOnlineAccentColor() colorWithAlphaComponent:0.30].CGColor;
    _publicUnavailableStack.accessibilityIdentifier = @"public-lobby-unavailable";

    _publicStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        _publicAvailableStack, _publicUnavailableStack,
    ]];
    _publicStack.axis = UILayoutConstraintAxisVertical;
    _publicStack.spacing = 12.0;

    _roleControl = [[UISegmentedControl alloc] initWithItems:@[@"Host", @"Join"]];
    _roleControl.selectedSegmentIndex = 0;
    _roleControl.accessibilityLabel = @"Host or join";
    MeleePadStyleSegmentedControl(_roleControl);
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
    _connectionFAQButton = [self secondaryButtonWithTitle:@"Private Room FAQ"
                                                   action:@selector(showConnectionModeHelp:)];
    _connectionFAQButton.accessibilityIdentifier = @"online-connection-faq";
    _privateStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        _roleControl, _addressField, _portField, _connectionHelp,
        _connectionFAQButton, _connectButton,
    ]];
    _privateStack.axis = UILayoutConstraintAxisVertical;
    _privateStack.spacing = 12.0;

    UILabel *automaticLabel = [UILabel new];
    automaticLabel.text = @"Automatic input buffer";
    automaticLabel.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(automaticLabel, UIFontTextStyleBody, UIFontWeightMedium);
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
    _bufferValueLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleBody]
        scaledFontForFont:[UIFont monospacedDigitSystemFontOfSize:14.0
                                                          weight:UIFontWeightRegular]];
    _bufferValueLabel.adjustsFontForContentSizeCategory = YES;
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
    _bufferStack.hidden = YES;
    _advancedButton = [self secondaryButtonWithTitle:@"Advanced settings"
                                             action:@selector(toggleAdvanced:)];
    _advancedButton.hidden = YES;

    _setupStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        _connectionControl, _educationButton, _educationStack, identityStack,
        _publicStack, _privateStack,
        _advancedButton, _bufferStack,
    ]];
    _setupStack.axis = UILayoutConstraintAxisVertical;
    _setupStack.spacing = 14.0;

    UILabel *playersTitle = [UILabel new];
    playersTitle.text = @"Players";
    playersTitle.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(playersTitle, UIFontTextStyleTitle2, UIFontWeightBold);
    _playersStack = [UIStackView new];
    _playersStack.axis = UILayoutConstraintAxisVertical;
    _playersStack.spacing = 8.0;
    _roomCodeLabel = [UILabel new];
    _roomCodeLabel.textColor = UIColor.whiteColor;
    _roomCodeLabel.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleTitle3]
        scaledFontForFont:[UIFont monospacedSystemFontOfSize:18.0
                                                     weight:UIFontWeightSemibold]];
    _roomCodeLabel.adjustsFontForContentSizeCategory = YES;
    _roomCodeLabel.numberOfLines = 0;
    _roomCodeLabel.hidden = YES;
    _stateLabel = [self mutedLabel];
    _stateLabel.text = @"Connecting…";
    _stateLabel.accessibilityIdentifier = @"online-play-status";

    UILabel *messagesTitle = [UILabel new];
    messagesTitle.text = @"Room chat";
    messagesTitle.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(messagesTitle, UIFontTextStyleTitle3, UIFontWeightBold);
    UILabel *messagesHelp = [self mutedLabel];
    messagesHelp.text = @"Messages are temporary and stay out of diagnostics. Private Room and Direct IP chat uses the same unencrypted peer connection as gameplay.";
    _messagesStack = [UIStackView new];
    _messagesStack.axis = UILayoutConstraintAxisVertical;
    _messagesStack.spacing = 6.0;
    _chatEmptyLabel = [self mutedLabel];
    _chatEmptyLabel.text = @"No messages yet.";
    _chatEmptyLabel.accessibilityIdentifier = @"room-chat-empty";
    [_messagesStack addArrangedSubview:_chatEmptyLabel];
    _chatField = [self textFieldWithPlaceholder:@"Message the room"];
    _chatField.returnKeyType = UIReturnKeySend;
    _chatField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
    _chatField.autocorrectionType = UITextAutocorrectionTypeYes;
    _chatField.accessibilityHint = @"Messages can be up to 160 characters.";
    [_chatField addTarget:self action:@selector(chatTextChanged:)
          forControlEvents:UIControlEventEditingChanged];
    _sendChatButton = [self primaryButtonWithTitle:@"Send" action:@selector(sendChatMessage:)];
    _sendChatButton.enabled = NO;
    _sendChatButton.accessibilityIdentifier = @"room-chat-send";
    [_sendChatButton setContentHuggingPriority:UILayoutPriorityRequired
                                       forAxis:UILayoutConstraintAxisHorizontal];
    UIStackView *chatComposer = [[UIStackView alloc]
        initWithArrangedSubviews:@[_chatField, _sendChatButton]];
    chatComposer.axis = UILayoutConstraintAxisHorizontal;
    chatComposer.alignment = UIStackViewAlignmentFill;
    chatComposer.spacing = 10.0;
    _chatCountLabel = [self mutedLabel];
    _chatCountLabel.text = @"0 / 160";
    _chatCountLabel.textAlignment = NSTextAlignmentRight;
    _chatCountLabel.textColor = [UIColor colorWithWhite:0.58 alpha:1.0];
    MeleePadStyleLabel(_chatCountLabel, UIFontTextStyleCaption2, UIFontWeightMedium);
    _chatCountLabel.accessibilityLabel = @"0 of 160 characters";
    UIStackView *chatStack = [[UIStackView alloc]
        initWithArrangedSubviews:@[
            messagesTitle, messagesHelp, _messagesStack, chatComposer, _chatCountLabel,
        ]];
    chatStack.axis = UILayoutConstraintAxisVertical;
    chatStack.spacing = 8.0;
    chatStack.tag = 7001;
    chatStack.hidden = YES;

    _readyButton = [self primaryButtonWithTitle:@"Ready" action:@selector(toggleReady:)];
    _startButton = [self primaryButtonWithTitle:@"Start Match" action:@selector(start:)];
    _startButton.enabled = NO;
    _leaveSessionButton = [self secondaryButtonWithTitle:@"Leave Session"
                                                  action:@selector(cancel:)];
    _leaveSessionButton.hidden = YES;
    UIStackView *lobbyActions = [[UIStackView alloc]
        initWithArrangedSubviews:@[_readyButton, _startButton, _leaveSessionButton]];
    lobbyActions.axis = UILayoutConstraintAxisHorizontal;
    lobbyActions.spacing = 12.0;
    lobbyActions.distribution = UIStackViewDistributionFillEqually;
    _lobbyStack = [[UIStackView alloc] initWithArrangedSubviews:@[
        playersTitle, _roomCodeLabel, _playersStack, _stateLabel, chatStack, lobbyActions,
    ]];
    _lobbyStack.axis = UILayoutConstraintAxisVertical;
    _lobbyStack.spacing = 12.0;
    _lobbyStack.hidden = YES;

    UIStackView *content = [[UIStackView alloc]
        initWithArrangedSubviews:@[_heroStack, _setupStack, _lobbyStack]];
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
        [content.widthAnchor constraintLessThanOrEqualToConstant:760.0],
        [content.centerXAnchor constraintEqualToAnchor:frame.centerXAnchor],
    ]];
    _roomCapacity = 2;
    MeleePadLog(@"online ui event=open public_lobby=%@",
        _publicLobbyClient.isAvailable ? @"available" : @"unavailable");
    [self connectionChanged:_connectionControl];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (_publicRefreshTimer == nil) {
        _publicRefreshTimer = [NSTimer timerWithTimeInterval:10.0 target:self
            selector:@selector(refreshPublicGamesAutomatically:)
            userInfo:nil repeats:YES];
        [NSRunLoop.mainRunLoop addTimer:_publicRefreshTimer forMode:NSRunLoopCommonModes];
    }
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    _backgroundGradient.frame = self.view.bounds;
    _heroGradient.frame = _heroStack.bounds;
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [_publicRefreshTimer invalidate];
    _publicRefreshTimer = nil;
}

- (UILabel *)mutedLabel {
    UILabel *label = [UILabel new];
    label.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    MeleePadStyleLabel(label, UIFontTextStyleFootnote, UIFontWeightRegular);
    label.numberOfLines = 0;
    return label;
}

- (UIView *)educationRowWithSymbol:(NSString *)symbolName
                              title:(NSString *)title
                             detail:(NSString *)detail {
    UIImageView *icon = [[UIImageView alloc]
        initWithImage:[UIImage systemImageNamed:symbolName]];
    icon.tintColor = MeleePadOnlineAccentColor();
    icon.contentMode = UIViewContentModeCenter;
    [icon.widthAnchor constraintEqualToConstant:30.0].active = YES;
    [icon.heightAnchor constraintEqualToConstant:30.0].active = YES;
    UILabel *titleLabel = [UILabel new];
    titleLabel.text = title;
    titleLabel.textColor = UIColor.whiteColor;
    titleLabel.numberOfLines = 0;
    MeleePadStyleLabel(titleLabel, UIFontTextStyleSubheadline, UIFontWeightSemibold);
    UILabel *detailLabel = [self mutedLabel];
    detailLabel.text = detail;
    UIStackView *copy = [[UIStackView alloc]
        initWithArrangedSubviews:@[titleLabel, detailLabel]];
    copy.axis = UILayoutConstraintAxisVertical;
    copy.spacing = 2.0;
    UIStackView *row = [[UIStackView alloc]
        initWithArrangedSubviews:@[icon, copy]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentTop;
    row.spacing = 10.0;
    row.isAccessibilityElement = YES;
    row.accessibilityLabel = [NSString stringWithFormat:@"%@. %@", title, detail];
    return row;
}

- (UIButton *)infoButtonWithAccessibilityLabel:(NSString *)label action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration plainButtonConfiguration];
    configuration.image = [UIImage systemImageNamed:@"info.circle"];
    configuration.baseForegroundColor = MeleePadOnlineAccentColor();
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(10, 10, 10, 10);
    button.configuration = configuration;
    button.accessibilityLabel = label;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    [button.widthAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;
    [button.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;
    return button;
}

- (void)toggleEducation:(id)sender {
    (void)sender;
    _educationStack.hidden = !_educationStack.hidden;
    UIButtonConfiguration *configuration = _educationButton.configuration;
    configuration.title = _educationStack.hidden ? @"How does Online Play work?"
                                                  : @"Hide Online Play guide";
    _educationButton.configuration = configuration;
    _educationButton.accessibilityHint = _educationStack.hidden
        ? @"Expands a three-step introduction." : @"Collapses the three-step introduction.";
    MeleePadLog(@"online education event=%@",
        _educationStack.hidden ? @"collapsed" : @"expanded");
}

- (void)showOnlinePlayHelp:(id)sender {
    (void)sender;
    MeleePadLog(@"online education event=help-opened");
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Online Play FAQ"
        message:@"Choose the topic you need. Public Games is the easiest option when available. Private Room is best for friends. Direct IP is an advanced fallback."
        preferredStyle:UIAlertControllerStyleAlert];
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Public Games"
        style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        (void)action;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showHelpTopic:@"Public Games"
                message:@"Public Games needs a MeleePad-operated HTTPS lobby service. That service lists rooms, keeps connection codes hidden until a compatible player joins, limits requests, carries room chat, and accepts reports. This build has no production service address, so browsing and hosting are deliberately off. When enabled, lobby traffic uses HTTPS, but the match still connects peer to peer and gameplay is not encrypted."];
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Private Room"
        style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        (void)action;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showHelpTopic:@"Private Room"
                message:@"Use this with people you trust. The host creates an eight-character room code and shares it privately. The code helps Dolphin connect the devices. It is not a password or encryption key. Keep MeleePad open while connecting."];
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Direct IP"
        style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        (void)action;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showHelpTopic:@"Direct IP Setup"
                message:@"Use Direct IP only on a trusted network or private VPN. The host keeps UDP port 2626 and shares a reachable IP address or hostname. A local-network game normally needs no router change. Internet hosting may require UDP port forwarding. There is no relay fallback. If it fails, check the address, port, firewall, MeleePad build, and supported game revision. Direct IP exposes the host address and gameplay is not encrypted."];
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Player Names & Room Chat"
        style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        (void)action;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showHelpTopic:@"Player Names & Room Chat"
                message:@"Confirm the name other players will see before browsing or connecting. Room chat lets current members type messages up to 160 characters and disappears when the room closes. Public Game chat travels through the lobby service. Private Room and Direct IP chat travels through the same unencrypted peer connection as gameplay. Hide and Report are available only in Public Games."];
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Safety & Troubleshooting"
        style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        (void)action;
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf showHelpTopic:@"Safety & Troubleshooting"
                message:@"Public Games lets you hide or report a player. Private Room and Direct IP are for people you already trust. Make sure everyone uses the same MeleePad build and supported GALE01 revision, keeps the app open, and marks Ready. Connection quality appears after joining. Some routers cannot connect because MeleePad has no relay fallback. Diagnostics exclude names, chat, addresses, room codes, and tokens."];
        });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Close"
        style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showPublicGamesAvailabilityHelp:(id)sender {
    (void)sender;
    MeleePadLog(@"online education event=public-availability-help-opened");
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Why Public Games Is Off"
        message:@"Public Games cannot safely be a list stored inside the app. It needs an online MeleePad service to publish and expire rooms, protect connection codes, limit spam, carry chat, and receive reports. No production service is configured in this build, so MeleePad fails closed instead of sending player data to an unknown or insecure server.\n\nWhen the service launches, lobby traffic will require HTTPS. Gameplay will still connect directly between players and will not be encrypted. Names are display names, not verified accounts."
        preferredStyle:UIAlertControllerStyleAlert];
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    [alert addAction:[UIAlertAction actionWithTitle:@"Use Private Room"
        style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        (void)action;
        dispatch_async(dispatch_get_main_queue(), ^{ [weakSelf showPrivateRoom:nil]; });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done"
        style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showHelpTopic:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
        message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Back to FAQ"
        style:UIAlertActionStyleDefault handler:^(__kindof UIAlertAction *action) {
        (void)action;
        dispatch_async(dispatch_get_main_queue(), ^{ [self showOnlinePlayHelp:nil]; });
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Done"
        style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)showRoomSizeHelp:(id)sender {
    (void)sender;
    MeleePadLog(@"online education event=room-size-help-opened");
    UIAlertController *alert = [UIAlertController
        alertControllerWithTitle:@"Room Size"
        message:@"Choose how many total players this game is waiting for. A public host can start only after every selected seat is filled. Each device currently contributes one local player."
        preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"Got It"
        style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (UITextField *)textFieldWithPlaceholder:(NSString *)placeholder {
    UITextField *field = [UITextField new];
    field.placeholder = placeholder;
    field.attributedPlaceholder = [[NSAttributedString alloc]
        initWithString:placeholder attributes:@{
            NSForegroundColorAttributeName: [UIColor colorWithWhite:0.62 alpha:1.0],
        }];
    field.accessibilityLabel = placeholder;
    field.delegate = self;
    field.textColor = UIColor.whiteColor;
    field.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    field.adjustsFontForContentSizeCategory = YES;
    field.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.10];
    field.layer.cornerRadius = 10.0;
    field.layer.borderWidth = 1.0;
    field.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
    field.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 12, 1)];
    field.leftViewMode = UITextFieldViewModeAlways;
    [field.heightAnchor constraintGreaterThanOrEqualToConstant:44.0].active = YES;
    return field;
}

- (UIButton *)primaryButtonWithTitle:(NSString *)title action:(SEL)action {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeSystem];
    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    configuration.baseBackgroundColor = MeleePadOnlineActionColor();
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
    configuration.contentInsets = NSDirectionalEdgeInsetsMake(11, 16, 11, 16);
    button.configuration = configuration;
    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)connectionChanged:(UISegmentedControl *)sender {
    BOOL publicGames = sender.selectedSegmentIndex == 0;
    NSString *mode = publicGames ? @"public"
        : (sender.selectedSegmentIndex == 1 ? @"private" : @"direct");
    MeleePadLog(@"online ui event=mode-selected mode=%@", mode);
    _publicStack.hidden = !publicGames;
    _privateStack.hidden = publicGames;
    _advancedButton.hidden = publicGames;
    _bufferStack.hidden = publicGames || !_advancedExpanded;
    if (publicGames) {
        BOOL publicAvailable = _publicLobbyClient.isAvailable;
        _publicAvailableStack.hidden = !publicAvailable;
        _publicUnavailableStack.hidden = publicAvailable;
        if (publicAvailable) {
            BOOL nameConfirmed = [self isNicknameConfirmed];
            _publicHostButton.enabled = nameConfirmed;
            _refreshButton.enabled = nameConfirmed;
            _capacityControl.enabled = YES;
            _privateFallbackButton.hidden = YES;
            if (nameConfirmed) {
                [self refreshPublicGames:nil];
            } else {
                _publicStatusLabel.textColor = UIColor.systemOrangeColor;
                _publicStatusLabel.text = @"Confirm your player name to browse or create public games.";
            }
        } else {
            _publicStatusLabel.textColor = UIColor.systemOrangeColor;
            _publicStatusLabel.text = @"Public Games is offline until a production HTTPS lobby service is configured.";
            _publicHostButton.enabled = NO;
            _refreshButton.enabled = NO;
            _capacityControl.enabled = NO;
            _privateFallbackButton.hidden = YES;
        }
        return;
    }
    [self roleChanged:_roleControl];
}

- (void)toggleAdvanced:(id)sender {
    (void)sender;
    _advancedExpanded = !_advancedExpanded;
    _bufferStack.hidden = !_advancedExpanded;
    UIButtonConfiguration *configuration = _advancedButton.configuration;
    configuration.title = _advancedExpanded ? @"Hide advanced settings" : @"Advanced settings";
    _advancedButton.configuration = configuration;
}

- (void)showPrivateRoom:(id)sender {
    (void)sender;
    _connectionControl.selectedSegmentIndex = 1;
    [self connectionChanged:_connectionControl];
}

- (void)showConnectionModeHelp:(id)sender {
    (void)sender;
    BOOL privateRoom = _connectionControl.selectedSegmentIndex == 1;
    if (privateRoom) {
        [self showHelpTopic:@"Private Room"
            message:@"Use this with people you trust. The host creates an eight-character room code and shares it privately. The code helps Dolphin connect the devices. It is not a password or encryption key. Both players need the same MeleePad build and supported game revision, and should keep the app open while connecting."];
    } else {
        [self showHelpTopic:@"Direct IP Setup"
            message:@"Use Direct IP only on a trusted network or private VPN. The host keeps UDP port 2626 and shares a reachable IP address or hostname. A local-network game normally needs no router change. Internet hosting may require UDP port forwarding. There is no relay fallback. If it fails, check the address, port, firewall, MeleePad build, and supported game revision. Direct IP exposes the host address and gameplay is not encrypted."];
    }
}

- (void)roleChanged:(UISegmentedControl *)sender {
    BOOL joining = sender.selectedSegmentIndex == MeleePadOnlinePlayRoleJoin;
    BOOL privateRoom = _connectionControl.selectedSegmentIndex == 1;
    _addressField.hidden = !joining;
    _addressField.placeholder = privateRoom ? @"8-character room code" : @"Host IP or hostname";
    _addressField.accessibilityLabel = _addressField.placeholder;
    _portField.hidden = privateRoom;
    _connectionHelp.text = privateRoom
        ? @"Private rooms use Dolphin's public traversal service. Room codes are locators, not passwords. Matches are not encrypted, so share codes only with people you trust."
        : @"Direct IP is not encrypted and exposes the host address. Internet hosts may also need UDP forwarding or a trusted private VPN.";
    UIButtonConfiguration *helpConfiguration = _connectionFAQButton.configuration;
    helpConfiguration.title = privateRoom ? @"Private Room FAQ"
        : @"Direct IP setup & troubleshooting";
    helpConfiguration.image = [UIImage systemImageNamed:@"questionmark.circle"];
    helpConfiguration.imagePadding = 7.0;
    _connectionFAQButton.configuration = helpConfiguration;
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

- (void)nicknameChanged:(UITextField *)sender {
    NSString *nickname = [sender.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    BOOL confirmed = _confirmedNickname.length > 0 &&
        [_confirmedNickname isEqualToString:nickname];
    _confirmNameButton.hidden = confirmed;
    UIButtonConfiguration *configuration = _confirmNameButton.configuration;
    configuration.title = @"Confirm Name";
    configuration.image = nil;
    _confirmNameButton.configuration = configuration;
    if (_connectionControl.selectedSegmentIndex == 0 && _publicLobbyClient.isAvailable) {
        _publicHostButton.enabled = confirmed;
        _refreshButton.enabled = confirmed;
    }
    _nameStatusLabel.textColor = confirmed ? UIColor.systemGreenColor : UIColor.systemOrangeColor;
    _nameStatusLabel.text = confirmed
        ? [NSString stringWithFormat:@"Playing as %@", _confirmedNickname]
        : @"Name changed. Confirm it to update your public name.";
}

- (void)confirmNickname:(id)sender {
    (void)sender;
    [self.view endEditing:YES];
    NSString *nickname = [self validatedNickname];
    if (nickname.length == 0)
        return;
    _nicknameField.text = nickname;
    _confirmedNickname = [nickname copy];
    [NSUserDefaults.standardUserDefaults setObject:nickname forKey:@"MeleePadOnlineNickname"];
    [self nicknameChanged:_nicknameField];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
        @"Player name confirmed");
    MeleePadLog(@"online ui event=player-name-confirmed");
    if (_connectionControl.selectedSegmentIndex == 0 && _publicLobbyClient.isAvailable) {
        _publicHostButton.enabled = YES;
        [self refreshPublicGames:nil];
    }
}

- (NSString *)confirmedNickname {
    NSString *nickname = [self validatedNickname];
    if (nickname.length == 0)
        return nil;
    if (_confirmedNickname.length == 0 || ![_confirmedNickname isEqualToString:nickname]) {
        [self showError:@"Confirm your player name before browsing, joining, or hosting."];
        return nil;
    }
    return nickname;
}

- (BOOL)isNicknameConfirmed {
    NSString *nickname = [_nicknameField.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    return _confirmedNickname.length > 0 && [_confirmedNickname isEqualToString:nickname];
}

- (void)refreshPublicGamesAutomatically:(NSTimer *)timer {
    (void)timer;
    if (_connectionControl.selectedSegmentIndex != 0 || _setupStack.hidden ||
        !_refreshButton.enabled || _nicknameField.isFirstResponder)
        return;
    NSString *nickname = [_nicknameField.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (nickname.length == 0 || nickname.length > 20 ||
        ![_confirmedNickname isEqualToString:nickname])
        return;
    NSCharacterSet *allowed = [NSCharacterSet characterSetWithCharactersInString:
        @"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ._-"];
    if ([nickname rangeOfCharacterFromSet:allowed.invertedSet].location != NSNotFound)
        return;
    [self refreshPublicGames:timer];
}

- (NSUInteger)bufferFrames {
    return (NSUInteger)llround(_bufferStepper.value);
}

- (void)refreshPublicGames:(id)sender {
    BOOL automaticRefresh = [sender isKindOfClass:NSTimer.class];
    NSString *nickname = [self confirmedNickname];
    if (nickname.length == 0)
        return;
    _refreshButton.enabled = NO;
    _privateFallbackButton.hidden = YES;
    _publicStatusLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    _publicStatusLabel.text = @"Finding compatible games…";
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    [_publicLobbyClient prepareWithNickname:nickname completion:^(NSDictionary *result, NSString *error) {
        (void)result;
        MeleePadOnlinePlayViewController *strongSelf = weakSelf;
        if (strongSelf == nil)
            return;
        if (error.length > 0) {
            MeleePadLog(@"online ui event=public-refresh result=session-error");
            strongSelf->_refreshButton.enabled = [strongSelf isNicknameConfirmed];
            strongSelf->_privateFallbackButton.hidden = NO;
            strongSelf->_publicStatusLabel.textColor = UIColor.systemRedColor;
            strongSelf->_publicStatusLabel.text = error;
            UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, error);
            return;
        }
        [strongSelf->_publicLobbyClient fetchRoomsWithCompletion:^(NSDictionary *roomsResult,
                                                                    NSString *roomsError) {
            strongSelf->_refreshButton.enabled = [strongSelf isNicknameConfirmed];
            if (roomsError.length > 0) {
                MeleePadLog(@"online ui event=public-refresh result=list-error");
                strongSelf->_privateFallbackButton.hidden = NO;
                strongSelf->_publicStatusLabel.textColor = UIColor.systemRedColor;
                strongSelf->_publicStatusLabel.text = roomsError;
                UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                                roomsError);
                return;
            }
            NSArray *rooms = [roomsResult[@"rooms"] isKindOfClass:NSArray.class]
                ? roomsResult[@"rooms"] : @[];
            NSUInteger compatibleCount = 0;
            for (NSDictionary *room in rooms)
                compatibleCount += [room[@"compatible"] boolValue] ? 1 : 0;
            strongSelf->_privateFallbackButton.hidden = YES;
            BOOL contentChanged = [strongSelf renderPublicRooms:rooms];
            if (!automaticRefresh || contentChanged) {
                MeleePadLog(@"online ui event=public-refresh result=success rooms=%lu compatible=%lu changed=%@",
                    (unsigned long)rooms.count, (unsigned long)compatibleCount,
                    contentChanged ? @"yes" : @"no");
            }
            [strongSelf->_publicLobbyClient fetchActivityWithCompletion:^(
                NSDictionary *activityResult, NSString *activityError) {
                if (activityError.length > 0) {
                    [strongSelf renderCrossGameActivity:@[]];
                    return;
                }
                NSArray *products = [activityResult[@"products"] isKindOfClass:NSArray.class]
                    ? activityResult[@"products"] : @[];
                [strongSelf renderCrossGameActivity:products];
            }];
        }];
    }];
}

- (void)renderCrossGameActivity:(NSArray<NSDictionary<NSString *, id> *> *)products {
    for (UIView *view in _crossGameRowsStack.arrangedSubviews) {
        [_crossGameRowsStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    for (NSDictionary<NSString *, id> *product in products) {
        if ([product[@"product_id"] isEqual:MeleePadPublicLobbyProductID])
            continue;
        NSInteger openRooms = MAX(0, [product[@"open_rooms"] integerValue]);
        NSInteger inGameRooms = MAX(0, [product[@"in_game_rooms"] integerValue]);
        NSInteger players = MAX(0, [product[@"players"] integerValue]);
        if (openRooms == 0 && inGameRooms == 0 && players == 0)
            continue;
        NSString *name = [product[@"display_name"] isKindOfClass:NSString.class]
            ? product[@"display_name"] : @"Another Pad game";
        UILabel *row = [self mutedLabel];
        row.textColor = [UIColor colorWithWhite:0.90 alpha:1.0];
        row.text = [NSString stringWithFormat:
            @"%@ · %ld room%@ open · %ld in progress · %ld player%@",
            name, (long)openRooms, openRooms == 1 ? @"" : @"s",
            (long)inGameRooms, (long)players,
            players == 1 ? @"" : @"s"];
        row.isAccessibilityElement = YES;
        [_crossGameRowsStack addArrangedSubview:row];
    }
    _crossGameStack.hidden = _crossGameRowsStack.arrangedSubviews.count == 0;
}

- (BOOL)renderPublicRooms:(NSArray<NSDictionary<NSString *, id> *> *)rooms {
    NSMutableArray<NSString *> *roomParts = [NSMutableArray arrayWithCapacity:rooms.count];
    for (NSDictionary<NSString *, id> *room in rooms) {
        NSArray<NSDictionary<NSString *, id> *> *roster =
            [room[@"roster"] isKindOfClass:NSArray.class] ? room[@"roster"] : @[];
        NSMutableArray<NSString *> *rosterIDs = [NSMutableArray arrayWithCapacity:roster.count];
        for (NSDictionary<NSString *, id> *player in roster)
            [rosterIDs addObject:player[@"session_id"] ?: @""];
        [roomParts addObject:[NSString stringWithFormat:@"%@:%@:%@:%@:%@:%@:%@:%@:%@",
            room[@"room_id"] ?: @"", room[@"players"] ?: @0, room[@"capacity"] ?: @0,
            room[@"state"] ?: @"", room[@"compatible"] ?: @NO,
            room[@"joinable"] ?: @NO, room[@"region"] ?: @"",
            room[@"build"] ?: @"", [rosterIDs componentsJoinedByString:@","]]];
    }
    [roomParts addObject:_publicLobbyClient.localSessionID ?: @""];
    NSString *signature = [roomParts componentsJoinedByString:@"|"];
    BOOL contentChanged = ![_lastPublicRoomsSignature isEqualToString:signature];
    _lastPublicRoomsSignature = signature;
    NSUInteger joinableCount = 0;
    for (NSDictionary<NSString *, id> *room in rooms)
        joinableCount += [room[@"joinable"] boolValue] ? 1 : 0;
    _publicStatusLabel.textColor = [UIColor colorWithWhite:0.72 alpha:1.0];
    _publicStatusLabel.text = rooms.count == 0
        ? @"No open games yet. Start one and it will appear here for compatible players."
        : [NSString stringWithFormat:@"%lu open game%@ · %lu joinable · refreshed now",
            (unsigned long)rooms.count, rooms.count == 1 ? @"" : @"s",
            (unsigned long)joinableCount];
    if (!contentChanged)
        return NO;
    for (UIView *view in _publicRoomsStack.arrangedSubviews) {
        [_publicRoomsStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    for (NSDictionary<NSString *, id> *room in rooms)
        [_publicRoomsStack addArrangedSubview:[self cardForRoom:room]];
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification,
                                    _publicStatusLabel.text);

    if (!_publicAutoJoinConsumed &&
        [NSProcessInfo.processInfo.environment[@"MELEEPAD_PUBLIC_LOBBY_AUTO_JOIN_FIRST"]
            isEqualToString:@"1"]) {
        for (NSDictionary *room in rooms) {
            if ([room[@"joinable"] boolValue]) {
                _publicAutoJoinConsumed = YES;
                [self joinPublicRoom:room];
                break;
            }
        }
    }
    return YES;
}

- (NSString *)displayNameForRegion:(NSString *)region {
    NSDictionary<NSString *, NSString *> *names = @{
        @"auto": @"Automatic region", @"north-america": @"North America",
        @"europe": @"Europe", @"asia": @"Asia", @"oceania": @"Oceania",
        @"south-america": @"South America", @"other": @"Other region",
    };
    return names[region] ?: @"Automatic region";
}

- (UIView *)cardForRoom:(NSDictionary<NSString *, id> *)room {
    NSString *host = [room[@"host"] isKindOfClass:NSString.class] ? room[@"host"] : @"Player";
    BOOL compatible = [room[@"compatible"] boolValue];
    BOOL waiting = [room[@"state"] isEqual:@"waiting"];
    NSInteger players = [room[@"players"] integerValue];
    NSInteger capacity = [room[@"capacity"] integerValue];
    BOOL joinable = room[@"joinable"] != nil ? [room[@"joinable"] boolValue]
        : compatible && waiting && players < capacity;
    UILabel *hostLabel = [UILabel new];
    hostLabel.text = [NSString stringWithFormat:@"%@’s game", host];
    hostLabel.textColor = UIColor.whiteColor;
    MeleePadStyleLabel(hostLabel, UIFontTextStyleHeadline, UIFontWeightSemibold);
    hostLabel.numberOfLines = 0;
    UILabel *badge = [UILabel new];
    NSString *badgeText = joinable ? @"Joinable" : (!compatible ? @"Update needed"
        : (!waiting ? @"In match" : @"Full"));
    badge.text = [NSString stringWithFormat:@"  %@  ", badgeText];
    badge.textColor = joinable ? UIColor.systemGreenColor
        : (!compatible ? UIColor.systemOrangeColor
        : (!waiting ? MeleePadOnlineAccentColor() : [UIColor colorWithWhite:0.72 alpha:1.0]));
    badge.backgroundColor = [badge.textColor colorWithAlphaComponent:0.12];
    MeleePadStyleLabel(badge, UIFontTextStyleCaption1, UIFontWeightSemibold);
    badge.layer.cornerRadius = 8.0;
    badge.clipsToBounds = YES;
    UIStackView *header = [[UIStackView alloc] initWithArrangedSubviews:@[hostLabel, badge]];
    header.axis = UILayoutConstraintAxisHorizontal;
    header.distribution = UIStackViewDistributionEqualSpacing;
    header.alignment = UIStackViewAlignmentCenter;
    UILabel *metadata = [self mutedLabel];
    NSInteger updatedSeconds = MAX(0, [room[@"updated_seconds_ago"] integerValue]);
    NSString *freshness = updatedSeconds <= 5 ? @"Live"
        : [NSString stringWithFormat:@"Updated %ld sec ago", (long)updatedSeconds];
    metadata.text = [NSString stringWithFormat:@"%@ · %ld-player game · %@",
        [self displayNameForRegion:room[@"region"]], (long)capacity, freshness];

    NSArray<NSDictionary<NSString *, id> *> *roster =
        [room[@"roster"] isKindOfClass:NSArray.class] ? room[@"roster"] : @[];
    NSMutableArray<NSString *> *rosterNames = [NSMutableArray array];
    for (NSDictionary<NSString *, id> *player in roster) {
        NSString *name = [player[@"name"] isKindOfClass:NSString.class]
            ? player[@"name"] : @"Player";
        if ([player[@"role"] isEqual:@"host"])
            name = [name stringByAppendingString:@" (Host)"];
        if ([player[@"session_id"] isEqual:_publicLobbyClient.localSessionID])
            name = [name stringByAppendingString:@" (You)"];
        [rosterNames addObject:name];
    }
    NSInteger hiddenPlayers = MAX(0, players - (NSInteger)rosterNames.count);
    if (hiddenPlayers > 0)
        [rosterNames addObject:[NSString stringWithFormat:@"%ld hidden", (long)hiddenPlayers]];
    NSInteger openSeats = MAX(0, capacity - players);
    if (openSeats > 0)
        [rosterNames addObject:[NSString stringWithFormat:@"%ld open", (long)openSeats]];
    UILabel *rosterLabel = [self mutedLabel];
    rosterLabel.textColor = [UIColor colorWithWhite:0.84 alpha:1.0];
    rosterLabel.text = [NSString stringWithFormat:@"Players: %@",
        rosterNames.count > 0 ? [rosterNames componentsJoinedByString:@" · "] : @"Unavailable"];
    UIStackView *occupancy = [self occupancyViewWithPlayers:players capacity:capacity];
    UILabel *matchSetup = [self mutedLabel];
    matchSetup.text = @"The host sets rules and stage in Melee. Connection quality appears after you join.";
    UILabel *compatibility = [self mutedLabel];
    NSString *version = [room[@"app_version"] isKindOfClass:NSString.class]
        ? room[@"app_version"] : @"unknown";
    NSString *build = [room[@"build"] isKindOfClass:NSString.class]
        ? room[@"build"] : @"unknown";
    if (joinable) {
        compatibility.text = [NSString stringWithFormat:
            @"Same build · MeleePad %@ (%@) · Ready to join", version, build];
    } else if (!compatible) {
        NSString *reason = [room[@"compatibility"] isKindOfClass:NSString.class]
            ? room[@"compatibility"] : @"This room uses a different build";
        compatibility.text = [NSString stringWithFormat:@"%@ · Host: MeleePad %@ (%@)",
            reason, version, build];
    } else {
        compatibility.text = [NSString stringWithFormat:@"Same build · %@",
            waiting ? @"Room is full" : @"Match already started"];
    }
    compatibility.textColor = compatible
        ? [UIColor colorWithWhite:0.72 alpha:1.0] : UIColor.systemOrangeColor;

    UIButton *join = [self primaryButtonWithTitle:@"Join Game" action:@selector(noop:)];
    join.enabled = joinable;
    join.accessibilityHint = joinable ? @"Connects to this public game."
        : compatibility.text;
    join.accessibilityIdentifier = [NSString stringWithFormat:@"join-public-room-%@", room[@"room_id"] ?: @""];
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    [join addAction:[UIAction actionWithHandler:^(__kindof UIAction *action) {
        (void)action;
        [weakSelf joinPublicRoom:room];
    }] forControlEvents:UIControlEventTouchUpInside];
    UIButton *more = [self secondaryButtonWithTitle:@"Safety" action:@selector(noop:)];
    more.menu = [self moderationMenuForRoom:room];
    more.showsMenuAsPrimaryAction = YES;
    UIStackView *actions = [[UIStackView alloc] initWithArrangedSubviews:@[more, join]];
    actions.axis = UILayoutConstraintAxisHorizontal;
    actions.spacing = 8.0;
    actions.distribution = UIStackViewDistributionFillEqually;
    UIStackView *card = [[UIStackView alloc]
        initWithArrangedSubviews:@[
            header, metadata, rosterLabel, occupancy, compatibility, matchSetup, actions,
        ]];
    card.axis = UILayoutConstraintAxisVertical;
    card.spacing = 10.0;
    card.layoutMargins = UIEdgeInsetsMake(14, 14, 14, 14);
    card.layoutMarginsRelativeArrangement = YES;
    card.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.08];
    card.layer.cornerRadius = 14.0;
    card.layer.borderWidth = 1.0;
    card.layer.borderColor = (joinable
        ? [MeleePadOnlineAccentColor() colorWithAlphaComponent:0.24]
        : [UIColor colorWithWhite:1.0 alpha:0.10]).CGColor;
    return card;
}

- (UIStackView *)occupancyViewWithPlayers:(NSInteger)players capacity:(NSInteger)capacity {
    NSInteger safeCapacity = MAX(2, MIN(4, capacity));
    NSInteger safePlayers = MAX(0, MIN(safeCapacity, players));
    NSMutableArray<UIView *> *icons = [NSMutableArray arrayWithCapacity:(NSUInteger)safeCapacity];
    UIImageSymbolConfiguration *symbol = [UIImageSymbolConfiguration
        configurationWithPointSize:16.0 weight:UIImageSymbolWeightSemibold];
    for (NSInteger index = 0; index < safeCapacity; ++index) {
        BOOL occupied = index < safePlayers;
        UIImage *image = [[UIImage systemImageNamed:occupied ? @"person.fill" : @"person"]
            imageByApplyingSymbolConfiguration:symbol];
        UIImageView *icon = [[UIImageView alloc] initWithImage:image];
        icon.tintColor = occupied ? MeleePadSeatColor((NSUInteger)index)
                                  : [UIColor colorWithWhite:0.48 alpha:1.0];
        icon.contentMode = UIViewContentModeCenter;
        [icon.widthAnchor constraintEqualToConstant:28.0].active = YES;
        [icon.heightAnchor constraintEqualToConstant:28.0].active = YES;
        [icons addObject:icon];
    }
    UILabel *count = [self mutedLabel];
    count.text = [NSString stringWithFormat:@"%ld of %ld seats filled",
        (long)safePlayers, (long)safeCapacity];
    UIStackView *iconRow = [[UIStackView alloc] initWithArrangedSubviews:icons];
    iconRow.axis = UILayoutConstraintAxisHorizontal;
    iconRow.spacing = 4.0;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[iconRow, count]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 10.0;
    row.isAccessibilityElement = YES;
    row.accessibilityLabel = count.text;
    return row;
}

- (UIMenu *)moderationMenuForRoom:(NSDictionary<NSString *, id> *)room {
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    UIAction *hide = [UIAction actionWithTitle:@"Hide This Game"
        image:[UIImage systemImageNamed:@"eye.slash"] identifier:nil
        handler:^(__kindof UIAction *action) { (void)action; [weakSelf hidePublicRoom:room]; }];
    NSMutableArray<UIMenuElement *> *children = [NSMutableArray arrayWithObject:hide];
    NSArray<NSDictionary<NSString *, id> *> *roster =
        [room[@"roster"] isKindOfClass:NSArray.class] ? room[@"roster"] : @[];
    if (roster.count == 0) {
        roster = @[@{
            @"session_id": room[@"host_id"] ?: @"",
            @"name": room[@"host"] ?: @"Host",
            @"role": @"host",
        }];
    }
    for (NSDictionary<NSString *, id> *player in roster) {
        NSString *sessionID = [player[@"session_id"] isKindOfClass:NSString.class]
            ? player[@"session_id"] : @"";
        if (sessionID.length == 0 || [sessionID isEqual:_publicLobbyClient.localSessionID])
            continue;
        NSString *name = [player[@"name"] isKindOfClass:NSString.class]
            ? player[@"name"] : @"Player";
        UIAction *offensive = [UIAction actionWithTitle:@"Offensive Name"
            image:[UIImage systemImageNamed:@"exclamationmark.bubble"]
            identifier:nil handler:^(__kindof UIAction *action) {
            (void)action;
            [weakSelf reportSessionID:sessionID room:room reason:@"offensive_name"];
        }];
        offensive.attributes = UIMenuElementAttributesDestructive;
        NSMutableArray<UIMenuElement *> *reasons = [NSMutableArray arrayWithObject:offensive];
        if ([player[@"role"] isEqual:@"host"]) {
            UIAction *spam = [UIAction actionWithTitle:@"Spam Listing"
                image:[UIImage systemImageNamed:@"exclamationmark.triangle"]
                identifier:nil handler:^(__kindof UIAction *action) {
                (void)action;
                [weakSelf reportSessionID:sessionID room:room reason:@"spam"];
            }];
            spam.attributes = UIMenuElementAttributesDestructive;
            [reasons addObject:spam];
        }
        [children addObject:[UIMenu menuWithTitle:[NSString stringWithFormat:@"Report %@", name]
            image:[UIImage systemImageNamed:@"flag"] identifier:nil options:0 children:reasons]];
    }
    return [UIMenu menuWithTitle:@"Safety" children:children];
}

- (void)hidePublicRoom:(NSDictionary<NSString *, id> *)room {
    [_publicLobbyClient hideSessionID:room[@"host_id"] completion:^(NSDictionary *result, NSString *error) {
        (void)result;
        if (error.length > 0) [self showError:error]; else [self refreshPublicGames:nil];
    }];
}

- (void)reportSessionID:(NSString *)sessionID
                    room:(NSDictionary<NSString *, id> *)room
                  reason:(NSString *)reason {
    [_publicLobbyClient reportSessionID:sessionID roomID:room[@"room_id"] reason:reason
        completion:^(NSDictionary *result, NSString *error) {
        (void)result;
        if (error.length > 0) [self showError:error]; else [self refreshPublicGames:nil];
    }];
}

- (void)hostPublicGame:(id)sender {
    (void)sender;
    NSString *nickname = [self confirmedNickname];
    if (nickname.length == 0) return;
    _roomCapacity = (NSUInteger)(2 + _capacityControl.selectedSegmentIndex);
    MeleePadLog(@"online ui event=host-requested mode=public capacity=%lu buffer=%@ frames=%lu",
        (unsigned long)_roomCapacity, _automaticBufferSwitch.on ? @"automatic" : @"manual",
        (unsigned long)[self bufferFrames]);
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
    NSString *nickname = [self confirmedNickname];
    if (nickname.length == 0) return;
    NSString *roomID = room[@"room_id"];
    if (roomID.length == 0) return;
    _roomCapacity = (NSUInteger)MAX(2, MIN(4, [room[@"capacity"] integerValue]));
    MeleePadLog(@"online ui event=join-requested mode=public capacity=%lu compatible=%@",
        (unsigned long)_roomCapacity, [room[@"compatible"] boolValue] ? @"yes" : @"no");
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
        [self.delegate onlinePlayViewController:self requestsJoinWithNickname:nickname
                                        address:code.lowercaseString port:2626 internetRoom:YES
                                automaticBuffer:self->_automaticBufferSwitch.on
                                   bufferFrames:[self bufferFrames]];
    }];
}

- (void)connect:(id)sender {
    (void)sender;
    [self.view endEditing:YES];
    NSString *nickname = [self confirmedNickname];
    if (nickname.length == 0) return;
    BOOL internetRoom = _connectionControl.selectedSegmentIndex == 1;
    _roomCapacity = 4;
    NSInteger portValue = internetRoom ? 2626 : _portField.text.integerValue;
    if (!internetRoom && (portValue < 1 || portValue > UINT16_MAX)) {
        [self showError:@"Enter a valid UDP port."];
        return;
    }
    MeleePadLog(@"online ui event=connect-requested mode=%@ role=%@ buffer=%@ frames=%lu",
        internetRoom ? @"private" : @"direct",
        _roleControl.selectedSegmentIndex == MeleePadOnlinePlayRoleHost ? @"host" : @"join",
        _automaticBufferSwitch.on ? @"automatic" : @"manual",
        (unsigned long)[self bufferFrames]);
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

- (void)chatTextChanged:(UITextField *)sender {
    NSString *text = [sender.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    _sendChatButton.enabled = text.length > 0 && text.length <= 160;
    _chatCountLabel.text = [NSString stringWithFormat:@"%lu / 160",
        (unsigned long)sender.text.length];
    _chatCountLabel.accessibilityLabel = [NSString stringWithFormat:
        @"%lu of 160 characters", (unsigned long)sender.text.length];
}

- (void)sendChatMessage:(id)sender {
    (void)sender;
    NSString *text = [_chatField.text stringByTrimmingCharactersInSet:
        NSCharacterSet.whitespaceAndNewlineCharacterSet];
    if (text.length == 0 || text.length > 160) {
        _stateLabel.textColor = UIColor.systemRedColor;
        _stateLabel.text = @"Messages must be between 1 and 160 characters.";
        return;
    }
    _sendChatButton.enabled = NO;
    void (^completion)(NSString *) = ^(NSString *error) {
        if (error.length > 0) {
            self->_stateLabel.textColor = UIColor.systemRedColor;
            self->_stateLabel.text = error;
            [self chatTextChanged:self->_chatField];
            return;
        }
        self->_chatField.text = @"";
        [self chatTextChanged:self->_chatField];
        if (self->_usesPublicChat)
            [self pollPublicMessagesIfNeeded:YES];
    };
    if (_usesPublicChat) {
        [_publicLobbyClient sendMessage:text
            completion:^(NSDictionary *result, NSString *error) {
            (void)result;
            completion(error);
        }];
    } else {
        [self.delegate onlinePlayViewController:self
            requestsSendPeerChatMessage:text completion:completion];
    }
}

- (UIMenu *)chatSafetyMenuForMessage:(NSDictionary<NSString *, id> *)message {
    NSString *sessionID = [message[@"sender_id"] isKindOfClass:NSString.class]
        ? message[@"sender_id"] : @"";
    __weak MeleePadOnlinePlayViewController *weakSelf = self;
    UIAction *hide = [UIAction actionWithTitle:@"Hide Player"
        image:[UIImage systemImageNamed:@"eye.slash"] identifier:nil
        handler:^(__kindof UIAction *action) {
        (void)action;
        MeleePadOnlinePlayViewController *strongSelf = weakSelf;
        if (strongSelf == nil) return;
        [strongSelf->_publicLobbyClient hideSessionID:sessionID
            completion:^(NSDictionary *result, NSString *error) {
            (void)result;
            strongSelf->_stateLabel.textColor = error.length > 0
                ? UIColor.systemRedColor : UIColor.systemGreenColor;
            strongSelf->_stateLabel.text = error.length > 0
                ? error : @"Player hidden. Their future room messages will not appear.";
        }];
    }];
    UIAction *report = [UIAction actionWithTitle:@"Report Chat Message"
        image:[UIImage systemImageNamed:@"exclamationmark.bubble"] identifier:nil
        handler:^(__kindof UIAction *action) {
        (void)action;
        MeleePadOnlinePlayViewController *strongSelf = weakSelf;
        if (strongSelf == nil) return;
        [strongSelf->_publicLobbyClient reportSessionID:sessionID
            roomID:strongSelf->_publicLobbyClient.activeRoomID reason:@"harassment"
            completion:^(NSDictionary *result, NSString *error) {
            (void)result;
            strongSelf->_stateLabel.textColor = error.length > 0
                ? UIColor.systemRedColor : UIColor.systemGreenColor;
            strongSelf->_stateLabel.text = error.length > 0
                ? error : @"Report submitted. The player is now hidden.";
        }];
    }];
    report.attributes = UIMenuElementAttributesDestructive;
    return [UIMenu menuWithTitle:@"Player safety" children:@[hide, report]];
}

- (UIView *)chatRowForMessage:(NSDictionary<NSString *, id> *)message {
    BOOL peerChat = [message[@"transport"] isEqual:@"peer"];
    BOOL local = peerChat ? [message[@"local"] boolValue]
                          : [message[@"sender_id"] isEqual:_publicLobbyClient.localSessionID];
    UILabel *sender = [UILabel new];
    sender.text = local
        ? [NSString stringWithFormat:@"%@ · YOU", message[@"sender"] ?: @"Player"]
        : (message[@"sender"] ?: @"Player");
    sender.textColor = local ? MeleePadOnlineAccentColor() : UIColor.whiteColor;
    MeleePadStyleLabel(sender, UIFontTextStyleCaption1, UIFontWeightBold);
    UILabel *body = [UILabel new];
    body.text = message[@"text"] ?: @"";
    body.textColor = UIColor.whiteColor;
    body.numberOfLines = 0;
    MeleePadStyleLabel(body, UIFontTextStyleBody, UIFontWeightRegular);
    UIStackView *copy = [[UIStackView alloc] initWithArrangedSubviews:@[sender, body]];
    copy.axis = UILayoutConstraintAxisVertical;
    copy.spacing = 2.0;
    NSMutableArray<UIView *> *items = [NSMutableArray arrayWithObject:copy];
    if (!local && !peerChat) {
        UIButton *safety = [self infoButtonWithAccessibilityLabel:@"Chat message safety"
                                                           action:@selector(noop:)];
        UIButtonConfiguration *configuration = safety.configuration;
        configuration.image = [UIImage systemImageNamed:@"ellipsis.circle"];
        safety.configuration = configuration;
        safety.menu = [self chatSafetyMenuForMessage:message];
        safety.showsMenuAsPrimaryAction = YES;
        [items addObject:safety];
    }
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:items];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.distribution = UIStackViewDistributionEqualSpacing;
    row.spacing = 10.0;
    row.layoutMargins = UIEdgeInsetsMake(10, 12, 10, 12);
    row.layoutMarginsRelativeArrangement = YES;
    row.backgroundColor = local
        ? [MeleePadOnlineAccentColor() colorWithAlphaComponent:0.12]
        : [UIColor colorWithWhite:1.0 alpha:0.06];
    row.layer.cornerRadius = 12.0;
    row.layer.borderWidth = 1.0;
    row.layer.borderColor = (local
        ? [MeleePadOnlineAccentColor() colorWithAlphaComponent:0.24]
        : [UIColor colorWithWhite:1.0 alpha:0.10]).CGColor;
    row.accessibilityLabel = [NSString stringWithFormat:@"%@ says %@",
        sender.text, body.text];
    UIView *spacer = [UIView new];
    [spacer setContentHuggingPriority:UILayoutPriorityDefaultLow
                              forAxis:UILayoutConstraintAxisHorizontal];
    UIStackView *bubbleLine = [[UIStackView alloc] initWithArrangedSubviews:
        local ? @[spacer, row] : @[row, spacer]];
    bubbleLine.axis = UILayoutConstraintAxisHorizontal;
    bubbleLine.alignment = UIStackViewAlignmentFill;
    bubbleLine.spacing = 44.0;
    [row.widthAnchor constraintLessThanOrEqualToAnchor:bubbleLine.widthAnchor
                                            multiplier:0.82].active = YES;
    return bubbleLine;
}

- (void)appendChatMessageRow:(NSDictionary<NSString *, id> *)message {
    if (_chatEmptyLabel.superview != nil) {
        [_messagesStack removeArrangedSubview:_chatEmptyLabel];
        [_chatEmptyLabel removeFromSuperview];
    }
    [_messagesStack addArrangedSubview:[self chatRowForMessage:message]];
    while (_messagesStack.arrangedSubviews.count > 8) {
        UIView *oldest = _messagesStack.arrangedSubviews.firstObject;
        [_messagesStack removeArrangedSubview:oldest];
        [oldest removeFromSuperview];
    }
}

- (void)renderPeerMessages:(NSArray<NSDictionary<NSString *, id> *> *)messages {
    for (NSDictionary<NSString *, id> *message in messages) {
        NSUInteger messageID = [message[@"id"] unsignedIntegerValue];
        if (messageID == 0 || messageID <= _lastPeerMessageID)
            continue;
        _lastPeerMessageID = messageID;
        [self appendChatMessageRow:message];
    }
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
            [self appendChatMessageRow:message];
        }
    }];
}

- (void)toggleReady:(id)sender {
    (void)sender;
    _localReady = !_localReady;
    UIButtonConfiguration *configuration = _readyButton.configuration;
    configuration.title = _localReady ? @"Not Ready" : @"Ready";
    configuration.image = _localReady
        ? [UIImage systemImageNamed:@"checkmark.circle.fill"] : nil;
    configuration.imagePadding = 6.0;
    _readyButton.configuration = configuration;
    MeleePadLog(@"online ui event=ready-changed ready=%@", _localReady ? @"yes" : @"no");
    [self.delegate onlinePlayViewController:self requestsReady:_localReady];
}

- (void)start:(id)sender {
    (void)sender;
    MeleePadLog(@"online ui event=start-requested capacity=%lu", (unsigned long)_roomCapacity);
    [_publicLobbyClient heartbeatInGame:YES completion:nil];
    [self.delegate onlinePlayViewControllerRequestsStart:self];
}

- (void)cancel:(id)sender {
    (void)sender;
    [self closePublicPresence];
    [self.delegate onlinePlayViewControllerRequestsCancel:self];
}

- (void)returnToGame:(id)sender {
    (void)sender;
    [self.delegate onlinePlayViewControllerRequestsReturnToGame:self];
}

- (void)closePublicPresence {
    _publicHostPending = NO;
    if (_publicLobbyClient.activeRoomID.length == 0) return;
    [_publicLobbyClient closeHostedRoomWithCompletion:nil];
    [_publicLobbyClient leaveActiveRoomWithCompletion:nil];
}

- (void)noop:(id)sender { (void)sender; }

- (void)setHeroCompact:(BOOL)compact {
    _heroKickerRow.hidden = NO;
    _heroDetailLabel.hidden = compact;
    _heroStack.spacing = compact ? 5.0 : 8.0;
    _heroStack.layoutMargins = compact ? UIEdgeInsetsMake(14, 18, 14, 18)
                                       : UIEdgeInsetsMake(20, 20, 20, 20);
    _heroWatermark.alpha = compact ? 0.68 : 1.0;
    _heroTitleLabel.font = [[UIFontMetrics metricsForTextStyle:
        compact ? UIFontTextStyleTitle1 : UIFontTextStyleLargeTitle]
        scaledFontForFont:[UIFont systemFontOfSize:compact ? 25.0 : 34.0
                                            weight:UIFontWeightBold]
        maximumPointSize:compact ? 31.0 : 38.0];
}

- (void)showConnectingWithMessage:(NSString *)message {
    [self setHeroCompact:YES];
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
          sessionRunning:(BOOL)sessionRunning
                roomCode:(NSString *)roomCode
                messages:(NSArray<NSDictionary<NSString *, id> *> *)messages
                  status:(NSString *)status {
    [self setHeroCompact:YES];
    _setupStack.hidden = YES;
    _lobbyStack.hidden = NO;
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:sessionRunning ? @"Return to Game" : @"Cancel"
        style:UIBarButtonItemStylePlain target:self
        action:sessionRunning ? @selector(returnToGame:) : @selector(cancel:)];
    _readyButton.hidden = sessionRunning;
    _startButton.hidden = sessionRunning || role != MeleePadOnlinePlayRoleHost;
    _leaveSessionButton.hidden = !sessionRunning;
    BOOL publicRoom = _publicLobbyClient.activeRoomID.length > 0 || _publicHostPending;
    _usesPublicChat = publicRoom;
    _startButton.enabled = canStart && (!publicRoom || players.count >= _roomCapacity);
    _roomCodeLabel.hidden = publicRoom || roomCode.length == 0;
    _roomCodeLabel.text = (!publicRoom && roomCode.length > 0)
        ? [NSString stringWithFormat:@"Room code: %@", roomCode] : @"";
    _stateLabel.textColor = [UIColor colorWithWhite:0.82 alpha:1.0];
    _stateLabel.text = sessionRunning
        ? [NSString stringWithFormat:@"Match in progress · %lu-frame%@ buffer",
            (unsigned long)bufferFrames, automaticBuffer ? @" automatic" : @""]
        : (status.length > 0 ? status : [NSString stringWithFormat:
            @"Input buffer: %lu frame%@%@", (unsigned long)bufferFrames,
            bufferFrames == 1 ? @"" : @"s", automaticBuffer ? @" (automatic)" : @""]);
    for (UIView *view in _playersStack.arrangedSubviews) {
        [_playersStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    NSUInteger capacity = MAX(_roomCapacity, players.count);
    capacity = MAX(2, MIN(4, capacity));
    NSUInteger readyCount = 0;
    NSUInteger compatibleCount = 0;
    for (NSDictionary<NSString *, id> *player in players) {
        readyCount += [player[@"ready"] boolValue] ? 1 : 0;
        compatibleCount += [player[@"compatible"] boolValue] ? 1 : 0;
    }
    NSString *roleName = role == MeleePadOnlinePlayRoleHost ? @"host" : @"join";
    NSString *diagnosticSignature = [NSString stringWithFormat:
        @"role=%@ public=%d players=%lu capacity=%lu ready=%lu compatible=%lu canStart=%d buffer=%@ frames=%lu",
        roleName, publicRoom, (unsigned long)players.count, (unsigned long)capacity,
        (unsigned long)readyCount, (unsigned long)compatibleCount, canStart,
        automaticBuffer ? @"automatic" : @"manual", (unsigned long)bufferFrames];
    if (![_lastLobbyDiagnosticSignature isEqualToString:diagnosticSignature]) {
        _lastLobbyDiagnosticSignature = diagnosticSignature;
        MeleePadLog(@"online lobby state %@", diagnosticSignature);
    }
    for (NSUInteger index = 0; index < capacity; ++index) {
        NSDictionary<NSString *, id> *player = index < players.count ? players[index] : nil;
        [_playersStack addArrangedSubview:[self seatCardAtIndex:index player:player]];
    }
    UIStackView *chatStack = (UIStackView *)[_lobbyStack viewWithTag:7001];
    chatStack.hidden = NO;
    if (!publicRoom)
        [self renderPeerMessages:messages];
    if (_publicHostPending && roomCode.length == 8) {
        _publicHostPending = NO;
        [_publicLobbyClient publishRoomWithTraversalCode:roomCode region:@"auto"
            capacity:_roomCapacity
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
            if (!sessionRunning)
                [_publicLobbyClient heartbeatInGame:NO completion:nil];
        }
        [self pollPublicMessagesIfNeeded:NO];
    }
}

- (UIView *)seatCardAtIndex:(NSUInteger)index
                     player:(NSDictionary<NSString *, id> *)player {
    UIColor *seatColor = MeleePadSeatColor(index);
    UILabel *seat = [UILabel new];
    seat.text = [NSString stringWithFormat:@"P%lu", (unsigned long)index + 1];
    seat.textAlignment = NSTextAlignmentCenter;
    seat.textColor = player != nil ? UIColor.whiteColor : seatColor;
    seat.backgroundColor = player != nil ? seatColor
        : [seatColor colorWithAlphaComponent:0.10];
    seat.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleSubheadline]
        scaledFontForFont:[UIFont systemFontOfSize:15.0 weight:UIFontWeightBold]
        maximumPointSize:20.0];
    seat.adjustsFontForContentSizeCategory = YES;
    seat.layer.cornerRadius = 18.0;
    seat.clipsToBounds = YES;
    [seat.widthAnchor constraintEqualToConstant:44.0].active = YES;
    [seat.heightAnchor constraintEqualToConstant:36.0].active = YES;

    UILabel *name = [UILabel new];
    name.text = player != nil ? (player[@"name"] ?: @"Player") : @"Open seat";
    name.textColor = player != nil ? UIColor.whiteColor
                                   : [UIColor colorWithWhite:0.70 alpha:1.0];
    MeleePadStyleLabel(name, UIFontTextStyleHeadline, UIFontWeightSemibold);
    name.numberOfLines = 1;

    BOOL local = [player[@"local"] boolValue];
    NSString *identity = nil;
    if (player != nil && index == 0 && local) identity = @"YOU · HOST";
    else if (player != nil && index == 0) identity = @"HOST";
    else if (player != nil && local) identity = @"YOU";
    UILabel *identityBadge = [UILabel new];
    identityBadge.text = identity != nil ? [NSString stringWithFormat:@"  %@  ", identity] : @"";
    identityBadge.textColor = seatColor;
    identityBadge.backgroundColor = [seatColor colorWithAlphaComponent:0.14];
    identityBadge.font = [[UIFontMetrics metricsForTextStyle:UIFontTextStyleCaption2]
        scaledFontForFont:[UIFont systemFontOfSize:11.0 weight:UIFontWeightBold]
        maximumPointSize:15.0];
    identityBadge.adjustsFontForContentSizeCategory = YES;
    identityBadge.layer.cornerRadius = 7.0;
    identityBadge.clipsToBounds = YES;
    identityBadge.hidden = identity.length == 0;
    UIStackView *nameRow = [[UIStackView alloc]
        initWithArrangedSubviews:@[name, identityBadge]];
    nameRow.axis = UILayoutConstraintAxisHorizontal;
    nameRow.alignment = UIStackViewAlignmentCenter;
    nameRow.spacing = 8.0;

    UILabel *detail = [self mutedLabel];
    if (player != nil) {
        NSString *controller = player[@"controller"] ?: @"No controller";
        NSString *ready = [player[@"ready"] boolValue] ? @"Ready" : @"Not ready";
        NSString *compatibility = [player[@"compatible"] boolValue]
            ? @"Build matches" : @"Version mismatch";
        detail.text = [NSString stringWithFormat:@"%@ · %@ ms to host · %@ · %@",
            controller, player[@"ping"] ?: @0, compatibility, ready];
        if (![player[@"compatible"] boolValue])
            detail.textColor = UIColor.systemOrangeColor;
    } else {
        detail.text = @"Waiting for a player";
    }
    UIStackView *copy = [[UIStackView alloc] initWithArrangedSubviews:@[nameRow, detail]];
    copy.axis = UILayoutConstraintAxisVertical;
    copy.spacing = 3.0;
    UIStackView *row = [[UIStackView alloc] initWithArrangedSubviews:@[seat, copy]];
    row.axis = UILayoutConstraintAxisHorizontal;
    row.alignment = UIStackViewAlignmentCenter;
    row.spacing = 12.0;
    row.layoutMargins = UIEdgeInsetsMake(12, 12, 12, 12);
    row.layoutMarginsRelativeArrangement = YES;
    row.backgroundColor = player != nil ? [seatColor colorWithAlphaComponent:0.10]
                                        : [UIColor colorWithWhite:1.0 alpha:0.04];
    row.layer.cornerRadius = 12.0;
    row.layer.borderWidth = 1.0;
    row.layer.borderColor = [seatColor colorWithAlphaComponent:player != nil ? 0.30 : 0.12].CGColor;
    row.isAccessibilityElement = YES;
    row.accessibilityLabel = [NSString stringWithFormat:@"Seat %lu, %@, %@",
        (unsigned long)index + 1, name.text, detail.text];
    return row;
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
    _lastPeerMessageID = 0;
    _usesPublicChat = NO;
    for (UIView *view in _messagesStack.arrangedSubviews) {
        [_messagesStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }
    [_messagesStack addArrangedSubview:_chatEmptyLabel];
    _chatField.text = @"";
    _sendChatButton.enabled = NO;
    _chatCountLabel.text = @"0 / 160";
    _chatCountLabel.accessibilityLabel = @"0 of 160 characters";
    _lastMessagePoll = 0;
    _lastHeartbeat = 0;
    _lastLobbyDiagnosticSignature = nil;
    _lastPublicRoomsSignature = nil;
    _roomCapacity = 2;
    _advancedExpanded = NO;
    _bufferStack.hidden = YES;
    UIButtonConfiguration *advancedConfiguration = _advancedButton.configuration;
    advancedConfiguration.title = @"Advanced settings";
    _advancedButton.configuration = advancedConfiguration;
    _setupStack.hidden = NO;
    _lobbyStack.hidden = YES;
    UIButtonConfiguration *configuration = _readyButton.configuration;
    configuration.title = @"Ready";
    configuration.image = nil;
    _readyButton.configuration = configuration;
    [self setHeroCompact:NO];
    [self connectionChanged:_connectionControl];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    textField.layer.borderColor =
        [MeleePadOnlineAccentColor() colorWithAlphaComponent:0.72].CGColor;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    textField.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.18].CGColor;
}

- (BOOL)textField:(UITextField *)textField
    shouldChangeCharactersInRange:(NSRange)range
                replacementString:(NSString *)string {
    if (textField != _chatField)
        return YES;
    NSString *updated = [textField.text stringByReplacingCharactersInRange:range
                                                                 withString:string];
    return updated.length <= 160 &&
        [string rangeOfCharacterFromSet:NSCharacterSet.newlineCharacterSet].location == NSNotFound;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    if (textField == _chatField) {
        [self sendChatMessage:textField];
        return NO;
    } else if (textField == _nicknameField) {
        [textField resignFirstResponder];
        [self confirmNickname:textField];
    } else if (textField == _addressField && !_portField.hidden) {
        [_portField becomeFirstResponder];
    } else {
        [textField resignFirstResponder];
    }
    return YES;
}

@end
