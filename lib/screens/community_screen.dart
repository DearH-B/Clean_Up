import 'package:flutter/material.dart';

import '../widgets/fairy_image.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

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
          onPressed: () => _showComingSoon(context),
          icon: const Icon(Icons.add_a_photo_outlined),
          label: const Text('내 청소 자랑하기'),
        ),
        const SizedBox(height: 20),
        const _CommunityPost(
          name: '반짝주방',
          place: '주방',
          message: '미뤄뒀던 냉장고 선반을 전부 닦았어요. 문 열 때마다 기분이 좋아요!',
          likes: 24,
          color: Color(0xFFFFE9EC),
          icon: Icons.kitchen_outlined,
        ),
        const SizedBox(height: 12),
        const _CommunityPost(
          name: '정리한스푼',
          place: '거실',
          message: '소파 밑까지 청소기 완료. 청소 요정에게 칭찬받을 준비됐어요.',
          likes: 17,
          color: Color(0xFFFFF4E3),
          icon: Icons.weekend_outlined,
        ),
        const SizedBox(height: 12),
        const _CommunityPost(
          name: '오늘도한칸',
          place: '욕실',
          message: '세면대 하나만 닦으려고 했는데 거울까지 끝냈어요!',
          likes: 31,
          color: Color(0xFFF4E9FF),
          icon: Icons.bathtub_outlined,
        ),
      ],
    );
  }

  void _showComingSoon(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => const Padding(
        padding: EdgeInsets.fromLTRB(24, 4, 24, 30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FairyImage(
              size: 96,
              assetPath: '캐릭터/청소요정_완료.png',
            ),
            SizedBox(height: 12),
            Text(
              '자랑 글 작성 기능을 준비하고 있어요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            SizedBox(height: 6),
            Text('MVP에서는 커뮤니티 모습을 먼저 확인할 수 있어요.'),
          ],
        ),
      ),
    );
  }
}

class _CommunityPost extends StatelessWidget {
  const _CommunityPost({
    required this.name,
    required this.place,
    required this.message,
    required this.likes,
    required this.color,
    required this.icon,
  });

  final String name;
  final String place;
  final String message;
  final int likes;
  final Color color;
  final IconData icon;

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
                  backgroundColor: color,
                  child: Icon(icon, color: const Color(0xFF6E4A50)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      Text(place, style: Theme.of(context).textTheme.bodySmall),
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
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 48, color: const Color(0xFF9C6A74)),
            ),
            const SizedBox(height: 12),
            Text(message),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.favorite_border, size: 20),
                const SizedBox(width: 5),
                Text('$likes'),
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
