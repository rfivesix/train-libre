import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
  import ActivityKit

  @main
  struct TrainLibreLiveActivityBundle: WidgetBundle {
    // The Home Screen widgets need iOS 18, the Live Activity ships from 16.2.
    // Gating them here rather than raising the extension's deployment target is
    // what keeps the Live Activity available to 16/17 users.
    var body: some Widget {
      WorkoutLiveActivityWidget()
      if #available(iOS 18.0, *) {
        TodayGlanceWidget()
        QuickActionsWidget()
        AIMealControlWidget()
        ScanBarcodeControlWidget()
        StartWorkoutControlWidget()
        AddMeasurementControlWidget()
        LogSupplementControlWidget()
        AddLiquidControlWidget()
        AddFoodControlWidget()
      }
    }
  }

  struct WorkoutLiveActivityWidget: Widget {
    var body: some WidgetConfiguration {
      ActivityConfiguration(for: WorkoutActivityAttributes.self) { context in
        LALockScreenView(context: context)
          .widgetURL(URL(string: context.attributes.deepLink))
      } dynamicIsland: { context in
        DynamicIsland {
          // The header has to live in .leading/.trailing, not in .bottom.
          // The bottom region has a capped height, and header + title +
          // metrics + button row together overflow it — the region then draws
          // almost nothing. The cost is that .trailing cannot reach the same
          // right edge as .bottom, so the duration sits slightly inset from
          // "Set x of y". That is a property of the Dynamic Island's region
          // layout, not something the view can correct.
          DynamicIslandExpandedRegion(.leading) {
            HStack(spacing: 5) {
              Image("LiveActivityIcon")
                .resizable()
                .scaledToFit()
                .frame(width: 14, height: 14)
              Text(context.attributes.workoutTitle)
                .font(LATheme.metaFont)
                .foregroundStyle(LATheme.secondaryText)
                .lineLimit(1)
            }
            .padding(.leading, 6)
          }
          DynamicIslandExpandedRegion(.trailing) {
            Text(context.attributes.workoutStartedAt, style: .timer)
              .font(LATheme.metaFont)
              .foregroundStyle(LATheme.secondaryText)
              .lineLimit(1)
              .multilineTextAlignment(.trailing)
              .frame(maxWidth: .infinity, alignment: .trailing)
              .padding(.trailing, 6)
          }
          // No Link wrapper here: the region contains Button(intent:) controls,
          // and nesting interactive elements inside a Link breaks the region.
          // Tap-through is handled by widgetURL on the DynamicIsland below.
          DynamicIslandExpandedRegion(.bottom) {
            LAExpandedBottomView(context: context)
              .padding(.horizontal, 6)
              .padding(.bottom, 8)
          }
        } compactLeading: {
          compactLeading(context)
        } compactTrailing: {
          LACompactTrailing(state: context.state)
        } minimal: {
          minimal(context)
        }
        .widgetURL(URL(string: context.attributes.deepLink))
        .keylineTint(LATheme.accent)
      }
    }

    @ViewBuilder
    private func compactLeading(
      _ context: ActivityViewContext<WorkoutActivityAttributes>
    ) -> some View {
      switch context.state.phase {
      case .resting:
        if let end = context.state.restEndsAt {
          // `.timer` counts down to the date and then keeps counting up, so
          // the pill never freezes at 0:00. The red backing latches exactly at
          // the deadline without needing a re-render — see LAOverdueFill.
          Text(end, style: .timer)
            .font(.system(size: 12, weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            // A `.timer` text reserves width for a longer duration than it is
            // currently showing and leaves the digits leading-aligned inside
            // that reserve — which is why the pill came out far too wide with
            // the time stuck to its left edge. Capping the width and centring
            // explicitly fixes both. `.fixedSize()` is not an option here: on
            // a system-animated timer it renders nothing at all.
            .multilineTextAlignment(.center)
            .frame(width: 40, alignment: .center)
            .padding(.horizontal, 4)
            .padding(.vertical, 2)
            .background(LAOverdueBackground(deadline: end, cornerRadius: 7))
        } else {
          icon
        }
      case .setPending:
        if context.state.badge.text.isEmpty {
          icon
        } else {
          // As tall as the compact zone allows — it is the only thing there.
          Text(context.state.badge.text)
            .font(.system(size: 18, weight: .heavy))
            .foregroundStyle(Color(hexString: context.state.badge.colorHex))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
        }
      case .noSetsLeft, .empty:
        icon
      }
    }

    @ViewBuilder
    private func minimal(
      _ context: ActivityViewContext<WorkoutActivityAttributes>
    ) -> some View {
      switch context.state.phase {
      case .resting:
        if let end = context.state.restEndsAt {
          Text(end, style: .timer)
            .font(.system(size: 10, weight: .bold).monospacedDigit())
            .foregroundStyle(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            .multilineTextAlignment(.center)
            .frame(width: 34, alignment: .center)
            .padding(.horizontal, 2)
            .padding(.vertical, 1)
            .background(LAOverdueBackground(deadline: end, cornerRadius: 6))
        } else {
          icon
        }
      case .setPending:
        // Identical to the compact trailing zone. With a second Live Activity
        // on screen this is the only place the set appears at all, so it shows
        // the same two lines rather than a shortened variant.
        LACompactTrailing(state: context.state)
      case .noSetsLeft, .empty:
        icon
      }
    }

    private var icon: some View {
      Image("LiveActivityIcon")
        .resizable()
        .scaledToFit()
        .frame(width: 14, height: 14)
    }
  }

#endif
