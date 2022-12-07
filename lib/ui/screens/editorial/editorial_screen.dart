import 'dart:async';

import 'package:drop_cap_text/drop_cap_text.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_circular_text/circular_text.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:wonders/common_libs.dart';
import 'package:wonders/logic/common/platform_info.dart';
import 'package:wonders/logic/common/string_utils.dart';
import 'package:wonders/logic/data/wonder_data.dart';
import 'package:wonders/ui/common/app_icons.dart';
import 'package:wonders/ui/common/blend_mask.dart';
import 'package:wonders/ui/common/centered_box.dart';
import 'package:wonders/ui/common/compass_divider.dart';
import 'package:wonders/ui/common/curved_clippers.dart';
import 'package:wonders/ui/common/google_maps_marker.dart';
import 'package:wonders/ui/common/gradient_container.dart';
import 'package:wonders/ui/common/hidden_collectible.dart';
import 'package:wonders/ui/common/pop_router_on_over_scroll.dart';
import 'package:wonders/ui/common/scaling_list_item.dart';
import 'package:wonders/ui/common/static_text_scale.dart';
import 'package:wonders/ui/common/themed_text.dart';
import 'package:wonders/ui/common/utils/context_utils.dart';
import 'package:wonders/ui/wonder_illustrations/common/animated_clouds.dart';
import 'package:wonders/ui/wonder_illustrations/common/wonder_illustration.dart';
import 'package:wonders/ui/wonder_illustrations/common/wonder_illustration_config.dart';
import 'package:wonders/ui/wonder_illustrations/common/wonder_title_text.dart';

part 'widgets/_app_bar.dart';
part 'widgets/_callout.dart';
part 'widgets/_circular_title_bar.dart';
part 'widgets/_collapsing_pull_quote_image.dart';
part 'widgets/_large_simple_quote.dart';
part 'widgets/_scrolling_content.dart';
part 'widgets/_section_divider.dart';
part 'widgets/_sliding_image_stack.dart';
part 'widgets/_title_text.dart';
part 'widgets/_top_illustration.dart';

class WonderEditorialScreen extends StatefulWidget {
  const WonderEditorialScreen(this.data, {Key? key, required this.onScroll}) : super(key: key);
  final WonderData data;
  final void Function(double scrollPos) onScroll;

  @override
  State<WonderEditorialScreen> createState() => _WonderEditorialScreenState();
}

class _WonderEditorialScreenState extends State<WonderEditorialScreen> with StatefulPropsMixin {
  late final _scroll = ScrollControllerProp(this, onChange: _handleScrollChanged);
  late final _scrollPos = ValueNotifier(0.0);
  late final _sectionIndex = ValueNotifier(0);

  /// Various [ValueListenableBuilders] are mapped to the _scrollPos and will rebuild when it changes
  void _handleScrollChanged() {
    _scrollPos.value = _scroll.px;
    widget.onScroll.call(_scrollPos.value);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, constraints) {
      bool shortMode = constraints.biggest.height < 700;
      double illustrationHeight = shortMode ? 250 : 280;
      double minAppBarHeight = shortMode ? 80 : 150;

      /// Attempt to maintain a similar aspect ratio for the image within the app-bar
      double maxAppBarHeight = min(context.widthPx, $styles.sizes.maxContentWidth1) * 1.5;

      return PopRouterOnOverScroll(
        controller: _scroll.controller,
        child: ColoredBox(
          color: $styles.colors.offWhite,
          child: Stack(
            children: [
              /// Background
              Positioned.fill(
                child: ColoredBox(color: widget.data.type.bgColor),
              ),

              /// Top Illustration - Sits underneath the scrolling content, fades out as it scrolls
              SizedBox(
                height: illustrationHeight,
                child: ListenableBuilder(
                  listenable: _scrollPos,
                  builder: (_, child) {
                    // get some value between 0 and 1, based on the amt scrolled
                    double opacity = (1 - _scrollPos.value / 700).clamp(0, 1);
                    return Opacity(opacity: opacity, child: child);
                  },
                  // This is due to a bug: https://github.com/flutter/flutter/issues/101872
                  child: RepaintBoundary(child: _TopIllustration(widget.data.type)),
                ),
              ),

              /// Scrolling content - Includes an invisible gap at the top, and then scrolls over the illustration
              TopCenter(
                child: SizedBox(
                  //width: $styles.sizes.maxContentWidth1,
                  child: CustomScrollView(
                    primary: false,
                    controller: _scroll.controller,
                    scrollBehavior: ScrollConfiguration.of(context).copyWith(),
                    cacheExtent: 1000,
                    slivers: [
                      /// Invisible padding at the top of the list, so the illustration shows through the btm
                      SliverToBoxAdapter(
                        child: SizedBox(height: illustrationHeight),
                      ),

                      /// Text content, animates itself to hide behind the app bar as it scrolls up
                      SliverToBoxAdapter(
                        child: ListenableBuilder(
                          listenable: _scrollPos,
                          builder: (_, child) {
                            double offsetAmt = max(0, _scrollPos.value * .3);
                            double opacity = (1 - offsetAmt / 150).clamp(0, 1);
                            return Transform.translate(
                              offset: Offset(0, offsetAmt),
                              child: Opacity(opacity: opacity, child: child),
                            );
                          },
                          child: _TitleText(widget.data, scroller: _scroll.controller),
                        ),
                      ),

                      /// Collapsing App bar, pins to the top of the list
                      SliverAppBar(
                        pinned: true,
                        collapsedHeight: minAppBarHeight,
                        toolbarHeight: minAppBarHeight,
                        expandedHeight: maxAppBarHeight,
                        backgroundColor: Colors.transparent,
                        elevation: 0,
                        leading: SizedBox.shrink(),
                        flexibleSpace: SizedBox.expand(
                          child: _AppBar(
                            widget.data.type,
                            scrollPos: _scrollPos,
                            sectionIndex: _sectionIndex,
                          ).animate().fade(duration: $styles.times.med, delay: $styles.times.pageTransition),
                        ),
                      ),

                      /// Editorial content (text and images)
                      _ScrollingContent(widget.data, scrollPos: _scrollPos, sectionNotifier: _sectionIndex),

                      /// Bottom padding
                      SliverToBoxAdapter(
                        child: Container(height: 150, color: $styles.colors.offWhite),
                      ),
                    ],
                  ),
                ),
              ),

              /// Home Btn
              ListenableBuilder(
                  listenable: _scroll.controller,
                  builder: (_, child) {
                    return AnimatedOpacity(
                      opacity: _scrollPos.value > 0 ? 0 : 1,
                      duration: $styles.times.med,
                      child: child,
                    );
                  },
                  child: BackBtn(icon: AppIcons.north).safe()),
            ],
          ),
        ),
      );
    });
  }
}
