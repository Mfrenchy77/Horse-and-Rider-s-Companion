// ignore_for_file: constant_identifier_names

part of 'app_cubit.dart';

/// The current status of the app.
enum AppStatus {
  authenticated,
  unauthenticated,
}

/// The Status of the Message to Support
enum MessageToSupportStatus {
  initial,
  sending,
  success,
}

/// The Sort State of the Resources
enum ResourcesSortStatus {
  saved,
  recent,
  oldest,
  mostRecommended,
}

/// The Sort State of the Comments
enum CommentSortState {
  Best,
  Recent,
  Oldest,
  Worst,
}

/// The Sorting of Conversations
enum ConversationsSort {
  unread,
  oldest,
  createdDate,
  lastupdatedDate,
}

/// The State of the Conversation
enum ConversationState {
  error,
  loaded,
  loading,
}

/// The state of the Conversations
enum ConversationsState {
  error,
  loaded,
  loading,
}

/// The Status of the Accept Request
enum AcceptStatus {
  loading,
  waiting,
  accepted,
}

/// The Navigation within the SkillTree Section
enum SkillTreeNavigation {
  SkillList,
  SkillLevel,
  TrainingPath,
  TrainingPathList
}

/// Tag for the Log Entry
enum LogTag {
  Show,
  Edit,
  Other,
  Health,
  Training,
}

/// The Page Status of the App
enum AppPageStatus {
  auth,
  error,
  loaded,
  profile,
  loading,
  settings,
  messages,
  resource,
  skillTree,
  resourceList,
  profileSetup,
  awitingEmailVerification,
}

class AppState extends Equatable {
  const AppState._({
    this.skill,
    this.message,
    this.messages,
    this.resource,
    this.bannerAd,
    this.messageId,
    this.index = 0,
    this.horseId = '',
    this.usersProfile,
    this.conversation,
    this.trainingPath,
    this.horseProfile,
    this.conversations,
    this.ownersProfile,
    this.isGuest = true,
    this.viewingProfile,
    this.isEdit = false,
    required this.status,
    this.isError = false,
    this.isSearch = false,
    this.messageText = '',
    this.isMessage = false,
    this.errorMessage = '',
    this.isViewing = false,
    this.isForRider = true,
    this.user = User.empty,
    this.allSkills = const [],
    this.resources = const [],
    this.isFromProfile = false,
    this.searchList = const [],
    this.isProfileSetup = false,
    this.sortedSkills = const [],
    this.isBannerAdReady = false,
    this.trainingPaths = const [],
    this.viewingProfielEmail = '',
    this.savedResources = const [],
    this.isFromTrainingPath = false,
    this.resourceComments = const [],
    this.isEmailVerification = false,
    this.isFromTrainingPathList = false,
    this.pageStatus = AppPageStatus.loading,
    this.acceptStatus = AcceptStatus.waiting,
    this.difficultyState = DifficultyState.all,
    this.commentSortState = CommentSortState.Best,
    this.conversationsSort = ConversationsSort.unread,
    this.conversationState = ConversationState.loaded,
    this.conversationsState = ConversationsState.loading,
    this.resourcesSortStatus = ResourcesSortStatus.recent,
    this.skillTreeNavigation = SkillTreeNavigation.SkillList,
    this.messageToSupportStatus = MessageToSupportStatus.initial,
  });

  const AppState.authenticated(User user)
      : this._(status: AppStatus.authenticated, user: user);

  const AppState.unauthenticated() : this._(status: AppStatus.unauthenticated);

  /// The index of the current page in the app.
  final int index;

  /// The current user of the app.
  final User user;

  /// Whether the user has selcted to edit.
  final bool isEdit;

  /// The current skill being viewed.
  final Skill? skill;

  /// Whether the user is a guest or not.
  final bool isGuest;

  /// Set when an Error snackbar needs to be shown
  final bool isError;

  /// Whether the state for the app bar is set to search.
  final bool isSearch;

  /// Set when a message snackbar needs to be shown
  final bool isMessage;

  /// The Id of the horse being viewed.
  final String horseId;

  /// Whether the use is viewing a profile or not.
  final bool isViewing;

  /// Whether we are viewing a rider or a horse profile.
  final bool isForRider;

  /// The message being viewed
  final Message? message;

  /// The current status of the app(whether the user is authenticated or not).
  final AppStatus status;

  /// The Id of a conversation to open
  final String? messageId;

  /// The message the user is typing
  final String messageText;

  /// The Resource being viewed.
  final Resource? resource;

  /// Whether Navigation is coming from Profile.
  final bool isFromProfile;

  /// The conversation being viewed
  final Conversation? conversation;

  /// The BannerAd to be shown in the app.
  final BannerAd? bannerAd;

  /// A String used to display an error message a snackbar
  /// message or a message to support
  final String errorMessage;

  /// Whether the user need to finish setting up their profile
  final bool isProfileSetup;

  /// Whether the BannerAd is ready to be shown.
  final bool isBannerAdReady;

  /// The Unsorted list of Skills from the database
  final List<Skill?> allSkills;

  /// Whether Navigation is coming from the TrainingPath section.
  final bool isFromTrainingPath;

  /// The list of messages in a conversation
  final List<Message>? messages;

  /// Whether we want to display the email verification dialog
  final bool isEmailVerification;

  /// The status of the accept request
  final AcceptStatus acceptStatus;

  /// The list of conversations for the user
  final List<Conversation>? conversations;

  /// The current page status of the app.
  final AppPageStatus pageStatus;

  /// The List to populate the search field.
  final List<String?> searchList;

  /// The database resources
  final List<Resource?> resources;

  /// The List of Skills that are sorted by difficulty and isForRider
  final List<Skill?> sortedSkills;

  /// The email of the profile to be viewed.
  final String viewingProfielEmail;

  /// The current Training Path being viewed.
  final TrainingPath? trainingPath;

  /// Whether Navigation is coming from the TrainingPathList section.
  final bool isFromTrainingPathList;

  /// The current user's RiderProfile.
  final RiderProfile? usersProfile;

  /// The Profile of the owner of the horse being viewed
  /// if not the current user.
  final RiderProfile? ownersProfile;

  /// The HorseProfile being viewed.
  final HorseProfile? horseProfile;

  /// The RiderProfile being viewed.
  final RiderProfile? viewingProfile;

  /// List of Saved Resources
  final List<Resource?> savedResources;

  /// The List of Comments for a Resource:
  final List<Comment> resourceComments;

  /// The Difficulty of the skills for sorting
  final DifficultyState difficultyState;

  /// The sort state of the resources comments
  final CommentSortState commentSortState;

  /// The database training paths
  final List<TrainingPath?> trainingPaths;

  /// The state of the conversation
  final ConversationState conversationState;

  /// The sort status for the messages list
  final ConversationsSort conversationsSort;

  /// The state of the conversations
  final ConversationsState conversationsState;

  /// The sort state of the resources
  final ResourcesSortStatus resourcesSortStatus;

  /// The current navigation within the SkillTree section.
  final SkillTreeNavigation skillTreeNavigation;

  /// The Status of the messages to support
  final MessageToSupportStatus messageToSupportStatus;

  AppState copyWith({
    int? index,
    User? user,
    Skill? skill,
    bool? isEdit,
    bool? isGuest,
    bool? isError,
    bool? isSearch,
    bool? isMessage,
    String? horseId,
    Message? message,
    bool? isViewing,
    bool? isForRider,
    String? messageId,
    AppStatus? status,
    Resource? resource,
    BannerAd? bannerAd,
    String? messageText,
    bool? isFromProfile,
    bool? isProfileSetup,
    String? errorMessage,
    bool? isBannerAdReady,
    List<Message>? messages,
    List<Skill?>? allSkills,
    bool? isFromTrainingPath,
    bool? isEmailVerification,
    List<String?>? searchList,
    AppPageStatus? pageStatus,
    List<Skill?>? sortedSkills,
    TrainingPath? trainingPath,
    List<Resource?>? resources,
    HorseProfile? horseProfile,
    RiderProfile? usersProfile,
    AcceptStatus? acceptStatus,
    Conversation? conversation,
    RiderProfile? ownersProfile,
    String? viewingProfielEmail,
    bool? isFromTrainingPathList,
    RiderProfile? viewingProfile,
    List<Comment>? resourceComments,
    List<Resource?>? savedResources,
    DifficultyState? difficultyState,
    List<Conversation>? conversations,
    CommentSortState? commentSortState,
    List<TrainingPath?>? trainingPaths,
    ConversationState? conversationState,
    ConversationsSort? conversationsSort,
    ConversationsState? conversationsState,
    ResourcesSortStatus? resourcesSortStatus,
    SkillTreeNavigation? skillTreeNavigation,
    MessageToSupportStatus? messageToSupportStatus,
  }) {
    return AppState._(
      user: user ?? this.user,
      skill: skill ?? this.skill,
      index: index ?? this.index,
      isEdit: isEdit ?? this.isEdit,
      status: status ?? this.status,
      isError: isError ?? this.isError,
      horseId: horseId ?? this.horseId,
      isGuest: isGuest ?? this.isGuest,
      message: message ?? this.message,
      messages: messages ?? this.messages,
      resource: resource ?? this.resource,
      isSearch: isSearch ?? this.isSearch,
      bannerAd: bannerAd ?? this.bannerAd,
      messageId: messageId ?? this.messageId,
      isMessage: isMessage ?? this.isMessage,
      isViewing: isViewing ?? this.isViewing,
      resources: resources ?? this.resources,
      allSkills: allSkills ?? this.allSkills,
      pageStatus: pageStatus ?? this.pageStatus,
      isForRider: isForRider ?? this.isForRider,
      searchList: searchList ?? this.searchList,
      messageText: messageText ?? this.messageText,
      conversation: conversation ?? this.conversation,
      acceptStatus: acceptStatus ?? this.acceptStatus,
      sortedSkills: sortedSkills ?? this.sortedSkills,
      trainingPath: trainingPath ?? this.trainingPath,
      errorMessage: errorMessage ?? this.errorMessage,
      horseProfile: horseProfile ?? this.horseProfile,
      usersProfile: usersProfile ?? this.usersProfile,
      conversations: conversations ?? this.conversations,
      trainingPaths: trainingPaths ?? this.trainingPaths,
      ownersProfile: ownersProfile ?? this.ownersProfile,
      isFromProfile: isFromProfile ?? this.isFromProfile,
      isProfileSetup: isProfileSetup ?? this.isProfileSetup,
      savedResources: savedResources ?? this.savedResources,
      viewingProfile: viewingProfile ?? this.viewingProfile,
      isBannerAdReady: isBannerAdReady ?? this.isBannerAdReady,
      difficultyState: difficultyState ?? this.difficultyState,
      resourceComments: resourceComments ?? this.resourceComments,
      commentSortState: commentSortState ?? this.commentSortState,
      conversationState: conversationState ?? this.conversationState,
      conversationsSort: conversationsSort ?? this.conversationsSort,
      conversationsState: conversationsState ?? this.conversationsState,
      isFromTrainingPath: isFromTrainingPath ?? this.isFromTrainingPath,
      isEmailVerification: isEmailVerification ?? this.isEmailVerification,
      viewingProfielEmail: viewingProfielEmail ?? this.viewingProfielEmail,
      skillTreeNavigation: skillTreeNavigation ?? this.skillTreeNavigation,
      resourcesSortStatus: resourcesSortStatus ?? this.resourcesSortStatus,
      isFromTrainingPathList:
          isFromTrainingPathList ?? this.isFromTrainingPathList,
      messageToSupportStatus:
          messageToSupportStatus ?? this.messageToSupportStatus,
    );
  }

  @override
  List<Object?> get props => [
        user,
        skill,
        index,
        status,
        isEdit,
        isGuest,
        message,
        horseId,
        isError,
        messages,
        resource,
        bannerAd,
        isSearch,
        messageId,
        isMessage,
        isViewing,
        resources,
        allSkills,
        isForRider,
        pageStatus,
        searchList,
        messageText,
        conversation,
        acceptStatus,
        sortedSkills,
        trainingPath,
        errorMessage,
        horseProfile,
        usersProfile,
        conversations,
        ownersProfile,
        isFromProfile,
        trainingPaths,
        savedResources,
        viewingProfile,
        isProfileSetup,
        isBannerAdReady,
        difficultyState,
        resourceComments,
        commentSortState,
        conversationState,
        conversationsSort,
        conversationsState,
        isFromTrainingPath,
        skillTreeNavigation,
        resourcesSortStatus,
        viewingProfielEmail,
        isEmailVerification,
        isFromTrainingPathList,
        messageToSupportStatus,
      ];
}
