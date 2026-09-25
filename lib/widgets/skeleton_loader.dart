import 'package:flutter/material.dart';
import '../main.dart';

class _Shimmer extends StatefulWidget {
  final Widget child;
  const _Shimmer({required this.child});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final t = _controller.value;
            return LinearGradient(
              begin: Alignment(-1.0 - t * 2, 0),
              end: Alignment(1.0 - t * 2, 0),
              colors: [
                AppColors.fieldFill,
                AppColors.border.withOpacity(0.6),
                AppColors.fieldFill,
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final BorderRadius borderRadius;
  const SkeletonBox({super.key, this.width, this.height = 14, this.borderRadius = const BorderRadius.all(Radius.circular(6))});

  @override
  Widget build(BuildContext context) {
    return _Shimmer(
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(color: AppColors.fieldFill, borderRadius: borderRadius),
      ),
    );
  }
}

class SkeletonListingCard extends StatelessWidget {
  const SkeletonListingCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AspectRatio(
            aspectRatio: 16 / 10,
            child: SkeletonBox(width: double.infinity, height: double.infinity, borderRadius: BorderRadius.zero),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                SkeletonBox(width: 160, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SkeletonListingList extends StatelessWidget {
  final int count;
  const SkeletonListingList({super.key, this.count = 6});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: count,
      itemBuilder: (context, i) => const SkeletonListingCard(),
    );
  }
}
