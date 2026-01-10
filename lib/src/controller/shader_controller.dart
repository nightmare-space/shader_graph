/// 用来控制 shader 动画播放状态的控制器。
///
/// A controller to manage shader animation playback state.
class ShaderController {
  bool _isPaused = false;

  /// 当前动画是否处于暂停状态。
  ///
  /// Whether the animation is currently paused.
  bool get isPaused => _isPaused;

  /// 暂停动画播放。
  ///
  /// Pauses the animation.
  void pause() {
    _isPaused = true;
  }

  /// 恢复动画播放。
  ///
  /// Resumes the animation.
  void resume() {
    _isPaused = false;
  }

  /// 切换播放和暂停状态。
  ///
  /// Toggles between play and pause states.
  void toggle() {
    _isPaused = !_isPaused;
  }
}
