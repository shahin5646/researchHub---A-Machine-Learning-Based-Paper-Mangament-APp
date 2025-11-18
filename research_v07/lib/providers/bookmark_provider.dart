import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class BookmarkProvider with ChangeNotifier {
  static const String _bookmarksKey = 'bookmarked_papers';
  final SharedPreferences _prefs;
  Set<String> _bookmarkedPapers = {};

  BookmarkProvider(this._prefs) {
    _loadBookmarks();
  }

  Set<String> get bookmarkedPapers => _bookmarkedPapers;

  bool isBookmarked(String paperId) {
    return _bookmarkedPapers.contains(paperId);
  }

  Future<void> _loadBookmarks() async {
    final bookmarksJson = _prefs.getString(_bookmarksKey);
    if (bookmarksJson != null) {
      final List<dynamic> bookmarksList = json.decode(bookmarksJson);
      _bookmarkedPapers = bookmarksList.cast<String>().toSet();
      notifyListeners();
    }
  }

  Future<void> _saveBookmarks() async {
    final bookmarksList = _bookmarkedPapers.toList();
    await _prefs.setString(_bookmarksKey, json.encode(bookmarksList));
  }

  Future<void> toggleBookmark(String paperId) async {
    if (_bookmarkedPapers.contains(paperId)) {
      _bookmarkedPapers.remove(paperId);
    } else {
      _bookmarkedPapers.add(paperId);
    }
    await _saveBookmarks();
    notifyListeners();
  }

  Future<void> addBookmark(String paperId) async {
    if (!_bookmarkedPapers.contains(paperId)) {
      _bookmarkedPapers.add(paperId);
      await _saveBookmarks();
      notifyListeners();
    }
  }

  Future<void> removeBookmark(String paperId) async {
    if (_bookmarkedPapers.contains(paperId)) {
      _bookmarkedPapers.remove(paperId);
      await _saveBookmarks();
      notifyListeners();
    }
  }

  Future<void> clearAllBookmarks() async {
    _bookmarkedPapers.clear();
    await _saveBookmarks();
    notifyListeners();
  }

  int get bookmarkCount => _bookmarkedPapers.length;
}
