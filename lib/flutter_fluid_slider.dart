import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// A fluid design slider that works just like the [Slider] material widget.
///
/// Used to select from a range of values.
///
/// The fluid slider will be disabled if [onChanged] is null.
///
/// By default, a fluid slider will be as wide as possible, with a height of
/// 60.0. When given unbounded constraints, it will attempt to make itself
/// 200.0 wide.
class FluidSlider extends StatefulWidget {
  /// Creates a fluid slider.
  ///
  /// * [value] determines currently selected value for this slider.
  /// * [onChanged] is called while the user is selecting a new value for the
  ///   slider.
  /// * [onChangeStart] is called when the user starts to select a new value
  ///   for the slider.
  /// * [onChangeEnd] is called when the user is done selecting a new value for
  ///   the slider.
  const FluidSlider({
    super.key,
    required this.value,
    this.min = 0.0,
    this.max = 1.0,
    this.start,
    this.end,
    this.onChanged,
    this.labelsTextStyle,
    this.valueTextStyle,
    this.onChangeStart,
    this.onChangeEnd,
    this.sliderColor,
    this.thumbColor,
    this.mapValueToString,
    this.showDecimalValue = false,
    this.thumbDiameter,
  })  : assert(min <= max),
        assert(value >= min && value <= max);

  /// The currently selected value for this slider.
  ///
  /// The slider's thumb is drawn at a position that corresponds to this value.
  final double value;

  /// The minimum value the user can select.
  ///
  /// Defaults to 0.0. Must be less than or equal to [max].
  final double min;

  /// The maximum value the user can select.
  ///
  /// Defaults to 1.0. Must be greater than or equal to [min].
  final double max;

  /// The widget to be displayed as the min label.
  ///
  /// If not provided, the [min] value is displayed as text.
  final Widget? start;

  /// The widget to be displayed as the max label.
  ///
  /// If not provided, the [max] value is displayed as text.
  final Widget? end;

  /// Called during a drag when the user is selecting a new value for the
  /// slider by dragging.
  ///
  /// The slider passes the new value to the callback but does not actually
  /// change state until the parent widget rebuilds the slider with the new
  /// value.
  ///
  /// If null, the slider will be displayed as disabled.
  final ValueChanged<double>? onChanged;

  /// Called when the user starts selecting a new value for the slider.
  ///
  /// The value passed will be the last [value] that the slider had before the
  /// change began.
  final ValueChanged<double>? onChangeStart;

  /// Called when the user is done selecting a new value for the slider.
  final ValueChanged<double>? onChangeEnd;

  /// The styling of the min and max text that gets displayed on the slider.
  final TextStyle? labelsTextStyle;

  /// The styling of the current value text that gets displayed on the slider.
  final TextStyle? valueTextStyle;

  /// The color of the slider.
  ///
  /// If not provided, the ancestor [Theme]'s [ThemeData.primaryColor] is used.
  final Color? sliderColor;

  /// The color of the thumb.
  ///
  /// If not provided, [Colors.white] is used.
  final Color? thumbColor;

  /// Whether to display the first decimal value of the slider value.
  ///
  /// Defaults to false.
  final bool showDecimalValue;

  /// Callback function to map the double values to String texts.
  ///
  /// If null, the value is converted to String based on [showDecimalValue].
  final String Function(double)? mapValueToString;

  /// The diameter of the thumb. It is also the height of the slider.
  ///
  /// Defaults to 60.0.
  final double? thumbDiameter;

  @override
  State<FluidSlider> createState() => _FluidSliderState();
}

class _FluidSliderState extends State<FluidSlider>
    with SingleTickerProviderStateMixin {
  late double _sliderWidth;
  double _currX = 0.0;
  late final AnimationController _animationController;
  late final CurvedAnimation _thumbAnimation;
  late final double _thumbDiameter;

  @override
  void initState() {
    super.initState();
    _thumbDiameter = widget.thumbDiameter ?? 60.0;
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _thumbAnimation = CurvedAnimation(
      curve: Curves.bounceOut,
      parent: _animationController,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Offset _getGlobalToLocal(Offset globalPosition) {
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    return renderBox.globalToLocal(globalPosition);
  }

  void _onHorizontalDragDown(DragDownDetails details) {
    if (_isInteractive) {
      _animationController.forward();
    }
  }

  void _onHorizontalDragStart(DragStartDetails details) {
    if (_isInteractive) {
      if (widget.onChangeStart != null) {
        _handleDragStart(widget.value);
      }
      _currX = _getGlobalToLocal(details.globalPosition).dx / _sliderWidth;
    }
  }

  void _onHorizontalDragUpdate(DragUpdateDetails details) {
    if (_isInteractive) {
      final double valueDelta = (details.primaryDelta ?? 0.0) / _sliderWidth;
      _currX += valueDelta;

      _handleChanged(_clamp(_currX));
    }
  }

  void _onHorizontalDragEnd(DragEndDetails details) {
    if (_isInteractive && widget.onChangeEnd != null) {
      _handleDragEnd(_clamp(_currX));
    }
    _currX = 0.0;
    _animationController.reverse();
  }

  void _onHorizontalDragCancel() {
    if (_isInteractive && widget.onChangeEnd != null) {
      _handleDragEnd(_clamp(_currX));
    }
    _currX = 0.0;
    _animationController.reverse();
  }

  double _clamp(double value) => value.clamp(0.0, 1.0);

  void _handleChanged(double value) {
    final ValueChanged<double>? onChanged = widget.onChanged;
    if (onChanged == null) {
      return;
    }

    final double lerpValue = _lerp(value);
    if (lerpValue != widget.value) {
      onChanged(lerpValue);
    }
  }

  void _handleDragStart(double value) {
    widget.onChangeStart?.call(value);
  }

  void _handleDragEnd(double value) {
    widget.onChangeEnd?.call(_lerp(value));
  }

  // Returns a number between min and max, proportional to value, which must
  // be between 0.0 and 1.0.
  double _lerp(double value) {
    assert(value >= 0.0);
    assert(value <= 1.0);
    return value * (widget.max - widget.min) + widget.min;
  }

  // Returns a number between 0.0 and 1.0, given a value between min and max.
  double _unlerp(double value) {
    assert(value <= widget.max);
    assert(value >= widget.min);
    return widget.max > widget.min
        ? (value - widget.min) / (widget.max - widget.min)
        : 0.0;
  }

  Color get _sliderColor => _isInteractive
      ? (widget.sliderColor ?? Theme.of(context).primaryColor)
      : Colors.grey;

  Color get _thumbColor =>
      _isInteractive ? (widget.thumbColor ?? Colors.white) : Colors.grey[300]!;

  bool get _isInteractive => widget.onChanged != null;

  TextStyle _currentValTextStyle(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final TextStyle defaultStyle =
        (widget.showDecimalValue ? textTheme.titleSmall : textTheme.titleMedium)
                ?.copyWith(fontWeight: FontWeight.bold) ??
            const TextStyle(fontWeight: FontWeight.bold);

    return widget.valueTextStyle ?? defaultStyle;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        const double thumbPadding = 8.0;
        final double thumbPosFactor = _unlerp(widget.value);

        // Used to compute thumb position and drag delta.
        _sliderWidth = constraints.hasBoundedWidth ? constraints.maxWidth : 200;

        final double remainingWidth =
            _sliderWidth - _thumbDiameter - 2 * thumbPadding;

        final double thumbPositionLeft =
            lerpDouble(thumbPadding, remainingWidth, thumbPosFactor)!;
        final double thumbPositionRight =
            lerpDouble(remainingWidth, thumbPadding, thumbPosFactor)!;

        final RelativeRect beginRect = RelativeRect.fromLTRB(
          thumbPositionLeft,
          0.0,
          thumbPositionRight,
          0.0,
        );

        final double poppedPosition = _thumbDiameter + 5;
        final RelativeRect endRect = RelativeRect.fromLTRB(
          thumbPositionLeft,
          -poppedPosition,
          thumbPositionRight,
          poppedPosition,
        );

        final Animation<RelativeRect> thumbPosition = RelativeRectTween(
          begin: beginRect,
          end: endRect,
        ).animate(_thumbAnimation);

        return Container(
          width: _sliderWidth,
          height: _thumbDiameter,
          decoration: BoxDecoration(
            color: _sliderColor,
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(10.0),
              right: Radius.circular(10.0),
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: <Widget>[
              _MinMaxLabels(
                textStyle: widget.labelsTextStyle,
                alignment: Alignment.centerLeft,
                child: widget.start,
                value: widget.min,
                padding: const EdgeInsets.only(left: 15.0),
              ),
              _MinMaxLabels(
                textStyle: widget.labelsTextStyle,
                alignment: Alignment.centerRight,
                child: widget.end,
                value: widget.max,
                padding: const EdgeInsets.only(right: 15.0),
              ),
              PositionedTransition(
                rect: thumbPosition,
                child: CustomPaint(
                  painter: _ThumbSplashPainter(
                    showContact: _animationController,
                    thumbPadding: thumbPadding,
                    splashColor: _sliderColor,
                  ),
                  child: GestureDetector(
                    onHorizontalDragCancel: _onHorizontalDragCancel,
                    onHorizontalDragDown: _onHorizontalDragDown,
                    onHorizontalDragStart: _onHorizontalDragStart,
                    onHorizontalDragUpdate: _onHorizontalDragUpdate,
                    onHorizontalDragEnd: _onHorizontalDragEnd,
                    child: Container(
                      width: _thumbDiameter,
                      height: _thumbDiameter,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _sliderColor,
                      ),
                      alignment: Alignment.center,
                      child: Container(
                        width: 0.75 * _thumbDiameter,
                        height: 0.75 * _thumbDiameter,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _thumbColor,
                        ),
                        child: Center(
                          child: Text(
                            widget.mapValueToString != null
                                ? widget.mapValueToString!(widget.value)
                                : widget.showDecimalValue
                                    ? widget.value.toStringAsFixed(1)
                                    : widget.value.toInt().toString(),
                            style: _currentValTextStyle(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ThumbSplashPainter extends CustomPainter {
  const _ThumbSplashPainter({
    required this.thumbPadding,
    required this.showContact,
    required this.splashColor,
  });

  // This is passed to calculate and compensate the value of x for drawing the
  // sticky fluid.
  final double thumbPadding;
  final Animation<double> showContact;
  final Color splashColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (showContact.value >= 0.5) {
      final Offset center = Offset(size.width / 2, size.height / 2);

      final Path path = Path()
        ..moveTo(-0.0, size.height + 6.0)
        ..quadraticBezierTo(center.dx, size.height, thumbPadding / 2, center.dy)
        ..lineTo(size.width - thumbPadding / 2, center.dy)
        ..quadraticBezierTo(
          center.dx,
          size.height,
          size.width + 0.0,
          size.height + 6.0,
        )
        ..close();

      canvas.drawPath(path, Paint()..color = splashColor);
    }
  }

  @override
  bool shouldRepaint(covariant _ThumbSplashPainter oldDelegate) {
    return oldDelegate.showContact.value != showContact.value ||
        oldDelegate.splashColor != splashColor ||
        oldDelegate.thumbPadding != thumbPadding;
  }
}

class _MinMaxLabels extends StatelessWidget {
  const _MinMaxLabels({
    required this.alignment,
    required this.padding,
    required this.value,
    this.textStyle,
    this.child,
  });

  final Alignment alignment;
  final TextStyle? textStyle;
  final Widget? child;
  final double value;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Align(
        alignment: alignment,
        child: child ??
            Text(
              value.toInt().toString(),
              style: textStyle ?? Theme.of(context).primaryTextTheme.titleSmall,
            ),
      ),
    );
  }
}
