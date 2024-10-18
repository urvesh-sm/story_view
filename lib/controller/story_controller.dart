import 'package:rxdart/rxdart.dart';

enum PlaybackState { pause, play, next, previous }

enum MuteState { muted, unmuted }

/// Controller to sync playback between animated child (story) views. This
/// helps make sure when stories are paused, the animation (gifs/slides) are
/// also paused.
/// Another reason for using the controller is to place the stories on `paused`
/// state when a media is loading.
class StoryController {
  /// Stream that broadcasts the playback state of the stories.
  final playbackNotifier = BehaviorSubject<PlaybackState>();
  final muteNotifier = BehaviorSubject<MuteState>();

  StoryController() {
    muteNotifier.value = MuteState.unmuted;
  }

  /// Notify listeners with a [PlaybackState.pause] state
  void pause() {
    playbackNotifier.add(PlaybackState.pause);
  }

  /// Notify listeners with a [PlaybackState.play] state
  void play() {
    playbackNotifier.add(PlaybackState.play);
  }

  void next() {
    playbackNotifier.add(PlaybackState.next);
  }

  void previous() {
    playbackNotifier.add(PlaybackState.previous);
  }

  void mute() {
    muteNotifier.add(MuteState.muted);
  }

  void unmute() {
    muteNotifier.add(MuteState.unmuted);
  }

  void toggleMute() {
    if (muteNotifier.value == MuteState.muted) {
      unmute();
    } else {
      mute();
    }
  }

  /// Remember to call dispose when the story screen is disposed to close
  /// the notifier stream.
  void dispose() {
    playbackNotifier.close();
    muteNotifier.close();
  }
}
