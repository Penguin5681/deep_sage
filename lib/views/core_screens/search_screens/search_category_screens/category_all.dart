import 'package:deep_sage/core/config/helpers/app_icons.dart';
import 'package:deep_sage/widgets/dataset_card.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class CategoryAll extends StatelessWidget {
  const CategoryAll({super.key});

  @override
  Widget build(BuildContext context) {
    final ScrollController scrollController = ScrollController();
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.only(top: 25.0, left: 35.0),
        child: Column(
          children: [
            Listener(
              onPointerSignal: (PointerSignalEvent event) {
                if (event is PointerScrollEvent) {
                  final offset = event.scrollDelta.dy;
                  scrollController.animateTo(
                    (scrollController.offset + offset).clamp(
                      0.0,
                      scrollController.position.maxScrollExtent,
                    ),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                  );
                }
              },
              child: Scrollbar(
                controller: scrollController,
                thumbVisibility: false,
                thickness: 4,
                radius: const Radius.circular(20),
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  controller: scrollController,
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      DatasetCard(
                        lightIconPath: AppIcons.chartLight,
                        labelText: 'Explore Stock Market Data',
                        subLabelText: 'Historical Stock prices and data',
                        buttonText: 'Search',
                        darkIconPath: AppIcons.chartDark,
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.aiLight,
                        darkIconPath: AppIcons.aiDark,
                        labelText: 'Explore AI & Tech Trends',
                        subLabelText:
                            'Latest datasets on AI, ML, and emerging technologies',
                        buttonText: 'Search',
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.healthLight,
                        darkIconPath: AppIcons.healthDark,
                        labelText: 'Explore Healthcare Insights',
                        subLabelText:
                            'Medical research, patient statistics, and health trends',
                        buttonText: 'Search',
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.governmentLight,
                        darkIconPath: AppIcons.governmentDark,
                        labelText: 'Explore Government Open Data',
                        subLabelText: 'Public reports, policies, and economic indicators',
                        buttonText: 'Search',
                      ),
                      const SizedBox(width: 25),
                      DatasetCard(
                        lightIconPath: AppIcons.factoryLight,
                        darkIconPath: AppIcons.factoryDark,
                        labelText: 'Explore Manufacturing Analytics',
                        subLabelText: 'Production data, supply chain insights, and industrial trends',
                        buttonText: 'Search',
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
