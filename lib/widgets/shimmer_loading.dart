import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../theme/app_colors.dart';

class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Define colors for Light and Dark mode
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: ListView.separated(
        itemCount: 6, // Show 6 fake posts
        physics: const NeverScrollableScrollPhysics(), // Disable scrolling on skeleton
        separatorBuilder: (ctx, i) => const Divider(),
        itemBuilder: (ctx, i) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Avatar Skeleton
              const CircleAvatar(radius: 20, backgroundColor: Colors.white),
              const SizedBox(width: 12),

              // 2. Content Skeleton
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name & Time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(width: 100, height: 10, color: Colors.white),
                        Container(width: 40, height: 10, color: Colors.white),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Category
                    Container(width: 60, height: 10, color: Colors.white),
                    const SizedBox(height: 10),

                    // Post Text (3 lines)
                    Container(width: double.infinity, height: 10, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: double.infinity, height: 10, color: Colors.white),
                    const SizedBox(height: 6),
                    Container(width: 200, height: 10, color: Colors.white),

                    const SizedBox(height: 15),

                    // Actions Row
                    Row(
                      children: [
                        Container(width: 20, height: 20, color: Colors.white),
                        const SizedBox(width: 30),
                        Container(width: 20, height: 20, color: Colors.white),
                        const SizedBox(width: 30),
                        Container(width: 20, height: 20, color: Colors.white),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

class ShimmerCategoryBar extends StatelessWidget {
  const ShimmerCategoryBar({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 5,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, __) => Container(
            width: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
    );
  }
}

class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // 1. Header Skeleton
            Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  // Avatar
                  const CircleAvatar(radius: 45, backgroundColor: Colors.white),
                  const SizedBox(height: 16),
                  // Name
                  Container(height: 24, width: 150, color: Colors.white),
                  const SizedBox(height: 24),
                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                          child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)))),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Container(
                              height: 45,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10)))),
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 30),

            // 2. Posts List Skeleton
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              itemBuilder: (ctx, i) => Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                        radius: 20, backgroundColor: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                              width: 120, height: 12, color: Colors.white),
                          const SizedBox(height: 8),
                          Container(
                              width: double.infinity,
                              height: 12,
                              color: Colors.white),
                          const SizedBox(height: 6),
                          Container(
                              width: 200, height: 12, color: Colors.white),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ShimmerCommentList extends StatelessWidget {
  const ShimmerCommentList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;
    final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

    return Shimmer.fromColors(
      baseColor: baseColor,
      highlightColor: highlightColor,
      child: Column(
        children: List.generate(5, (index) => _buildShimmerCommentItem()),
      ),
    );
  }

  Widget _buildShimmerCommentItem() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar Skeleton
          const CircleAvatar(radius: 16, backgroundColor: Colors.white),
          const SizedBox(width: 12),

          // Content Skeleton
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name & Time
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(width: 80, height: 10, color: Colors.white),
                    Container(width: 40, height: 10, color: Colors.white),
                  ],
                ),
                const SizedBox(height: 10),

                // Comment Text (2 lines)
                Container(width: double.infinity, height: 10, color: Colors.white),
                const SizedBox(height: 6),
                Container(width: 150, height: 10, color: Colors.white),
              ],
            ),
          ),
        ],
      ),
    );
  }
}