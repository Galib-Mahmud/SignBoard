import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/post_model.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class PostCard extends StatefulWidget {
  final PostModel post;
  final VoidCallback? onSaveChanged;
  final VoidCallback? onDelete;

  const PostCard({
    super.key,
    required this.post,
    this.onSaveChanged,
    this.onDelete,
  });


  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  bool _isExpanded = false;
  bool _isSaving = false;

  Future<void> _launchWhatsApp() async {
    final phone = widget.post.contactWhatsapp.replaceAll(RegExp(r'[^0-9]'), '');
    final message = Uri.encodeComponent(
      'Hi, I am interested in your SignBoard post: "${widget.post.title}"',
    );
    final url = Uri.parse('https://wa.me/$phone?text=$message');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $phone')),
        );
      }
    }
  }

  Future<void> _launchGoRoute() async {
    final lat = widget.post.latitude;
    final lng = widget.post.longitude;
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Maps')),
        );
      }
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaving) return;
    setState(() => _isSaving = true);

    try {
      final newStatus = await ApiService().toggleSavePost(widget.post.id);
      setState(() {
        widget.post.isSaved = newStatus;
      });
      widget.onSaveChanged?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus ? 'Saved to your bookmarks' : 'Removed from bookmarks',
            ),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sign in required to save posts')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final post = widget.post;
    final hasStructuredData = post.structuredData.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.bgSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderLight, width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Card Header: Category & Distance & Bookmark / Delete
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.categoryName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryDark,
                          letterSpacing: -0.2,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (post.formattedDistance.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '•  ${post.formattedDistance}',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w500,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.onDelete != null) ...[
                IconButton(
                  onPressed: widget.onDelete,
                  iconSize: 22,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'Delete post',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.dangerRed,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              IconButton(
                onPressed: _toggleSave,
                iconSize: 24,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: post.isSaved ? 'Remove bookmark' : 'Bookmark post',
                icon: Icon(
                  post.isSaved ? Icons.bookmark : Icons.bookmark_border,
                  color: post.isSaved ? AppTheme.accentBlue : AppTheme.primaryDark,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // 2. Post Title (if distinct from Category)
          Text(
            post.title,
            style: const TextStyle(
              fontSize: 16.5,
              fontWeight: FontWeight.w700,
              color: AppTheme.primaryDark,
              height: 1.35,
              letterSpacing: -0.2,
            ),
          ),

          const SizedBox(height: 6),

          // 3. Description with 'more' / 'less' toggle
          if (post.description.isNotEmpty) ...[
            Text(
              post.description,
              maxLines: _isExpanded ? 100 : 3,
              overflow: _isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w400,
                color: Color(0xFF334155), // Slate-700 High Contrast Text
                height: 1.55,
              ),
            ),
            if (post.description.length > 70) ...[
              GestureDetector(
                onTap: () {
                  setState(() => _isExpanded = !_isExpanded);
                },
                child: Padding(
                  padding: const EdgeInsets.only(top: 4, bottom: 4),
                  child: Text(
                    _isExpanded ? 'Show less' : 'Read more',
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      color: AppTheme.accentBlue,
                    ),
                  ),
                ),
              ),
            ],
          ],

          // 4. Structured Data Chips / Key Parameters
          if (hasStructuredData) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: post.structuredData.entries.map((entry) {
                final key = entry.key
                    .replaceAll('_', ' ')
                    .split(' ')
                    .map((str) => str.isNotEmpty
                        ? '${str[0].toUpperCase()}${str.substring(1)}'
                        : '')
                    .join(' ');
                final val = entry.value.toString();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9), // Slate-100
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1), // Slate-300
                  ),
                  child: Text(
                    '$key: $val',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B), // Slate-800
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // 5. Address / Location
          if (post.address.isNotEmpty || post.city.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppTheme.textSecondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    [post.address, post.city]
                        .where((s) => s.isNotEmpty)
                        .join(', '),
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],

          const SizedBox(height: 16),

          // 6. Actions: WhatsApp and Go route Buttons (exact Figma styling)
          Row(
            children: [
              // WhatsApp Button
              Material(
                color: AppTheme.whatsAppGreen,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: _launchWhatsApp,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: Colors.white,
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'WhatsApp',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 12),

              // Go route Button
              Material(
                color: AppTheme.goRouteBg,
                borderRadius: BorderRadius.circular(10),
                child: InkWell(
                  onTap: _launchGoRoute,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.navigation_outlined,
                          color: AppTheme.primaryDark,
                          size: 17,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Go route',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
