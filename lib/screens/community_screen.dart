import 'package:flutter/material.dart';

import '../models/community_post.dart';
import '../repositories/cleaning_data_repository.dart';
import '../widgets/fairy_image.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({
    required this.dataRepository,
    super.key,
  });

  final CleaningDataRepository dataRepository;

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  late List<CommunityPost> _posts;

  @override
  void initState() {
    super.initState();
    _posts = _defaultPosts;
    _loadPosts();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('청소 자랑',
                      style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  const Text('작은 변화도 함께 보면 더 즐거워요.'),
                ],
              ),
            ),
            const FairyImage(
              size: 68,
              assetPath: '캐릭터/청소요정_진행.png',
            ),
          ],
        ),
        const SizedBox(height: 18),
        FilledButton.icon(
          onPressed: _showAddPostSheet,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('내 청소 자랑하기'),
        ),
        const SizedBox(height: 20),
        for (final post in _posts) ...[
          _CommunityPostCard(post: post),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _loadPosts() async {
    final savedPosts = await widget.dataRepository.loadCommunityPosts();
    if (!mounted || savedPosts == null) {
      return;
    }

    setState(() {
      _posts = savedPosts;
    });
  }

  Future<void> _showAddPostSheet() async {
    final post = await showModalBottomSheet<CommunityPost>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const _AddPostSheet(),
    );

    if (post == null || !mounted) {
      return;
    }

    setState(() {
      _posts = [post, ..._posts];
    });
    await widget.dataRepository.saveCommunityPosts(_posts);
  }
}

const _defaultPosts = [
  CommunityPost(
    id: 'sample-1',
    name: '반짝주방',
    place: '주방',
    message: '미뤄뒀던 냉장고 선반을 전부 닦았어요. 문 열 때마다 기분이 좋아요!',
    likes: 24,
    colorValue: 0xFFFFE9EC,
    iconCodePoint: 0xe33d,
  ),
  CommunityPost(
    id: 'sample-2',
    name: '정리한스푼',
    place: '거실',
    message: '소파 밑까지 청소기 완료. 청소 요정에게 칭찬받을 준비됐어요.',
    likes: 17,
    colorValue: 0xFFFFF4E3,
    iconCodePoint: 0xf1f0,
  ),
  CommunityPost(
    id: 'sample-3',
    name: '오늘도한칸',
    place: '욕실',
    message: '세면대 하나만 닦으려고 했는데 거울까지 끝냈어요!',
    likes: 31,
    colorValue: 0xFFF4E9FF,
    iconCodePoint: 0xe06b,
  ),
];

class _AddPostSheet extends StatefulWidget {
  const _AddPostSheet();

  @override
  State<_AddPostSheet> createState() => _AddPostSheetState();
}

class _AddPostSheetState extends State<_AddPostSheet> {
  final _nameController = TextEditingController(text: '나의청소');
  final _messageController = TextEditingController();
  String _place = '주방';

  @override
  void dispose() {
    _nameController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('청소 자랑하기', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          const Text('오늘 해낸 작은 청소도 충분히 자랑할 만해요.'),
          const SizedBox(height: 16),
          TextField(
            controller: _nameController,
            autofocus: true,
            decoration: const InputDecoration(labelText: '닉네임'),
          ),
          const SizedBox(height: 12),
          DropdownMenu<String>(
            width: double.infinity,
            initialSelection: _place,
            label: const Text('구역'),
            dropdownMenuEntries: const [
              DropdownMenuEntry(value: '주방', label: '주방'),
              DropdownMenuEntry(value: '거실', label: '거실'),
              DropdownMenuEntry(value: '욕실', label: '욕실'),
              DropdownMenuEntry(value: '침실', label: '침실'),
              DropdownMenuEntry(value: '기타', label: '기타'),
            ],
            onSelected: (place) {
              if (place != null) {
                _place = place;
              }
            },
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '자랑 내용',
              hintText: '예: 싱크대 물때를 전부 닦았어요!',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _submit,
            child: const Text('올리기'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    final name = _nameController.text.trim();
    final message = _messageController.text.trim();
    if (name.isEmpty || message.isEmpty) {
      return;
    }

    Navigator.of(context).pop(
      CommunityPost(
        id: 'post-${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        place: _place,
        message: message,
        likes: 0,
        colorValue: 0xFFFFE9EC,
        iconCodePoint: Icons.auto_awesome.codePoint,
      ),
    );
  }
}

class _CommunityPostCard extends StatelessWidget {
  const _CommunityPostCard({required this.post});

  final CommunityPost post;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: post.color,
                  child: Icon(post.icon, color: const Color(0xFF6E4A50)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(
                        post.place,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.more_horiz),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: post.color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(post.icon, size: 48, color: const Color(0xFF9C6A74)),
            ),
            const SizedBox(height: 12),
            Text(post.message),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 20),
                const SizedBox(width: 5),
                Text('${post.likes}'),
                const SizedBox(width: 18),
                const Icon(Icons.chat_bubble_outline, size: 19),
                const SizedBox(width: 5),
                const Text('응원하기'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
