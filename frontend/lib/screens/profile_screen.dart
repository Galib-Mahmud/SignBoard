import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../widgets/post_card.dart';
import 'auth_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _api = ApiService();
  bool _isLoadingMyPosts = false;
  List<PostModel> _myPosts = [];
  bool _showingMyPosts = false;

  @override
  void initState() {
    super.initState();
    _fetchMyPosts();
  }

  Future<void> _fetchMyPosts() async {
    setState(() => _isLoadingMyPosts = true);
    try {
      final posts = await _api.getMyPosts();
      if (mounted) {
        setState(() {
          _myPosts = posts;
          _isLoadingMyPosts = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoadingMyPosts = false);
      }
    }
  }

  void _showSubscriptionDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.borderLight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'SignBoard Subscriptions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'COMING SOON',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFB45309),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Unlock advanced visibility, verified business badges, and unlimited featured listings.',
                style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
              ),
              const SizedBox(height: 20),

              // Pro Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.goRouteBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryDark, width: 1.2),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pro Member',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryDark,
                          ),
                        ),
                        Text(
                          '\$9.99 / mo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.accentBlue,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text('• Top search priority across category results'),
                    SizedBox(height: 4),
                    Text('• Direct WhatsApp verified badge'),
                    SizedBox(height: 4),
                    Text('• Real-time analytics on map routes & card views'),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Notify Me When Available'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showServerConfigDialog() {
    final controller = TextEditingController(text: _api.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.dns_rounded, color: AppTheme.accentBlue, size: 22),
            SizedBox(width: 8),
            Text(
              'Server Base URL',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure backend target for physical phone or Render deployment:',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'https://signboard-backend.onrender.com/api',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newUrl = controller.text;
              Navigator.pop(ctx);
              await _api.setCustomBaseUrl(newUrl);
              if (mounted) {
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Server updated: ${_api.baseUrl}')),
                );
              }
            },
            child: const Text('Save & Connect'),
          ),

        ],
      ),
    );
  }

  void _showAboutDialog() {

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppTheme.bgSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.signpost_rounded, color: AppTheme.primaryDark),
              SizedBox(width: 10),
              Text('About SignBoard'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Version 1.0.0 (Production Scalable)',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              SizedBox(height: 8),
              Text(
                'SignBoard is a high-performance hyperlocal directory platform designed to handle 1,000,000+ concurrent requests using indexed spatial queries, structured category standards, and zero image bloat.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
              SizedBox(height: 12),
              Text(
                '• Backend: Django 6 + DRF + Haversine Indexing\n• Frontend: Flutter 3.44 Mobile/Desktop\n• Location: Precision GPS coordinate routing',
                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.bgSurface,
        title: const Text('Log out'),
        content: const Text('Are you sure you want to log out of SignBoard?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Log out',
              style: TextStyle(color: AppTheme.dangerRed, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _api.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _api.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgSurface,
      appBar: AppBar(
        backgroundColor: AppTheme.bgSurface,
        title: Text(
          _showingMyPosts ? 'My Posts (${_myPosts.length})' : 'Profile',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryDark,
          ),
        ),
        leading: _showingMyPosts
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _showingMyPosts = false),
              )
            : null,
      ),
      body: _showingMyPosts
          ? _buildMyPostsView()
          : ListView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              children: [
                // Header: Profile photo & Identity
                Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: AppTheme.goRouteBg,
                      backgroundImage: user?.avatarUrl != null && user!.avatarUrl!.isNotEmpty
                          ? NetworkImage(user.avatarUrl!)
                          : null,
                      child: user?.avatarUrl == null || user!.avatarUrl!.isEmpty
                          ? const Icon(Icons.person, size: 36, color: AppTheme.primaryDark)
                          : null,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.displayName ?? 'Maya Johnson',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            user?.email ?? 'maya.j@example.com',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 16),

                // Menu items matching Figma layout:
                // 1. All Post
                _buildMenuItem(
                  icon: Icons.post_add_rounded,
                  title: 'All Post',
                  subtitle: '${_myPosts.length} posts created',
                  onTap: () {
                    setState(() => _showingMyPosts = true);
                    _fetchMyPosts();
                  },
                ),


                // 2. Subscription
                _buildMenuItem(
                  icon: Icons.credit_card_outlined,
                  title: 'Subscription',
                  subtitle: 'Manage pro features & visibility',
                  onTap: _showSubscriptionDialog,
                ),

                // 3. Server Configuration (Physical Phone / Render)
                _buildMenuItem(
                  icon: Icons.dns_outlined,
                  title: 'Server Configuration',
                  subtitle: _api.baseUrl,
                  onTap: _showServerConfigDialog,
                ),

                // 4. About
                _buildMenuItem(
                  icon: Icons.help_outline_rounded,
                  title: 'About',
                  subtitle: 'Learn more about SignBoard',
                  onTap: _showAboutDialog,
                ),

                const SizedBox(height: 16),
                const Divider(height: 1, color: AppTheme.borderLight),
                const SizedBox(height: 16),


                // 4. Log out
                _buildMenuItem(
                  icon: Icons.logout_rounded,
                  title: 'Log out',
                  titleColor: AppTheme.dangerRed,
                  iconColor: AppTheme.dangerRed,
                  onTap: _logout,
                ),
              ],
            ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color titleColor = AppTheme.primaryDark,
    Color iconColor = AppTheme.primaryDark,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: AppTheme.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppTheme.borderLight, width: 1.2),
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          leading: Icon(icon, color: iconColor, size: 24),
          title: Text(
            title,
            style: TextStyle(
              fontSize: 15.5,
              fontWeight: FontWeight.w700,
              color: titleColor,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppTheme.textSecondary,
                  ),
                )
              : null,
          trailing: const Icon(
            Icons.chevron_right_rounded,
            size: 22,
            color: AppTheme.textMuted,
          ),
        ),
      ),
    );
  }


  Future<void> _deleteSinglePost(PostModel post) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.delete_outline_rounded, color: AppTheme.dangerRed, size: 24),
            SizedBox(width: 8),
            Text(
              'Delete Post',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Are you sure you want to permanently delete this post?',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.bgCanvas,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                post.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(fontSize: 12, color: AppTheme.dangerRed),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _api.deletePost(post.id);
        setState(() {
          _myPosts.removeWhere((p) => p.id == post.id);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Post deleted successfully'),
              backgroundColor: AppTheme.primaryDark,
              duration: Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete post: $e'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteAllPosts() async {
    if (_myPosts.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppTheme.dangerRed, size: 26),
            SizedBox(width: 8),
            Text(
              'Delete All Posts?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Text(
          'You are about to permanently delete all ${_myPosts.length} posts from your account. This action cannot be reversed.\n\nAre you sure you want to proceed?',
          style: const TextStyle(fontSize: 14, height: 1.4, color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.dangerRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete All Posts'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoadingMyPosts = true);
      try {
        final count = await _api.deleteAllMyPosts();
        setState(() {
          _myPosts.clear();
          _isLoadingMyPosts = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Successfully deleted $count posts'),
              backgroundColor: AppTheme.primaryDark,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } catch (e) {
        setState(() => _isLoadingMyPosts = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete posts: $e'),
              backgroundColor: AppTheme.dangerRed,
            ),
          );
        }
      }
    }
  }

  Widget _buildMyPostsView() {
    if (_isLoadingMyPosts) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    if (_myPosts.isEmpty) {
      return RefreshIndicator(
        onRefresh: _fetchMyPosts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          children: [
            const SizedBox(height: 40),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.post_add_rounded, size: 54, color: AppTheme.textMuted),
                  const SizedBox(height: 14),
                  const Text(
                    'You haven\'t published any posts yet',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Tap the "+" tab below to publish your first post.',
                    style: TextStyle(fontSize: 13, color: AppTheme.textSecondary),
                  ),
                  const SizedBox(height: 20),
                  OutlinedButton.icon(
                    onPressed: _fetchMyPosts,
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    label: const Text('Refresh Posts'),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Action Bar: Count & Refresh & Delete All Button
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppTheme.bgSurface,
            border: Border(bottom: BorderSide(color: AppTheme.borderLight, width: 1)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_myPosts.length} Active Posts',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textSecondary,
                ),
              ),
              Row(
                children: [
                  // Instant Refresh Button
                  InkWell(
                    onTap: _fetchMyPosts,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEFF6FF),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 16, color: AppTheme.accentBlue),
                          SizedBox(width: 4),
                          Text(
                            'Refresh',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.accentBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Delete All Button
                  InkWell(
                    onTap: _deleteAllPosts,
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.delete_sweep_rounded, size: 16, color: AppTheme.dangerRed),
                          SizedBox(width: 4),
                          Text(
                            'Delete All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.dangerRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Posts List with Pull-to-Refresh
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchMyPosts,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _myPosts.length,
              itemBuilder: (context, index) {
                final post = _myPosts[index];
                return AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: PostCard(
                    key: ValueKey(post.id),
                    post: post,
                    onSaveChanged: _fetchMyPosts,
                    onDelete: () => _deleteSinglePost(post),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

}

