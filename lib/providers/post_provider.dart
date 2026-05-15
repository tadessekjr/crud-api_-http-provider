import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/post_service.dart';

class PostProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  List<PostModel> _posts = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _successMessage = '';
  String _searchQuery = '';
  final Map<int, int> _viewCounts = {};

  List<PostModel> get posts => _searchQuery.isEmpty ? _posts : _filteredPosts();
  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  String get successMessage => _successMessage;
  String get searchQuery => _searchQuery;

  int getViewCount(int postId) => _viewCounts[postId] ?? 0;

  void incrementViewCount(int postId) {
    _viewCounts[postId] = (_viewCounts[postId] ?? 0) + 1;
    notifyListeners();
  }

  List<PostModel> _filteredPosts() {
    return _posts.where((post) =>
        post.title.toLowerCase().contains(_searchQuery) ||
        post.body.toLowerCase().contains(_searchQuery)).toList();
  }

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  Future<void> loadPosts() async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      _posts = await _postService.getPosts();
      _searchQuery = '';
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPost(PostModel post) async {
    _isLoading = true;
    notifyListeners();

    final oldList = List<PostModel>.from(_posts);
    _posts.insert(0, post);
    notifyListeners();

    try {
      final newPost = await _postService.createPost(post);
      final index = _posts.indexWhere((p) => p.id == post.id);
      if (index != -1) {
        _posts[index] = newPost;
      }
      _successMessage = 'Post added successfully!';
      _errorMessage = '';
    } catch (e) {
      _posts = oldList;
      _errorMessage = 'Failed to add post: ${e.toString()}';
      _successMessage = '';
    } finally {
      _isLoading = false;
      notifyListeners();
      _clearSuccessAfterDelay();
    }
  }

  Future<void> updatePost(PostModel post) async {
    _isLoading = true;
    notifyListeners();

    final oldList = List<PostModel>.from(_posts);
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts[index] = post;
      notifyListeners();
    }

    try {
      await _postService.updatePost(post);
      _successMessage = 'Post updated successfully!';
      _errorMessage = '';
    } catch (e) {
      _posts = oldList;
      _errorMessage = 'Failed to update post: ${e.toString()}';
      _successMessage = '';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
      _clearSuccessAfterDelay();
    }
  }

  Future<void> deletePost(int id) async {
    _isLoading = true;
    notifyListeners();

    final oldList = List<PostModel>.from(_posts);
    _posts.removeWhere((post) => post.id == id);
    notifyListeners();

    try {
      await _postService.deletePost(id);
      _successMessage = 'Post deleted successfully!';
      _errorMessage = '';
    } catch (e) {
      _posts = oldList;
      _errorMessage = 'Failed to delete post: ${e.toString()}';
      _successMessage = '';
      notifyListeners();
    } finally {
      _isLoading = false;
      notifyListeners();
      _clearSuccessAfterDelay();
    }
  }

  void _clearSuccessAfterDelay() {
    Future.delayed(const Duration(seconds: 3), () {
      _successMessage = '';
      notifyListeners();
    });
  }
}