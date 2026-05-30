import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../models/content_block.dart';

class ResolvedImageLayout {
  final double width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  const ResolvedImageLayout({
    required this.width,
    required this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });
}

ResolvedImageLayout resolveImageLayout({
  required double contentWidth,
  required Size? naturalSize,
  required double? declaredWidth,
  required double? declaredHeight,
  required CssLength? cssWidth,
  required CssLength? cssHeight,
  required CssLength? cssMaxWidth,
  required CssLength? cssMaxHeight,
  ReaderTextAlign? alignment,
  double maxImageWidthRatio = 1.0,
  double fontSize = 16,
}) {
  final safeContentWidth = contentWidth.isFinite && contentWidth > 0
      ? contentWidth
      : 720.0;
  final ratioLimit = maxImageWidthRatio.isFinite
      ? maxImageWidthRatio.clamp(0.1, 1.0).toDouble()
      : 1.0;
  final contentLimit = safeContentWidth * ratioLimit;
  final cssMaxWidthValue = _resolveLength(
    cssMaxWidth,
    percentBase: safeContentWidth,
    fontSize: fontSize,
  );
  final maxWidth = math.max(
    1.0,
    math.min(contentLimit, cssMaxWidthValue ?? contentLimit),
  );

  final naturalAspect = _aspectRatio(naturalSize?.width, naturalSize?.height);
  final declaredAspect = _aspectRatio(declaredWidth, declaredHeight);
  final aspectRatio = naturalAspect ?? declaredAspect;

  final cssWidthValue = _resolveLength(
    cssWidth,
    percentBase: safeContentWidth,
    fontSize: fontSize,
  );
  final resolvedWidth =
      cssWidthValue ?? declaredWidth ?? naturalSize?.width ?? safeContentWidth;

  var width = resolvedWidth.clamp(1.0, maxWidth).toDouble();
  double? height;

  if (aspectRatio != null) {
    height = width / aspectRatio;
  } else {
    final explicitHeight = _resolveLength(
      cssHeight,
      percentBase: safeContentWidth,
      fontSize: fontSize,
    );
    height = explicitHeight ?? declaredHeight;
  }

  final cssMaxHeightValue = _resolveLength(
    cssMaxHeight,
    percentBase: safeContentWidth,
    fontSize: fontSize,
  );
  if (height != null &&
      cssMaxHeightValue != null &&
      cssMaxHeightValue > 0 &&
      height > cssMaxHeightValue) {
    height = cssMaxHeightValue;
    if (aspectRatio != null) {
      width = math.min(width, height * aspectRatio);
    }
  }

  return ResolvedImageLayout(
    width: width,
    height: height,
    alignment: _alignmentFor(alignment),
  );
}

double? _resolveLength(
  CssLength? length, {
  required double percentBase,
  required double fontSize,
}) {
  final value = length?.resolve(percentBase: percentBase, fontSize: fontSize);
  if (value == null || !value.isFinite || value <= 0) return null;
  return value;
}

double? _aspectRatio(double? width, double? height) {
  if (width == null || height == null || width <= 0 || height <= 0) {
    return null;
  }
  return (width / height).clamp(0.05, 20.0).toDouble();
}

Alignment _alignmentFor(ReaderTextAlign? alignment) {
  return switch (alignment) {
    ReaderTextAlign.end => Alignment.centerRight,
    ReaderTextAlign.start => Alignment.centerLeft,
    _ => Alignment.center,
  };
}
