part of flutter_video_cast;

final AirPlayPlatform _airPlayPlatform = AirPlayPlatform.instance;

/// Widget that displays the AirPlay button.
class AirPlayButton extends StatelessWidget {
  /// Creates a widget displaying a AirPlay button.
<<<<<<< HEAD
  AirPlayButton({
    Key? key,
    this.size = 30.0,
    this.color = Colors.black,
    this.activeColor = Colors.white,
=======
  const AirPlayButton({
    Key? key,
    this.size,
    this.color,
    this.activeColor,
>>>>>>> efc510aa2f891522ece4ffc7e22d9c59bda7aeb7
    this.onRoutesOpening,
    this.onRoutesClosed,
  }) : super(key: key);

  /// The size of the button.
  final double? size;

  /// The color of the button.
  final Color? color;

  /// The color of the button when connected.
  final Color? activeColor;

  /// Called while the AirPlay popup is opening.
  final VoidCallback? onRoutesOpening;

  /// Called when the AirPlay popup has closed.
  final VoidCallback? onRoutesClosed;

  @override
  Widget build(BuildContext context) {
    final defaultColor = color ?? IconTheme.of(context).color;
    final activeDefaultColor = color ?? IconTheme.of(context).color;
    final Map<String, dynamic> args = {
      'red': defaultColor?.red,
      'green': defaultColor?.green,
      'blue': defaultColor?.blue,
      'alpha': defaultColor?.alpha,
      'activeRed': activeDefaultColor?.red,
      'activeGreen': activeDefaultColor?.green,
      'activeBlue': activeDefaultColor?.blue,
      'activeAlpha': activeDefaultColor?.alpha,
    };
    if (Platform.isIOS) {
      final iconSize = size ?? IconTheme.of(context).size;
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: _airPlayPlatform.buildView(args, _onPlatformViewCreated),
      );
    }
    return SizedBox();
  }

  Future<void> _onPlatformViewCreated(int id) async {
    await _airPlayPlatform.init(id);
<<<<<<< HEAD
    if (onRoutesOpening != null) {
      _airPlayPlatform.onRoutesOpening(id: id).listen((_) => onRoutesOpening!());
    }
    if (onRoutesClosed != null) {
      _airPlayPlatform
          .onRoutesClosed(id: id)
          .listen((event) => onRoutesClosed!());
    }
=======
    _airPlayPlatform.onRoutesOpening(id: id).listen((_) => onRoutesOpening?.call());
    _airPlayPlatform.onRoutesClosed(id: id).listen((event) => onRoutesClosed?.call());
>>>>>>> efc510aa2f891522ece4ffc7e22d9c59bda7aeb7
  }
}
