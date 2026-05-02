{ pkgs, ... }:

{
  programs.vesktop = {
    enable = true;
    settings = {
      arRPC = true;
      checkUpdates = false;
      splashTheming = true;
      discordBranch = "stable";
      hardwareAcceleration = true;
      minimizeToTray = false;
    };
    vencord.settings = {
      autoUpdate = false;
      autoUpdateNotification = false;
      notifyAboutUpdates = false;
      useQuickCss = true;
      disableMinSize = true;
      plugins = {
        FakeNitro = {
          enabled = true;
          enableEmojiBypass = false;
          enableStickerBypass = false;
          transformStickers = true;
          transformCompoundSentence = true;
        };
        AlwaysExpandRoles.enabled = true;
        AlwaysTrust.enabled = true;
        AnonymiseFileNames.enabled = true;
        BetterGifPicker.enabled = true;
        BetterNotesBox = {
          enabled = true;
          noSpellCheck = true;
        };
        BetterRoleContext.enabled = true;
        BetterSessions.enabled = true;
        BetterUploadButton.enabled = true;
        BiggerStreamPreview.enabled = true;
        BlurNSFW.enabled = true;
        CallTimer.enabled = true;
        ClearURLs.enabled = true;
        ConsoleJanitor.enabled = true;
        ConsoleShortcuts.enabled = true;
        CopyEmojiMarkdown = {
          enabled = true;
          copyUnicode = true;
        };
        CopyFileContents.enabled = true;
        CopyUserURLs.enabled = true;
        CustomIdle.enabled = true;
        Experiments.enabled = true;
        ExpressionCloner.enabled = true;
        FavoriteEmojiFirst.enabled = true;
        FavoriteGifSearch.enabled = true;
        FixCodeblockGap.enabled = true;
        FixSpotifyEmbeds.enabled = true;
        FixYoutubeEmbeds.enabled = true;
        ForceOwnerCrown.enabled = true;
        FriendsSince.enabled = true;
        GameActivityToggle.enabled = true;
        ImageFilename.enabled = true;
        ImageZoom.enabled = true;
        ImplicitRelationships.enabled = true;
        LoadingQuotes.enabled = true;
        MemberCount.enabled = true;
        MentionAvatars.enabled = true;
        MessageLinkEmbeds.enabled = true;
        MutualGroupDMs.enabled = true;
        NewGuildSettings = {
          enabled = true;
          messages = 1;
        };
        NoBlockedMessages.enabled = true;
        NoOnboardingDelay.enabled = true;
        NoPendingCount = {
          enabled = true;
          hideFriendRequestsCount = false;
        };
        NoReplyMention = {
          enabled = true;
          shouldPingListed = true;
          userList = "229234811162591233,1248971385502695485,257831928256921610,714368947704823819,873299952548319252,856938351680159797,459706741806858251,170540273976213505";
        };
        NoTypingAnimation.enabled = true;
        NoUnblockToJump.enabled = true;
        NormalizeMessageLinks.enabled = true;
        OnePingPerDM = {
          enabled = true;
          allowMentions = true;
          allowEveryone = true;
        };
        OpenInApp.enable = true;
        PermissionsViewer.enabled = true;
        petpet.enabled = true;
        QuickReply.enabled = true;
        ReverseImageSearch.enabled = true;
        SendTimestamps.enabled = true;
        ShikiCodeblocks.enabled = true;
        ShowConnections.enabled = true;
        ShowMeYourName = {
          enabled = true;
          mode = "nick-user";
          friendNicknames = "fallback";
        };
        SilentTyping.enabled = true;
        TypingIndicator.enabled = true;
        ThemeAttributes.enabled = true;
        TypingTweaks.enabled = true;
        Unindent.enabled = true;
        ValidReply.enabled = true;
        ValidUser.enabled = true;
        YoutubeAdblock.enabled = true;
      };
    };
    # vencord.themes = [ ];
    package = pkgs.vesktop;
  };
}
