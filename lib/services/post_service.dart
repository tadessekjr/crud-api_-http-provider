import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/post_model.dart';

class PostService {
  static const String baseUrl = 'https://jsonplaceholder.typicode.com';
  static const String _postsKey = 'saved_posts';
  
  final http.Client _client = http.Client();

  // Load posts from local storage
  Future<List<PostModel>> getPosts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? postsJson = prefs.getString(_postsKey);
      
      if (postsJson != null) {
        List<dynamic> decoded = json.decode(postsJson);
        return decoded.map((json) => PostModel.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      print('Error loading from local: $e');
      return [];
    }
  }

  // Save posts to local storage
  Future<void> _savePosts(List<PostModel> posts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String postsJson = json.encode(posts.map((p) => p.toJson()).toList());
      await prefs.setString(_postsKey, postsJson);
    } catch (e) {
      print('Error saving posts: $e');
    }
  }

  // Create post - save locally and try API
  Future<PostModel> createPost(PostModel post) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/posts'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': post.userId,
              'title': post.title,
              'body': post.body,
            }),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        final apiPost = PostModel.fromJson(json.decode(response.body));
        
        // Save locally after successful API call
        final currentPosts = await getPosts();
        currentPosts.insert(0, apiPost);
        await _savePosts(currentPosts);
        return apiPost;
      }
      throw Exception('Failed to create post');
    } catch (e) {
      // If API fails, still save locally with temporary ID
      final tempPost = post.copyWith(id: DateTime.now().millisecondsSinceEpoch);
      final currentPosts = await getPosts();
      currentPosts.insert(0, tempPost);
      await _savePosts(currentPosts);
      return tempPost;
    }
  }

  // Update post - save locally and try API
  Future<PostModel> updatePost(PostModel post) async {
    try {
      await _client
          .put(
            Uri.parse('$baseUrl/posts/${post.id}'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'userId': post.userId,
              'title': post.title,
              'body': post.body,
            }),
          )
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      print('API update failed: $e');
    }
    
    // Always update locally
    final currentPosts = await getPosts();
    final index = currentPosts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      currentPosts[index] = post;
      await _savePosts(currentPosts);
    }
    return post;
  }

  // Delete post - remove locally and try API
  Future<void> deletePost(int id) async {
    try {
      await _client
          .delete(Uri.parse('$baseUrl/posts/$id'))
          .timeout(const Duration(seconds: 30));
    } catch (e) {
      print('API delete failed: $e');
    }
    
    // Always delete locally
    final currentPosts = await getPosts();
    currentPosts.removeWhere((post) => post.id == id);
    await _savePosts(currentPosts);
  }

  void dispose() {
    _client.close();
  }
}