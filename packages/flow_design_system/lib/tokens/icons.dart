import 'package:flutter/material.dart';

abstract class IconTokens {
  double get sizeSmall;
  double get sizeNormal;
  double get sizeMedium;
  double get sizeLarge;

  IconData get home;
  IconData get library;
  IconData get settings;
  IconData get search;

  IconData get readerChapter;
  IconData get readerDictionary;
  IconData get readerBookmark;
  IconData get readerFontSize;
}

class _DefaultIconTokens implements IconTokens {
  const _DefaultIconTokens();

  @override
  double get sizeSmall => 16;
  @override
  double get sizeNormal => 20;
  @override
  double get sizeMedium => 24;
  @override
  double get sizeLarge => 32;

  @override
  IconData get home => Icons.home_outlined;
  @override
  IconData get library => Icons.library_books_outlined;
  @override
  IconData get settings => Icons.settings_outlined;
  @override
  IconData get search => Icons.search;

  @override
  IconData get readerChapter => Icons.menu_book_outlined;
  @override
  IconData get readerDictionary => Icons.menu_book;
  @override
  IconData get readerBookmark => Icons.bookmark_outline;
  @override
  IconData get readerFontSize => Icons.format_size;
}

const IconTokens defaultIconTokens = _DefaultIconTokens();
