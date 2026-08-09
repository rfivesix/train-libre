import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
  import ActivityKit

  @main
  struct TrainLibreLiveActivityBundle: WidgetBundle {
    var body: some Widget {
      WorkoutLiveActivityWidget()
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

    private func checkIsOverdue(
      _ state: WorkoutActivityAttributes.ContentState,
      isStale: Bool
    ) -> Bool {
      guard state.phase == .resting else { return false }
      if isStale { return true }
      if let end = state.restEndsAt {
        return Date() >= end
      }
      return false
    }

    @ViewBuilder
    private func compactLeading(
      _ context: ActivityViewContext<WorkoutActivityAttributes>
    ) -> some View {
      switch context.state.phase {
      case .resting:
        if let end = context.state.restEndsAt {
          // One text for both cases: `.timer` counts down to the date and then
          // keeps counting up, so the pill never freezes at 0:00. Only the
          // colour depends on a re-render.
          Text(end, style: .timer)
            .font(.system(size: 12, weight: .bold).monospacedDigit())
            .foregroundStyle(
              checkIsOverdue(context.state, isStale: context.isStale)
                ? LATheme.overdue : LATheme.accent
            )
            .lineLimit(1)
            // Without a cap the timer text reserves width for the longest
            // possible duration and stretches the whole compact pill.
            .frame(maxWidth: 44)
        } else {
          icon
        }
      case .setPending:
        if context.state.badge.text.isEmpty {
          icon
        } else {
          Text(context.state.badge.text)
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(Color(hexString: context.state.badge.colorHex))
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
            .foregroundStyle(
              checkIsOverdue(context.state, isStale: context.isStale)
                ? LATheme.overdue : LATheme.accent
            )
            .lineLimit(1)
        } else {
          icon
        }
      case .setPending, .noSetsLeft, .empty:
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
