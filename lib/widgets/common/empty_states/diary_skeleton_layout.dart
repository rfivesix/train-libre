import 'package:flutter/material.dart';
import '../../../util/design_constants.dart';
import '../app_card_container.dart';
import 'app_skeleton.dart';

class DiarySkeletonLayout extends StatelessWidget {
  const DiarySkeletonLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(120), // "HEUTE IM BLICK"
        _buildMacroGrid(),
        const SizedBox(height: DesignConstants.spacingM),
        _buildSectionHeader(160), // "HEUTIGES PROTOKOLL"
        _buildSkeletonCard(context), // Water
        _buildSkeletonCard(context), // Breakfast
        _buildSkeletonCard(context), // Lunch
        _buildSkeletonCard(context), // Dinner
        _buildSkeletonCard(context), // Snacks
        const SizedBox(height: DesignConstants.spacingXXL),
      ],
    );
  }

  Widget _buildSectionHeader(double width) {
    return Padding(
      padding: const EdgeInsets.only(
        left: DesignConstants.spacingS,
        bottom: DesignConstants.spacingM,
        top: DesignConstants.spacingM,
      ),
      child: SkeletonText(width: width, height: 14),
    );
  }

  Widget _buildMacroGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: DesignConstants.spacingS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                _buildGridSkeletonCard(70),
                const SizedBox(height: 12),
                _buildGridSkeletonCard(70),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              children: [
                _buildGridSkeletonCard(42),
                const SizedBox(height: 12),
                _buildGridSkeletonCard(42),
                const SizedBox(height: 12),
                _buildGridSkeletonCard(42),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridSkeletonCard(double height) {
    return AppCardContainer(
      margin: EdgeInsets.zero,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonText(width: 64, height: 16),
            const Spacer(),
            const SkeletonText(width: 90, height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildSkeletonCard(BuildContext context) {
    return AppCardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const SkeletonText(width: 120, height: 20),
              const Spacer(),
              AppSkeleton(
                width: 28, 
                height: 28, 
                borderRadius: BorderRadius.circular(14),
              ),
            ],
          ),
          const SizedBox(height: DesignConstants.spacingM),
          const AppSkeleton(width: double.infinity, height: 32),
        ],
      ),
    );
  }
}
