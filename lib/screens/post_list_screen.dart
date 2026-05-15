import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/post_provider.dart';
import '../models/post_model.dart';
import '../widgets/post_card.dart';
import '../widgets/add_post_dialog.dart';
import 'post_detail_screen.dart';

class PostListScreen extends StatelessWidget {
  const PostListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Post Manager Pro'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<PostProvider>().loadPosts(),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search posts...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.2),
              ),
              onChanged: (query) {
                context.read<PostProvider>().updateSearchQuery(query);
              },
            ),
          ),
        ),
      ),
      body: Consumer<PostProvider>(
        builder: (context, provider, child) {
          // Show messages
          if (provider.successMessage.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(provider.successMessage)),
              );
            });
          }
          if (provider.errorMessage.isNotEmpty) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(provider.errorMessage),
                  backgroundColor: Colors.red,
                ),
              );
            });
          }

          if (provider.isLoading && provider.posts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage.isNotEmpty && provider.posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(provider.errorMessage),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => provider.loadPosts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

        if (provider.posts.isEmpty) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.article_outlined, size: 64),
        const SizedBox(height: 16),
        Text(provider.searchQuery.isEmpty ? 'No posts' : 'No matches'),
        const SizedBox(height: 16),
        if (provider.searchQuery.isEmpty)
          ElevatedButton(
            onPressed: () => _showAddPostDialog(context, provider), // ✅ fixed
            child: const Text('Create First Post'),
          ),
      ],
    ),
  );
}

          return RefreshIndicator(
            onRefresh: () => provider.loadPosts(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: provider.posts.length,
              itemBuilder: (context, index) {
                final post = provider.posts[index];
                return CustomPostCard(
                  post: post,
                  viewCount: provider.getViewCount(post.id),
                  onTap: () {
                    provider.incrementViewCount(post.id);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PostDetailScreen(
                          post: post,
                          onView: () => provider.incrementViewCount(post.id),
                        ),
                      ),
                    );
                  },
                  onEdit: () => _showEditPostDialog(context, post, provider),
                  onDelete: () => _showDeleteConfirmation(context, post.id, provider),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPostDialog(context, context.read<PostProvider>()),
        icon: const Icon(Icons.add),
        label: const Text('New Post'),
      ),
    );
  }

  void _showAddPostDialog(BuildContext context, PostProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AddPostDialog(postProvider: provider),
    );
  }

  void _showEditPostDialog(BuildContext context, PostModel post, PostProvider provider) {
    final titleController = TextEditingController(text: post.title);
    final bodyController = TextEditingController(text: post.body);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Post'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: bodyController,
              decoration: const InputDecoration(labelText: 'Body'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final updatedPost = post.copyWith(
                title: titleController.text,
                body: bodyController.text,
              );
              provider.updatePost(updatedPost);
              Navigator.pop(dialogContext);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, int id, PostProvider provider) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Post'),
        content: const Text('This action cannot be undone. Delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deletePost(id);
              Navigator.pop(dialogContext);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}