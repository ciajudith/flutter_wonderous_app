part of '../wonder_events.dart';

class _EventsList extends StatefulWidget {
  const _EventsList(
      {Key? key,
      required this.data,
      this.topHeight = 0,
      this.blurOnScroll = false,
      this.showTopGradient = true,
      this.showBottomGradient = true})
      : super(key: key);
  final WonderData data;
  final double topHeight;
  final bool blurOnScroll;
  final bool showTopGradient;
  final bool showBottomGradient;

  @override
  State<_EventsList> createState() => _EventsListState();
}

class _EventsListState extends State<_EventsList> with StatefulPropsMixin {
  late final _scroll = ScrollControllerProp(this);

  @override
  Widget build(BuildContext context) {
    return widget.blurOnScroll ? _buildScrollingListWithBlur() : _buildScrollingList();
  }

  /// The actual content of the scrolling list
  Widget _buildScrollingList() {
    Container buildHandle() {
      return Container(
        width: 35,
        height: 5,
        decoration: BoxDecoration(color: $styles.colors.greyMedium, borderRadius: BorderRadius.circular(99)),
      );
    }

    final events = widget.data.events;

    final listItems = <Widget>[];
    for (var e in events.entries) {
      final delay = 100.ms + (100 * listItems.length).ms;
      listItems.add(
        TimelineEventCard(year: e.key, text: e.value, darkMode: true)
            .animate()
            .fade(delay: delay, duration: $styles.times.med * 1.5)
            .slide(begin: Offset(0, 1), curve: Curves.easeOutBack),
      );
    }
    return Stack(
      children: [
        //TODO: Remove scrollbar on portrait
        SingleChildScrollView(
          controller: _scroll.controller,
          child: Column(
            children: [
              IgnorePointer(child: Gap(widget.topHeight)),
              Container(
                decoration: BoxDecoration(
                  color: $styles.colors.black,
                  borderRadius: BorderRadius.circular($styles.corners.md),
                ),
                padding: EdgeInsets.symmetric(horizontal: $styles.insets.md),
                child: Column(
                  children: [
                    Gap($styles.insets.xs),
                    buildHandle(),
                    Gap($styles.insets.sm),
                    ...listItems,
                    Gap($styles.insets.xl),
                    HiddenCollectible(widget.data.type, index: 2, size: 150),
                    Gap(150),
                  ],
                ),
              ),
            ],
          ),
        ),

        /// Vertical gradient on btm
        if (widget.showBottomGradient)
          Positioned.fill(
            child: BottomCenter(
              child: ListOverscollGradient(bottomUp: true, size: 100),
            ),
          ),
        if (widget.showTopGradient)
          Positioned.fill(
            child: TopCenter(
              child: ListOverscollGradient(size: 100),
            ),
          ),
      ],
    );
  }

  /// Wraps the list in a scroll listener
  Widget _buildScrollingListWithBlur() {
    return ListenableBuilder(
      listenable: _scroll.controller,
      child: _buildScrollingList(),
      builder: (_, child) {
        bool showBackdrop = true;
        double backdropAmt = 0;
        if (showBackdrop) {
          double blurStart = 50;
          double maxScroll = 150;
          double scrollPx = _scroll.px - blurStart;
          // Normalize scroll position to a value between 0 and 1
          backdropAmt = (_scroll.px - blurStart).clamp(0, maxScroll) / maxScroll;
          // Disable backdrop once it is offscreen for an easy perf win
          showBackdrop = (scrollPx <= 500);
        }
        // Container provides a underlay which gets darker as the background blurs
        return Stack(
          children: [
            if (showBackdrop) ...[
              AppBackdrop(
                  strength: backdropAmt,
                  child: IgnorePointer(
                    child: Container(
                      color: $styles.colors.black.withOpacity(backdropAmt * .6),
                    ),
                  )),
            ],
            child!,
          ],
        );
      },
    );
  }
}
