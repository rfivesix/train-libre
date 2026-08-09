import SwiftUI
import WidgetKit
#if canImport(AppIntents)
  import AppIntents
#endif

#if canImport(ActivityKit)
  import ActivityKit

  // MARK: - Shared pieces

  /// Header row — used on Lock screen banner.
  @available(iOS 16.2, *)
  struct LAHeader: View {
    let attributes: WorkoutActivityAttributes

    var body: some View {
      HStack(spacing: 8) {
        Image("LiveActivityIcon")
          .resizable()
          .scaledToFit()
          .frame(width: 14, height: 14)
        Text(attributes.workoutTitle)
          .font(LATheme.metaFont)
          .foregroundStyle(LATheme.secondaryText)
          .lineLimit(1)
        Spacer(minLength: 4)
        // Same size and weight as the workout title and "Set x of y" — no
        // monospaced digits, which is what made it read as a different face.
        Text(attributes.workoutStartedAt, style: .timer)
          .font(LATheme.metaFont)
          .foregroundStyle(LATheme.secondaryText)
          .lineLimit(1)
          .multilineTextAlignment(.trailing)
      }
      .padding(.bottom, 11)
    }
  }

  /// Exercise name + set position.
  @available(iOS 16.2, *)
  struct LATitleRow: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
      HStack(alignment: .firstTextBaseline, spacing: 10) {
        Text(state.exerciseName)
          .font(.system(size: 17, weight: .bold))
          .foregroundStyle(.white)
          .lineLimit(1)
          .minimumScaleFactor(0.8)
        Spacer(minLength: 4)
        Text(state.setPosition)
          .font(LATheme.metaFont)
          .foregroundStyle(LATheme.secondaryText)
          .lineLimit(1)
          .fixedSize()
      }
    }
  }

  /// The metrics line. The set-type badge leads it.
  @available(iOS 16.2, *)
  struct LAMetricsRow: View {
    let state: WorkoutActivityAttributes.ContentState
    let dimmed: Bool
    let showTertiary: Bool
    /// With no timer running, the set is the only thing on the card — it gets
    /// the full weight of the exercise name. While resting, the timer row
    /// carries the attention and the set steps back a size.
    let prominent: Bool

    init(
      state: WorkoutActivityAttributes.ContentState,
      dimmed: Bool = false,
      showTertiary: Bool = true,
      prominent: Bool = false
    ) {
      self.state = state
      self.dimmed = dimmed
      self.showTertiary = showTertiary
      self.prominent = prominent
    }

    private var badgeColor: Color {
      let isNeutral = state.badge.colorHex == "#8E8E93" || state.badge.colorHex == "8E8E93"
      return isNeutral ? Color.white : Color(hexString: state.badge.colorHex)
    }

    /// One size and weight for the whole row, matching the exercise name's
    /// face. Previously the badge sat at 15.5 and the values at 13.5, which is
    /// what made the line read as two different fonts.
    private var metricFont: Font {
      .system(size: prominent ? 17 : 15, weight: .bold)
    }

    var body: some View {
      HStack(alignment: .firstTextBaseline, spacing: 6) {
        if !state.badge.text.isEmpty {
          Text(state.badge.text)
            .foregroundStyle(badgeColor)
            .padding(.trailing, 1)
        }
        Text(state.metricPrimary)
          .foregroundStyle(.white)
        if !state.metricSecondary.isEmpty {
          Text(state.metricSeparator)
            .foregroundStyle(.white)
          Text(state.metricSecondary)
            .foregroundStyle(.white)
        }
        if showTertiary && !state.metricTertiary.isEmpty {
          Text(state.metricTertiary)
            .foregroundStyle(.white)
        }
      }
      .font(metricFont)
      .lineLimit(1)
      .minimumScaleFactor(0.75)
      .opacity(dimmed ? 0.45 : 1.0)
    }
  }

  /// The checkmark button. On iOS 17+ it triggers CompleteSetIntent.
  @available(iOS 16.2, *)
  struct LATickButton: View {
    let attributes: WorkoutActivityAttributes

    var body: some View {
      if #available(iOS 17.0, *) {
        Button(intent: CompleteSetIntent(workoutLogId: attributes.workoutLogId)) {
          tick
        }
        .buttonStyle(.plain)
      } else {
        tick
      }
    }

    private var tick: some View {
      Image(systemName: "checkmark")
        .font(.system(size: 16, weight: .bold))
        .foregroundStyle(LATheme.onAccent)
        .frame(width: LATheme.tickSize, height: LATheme.tickSize)
        .background(LATheme.accent, in: RoundedRectangle(cornerRadius: LATheme.controlRadius))
    }
  }

  /// −15s · countdown · +15s · Skip.
  @available(iOS 17.0, *)
  struct LARestControls: View {
    let attributes: WorkoutActivityAttributes
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
      // The hairline progress bar is deliberately gone for now. It was a
      // `ProgressView(timerInterval:).progressViewStyle(.linear)` forced to a
      // 3pt height — the linear style lays out through a GeometryReader, and
      // the widget renderer was tripping a layout assertion inside
      // `GeometryReaderLayout.placeSubviews` during the island expand
      // animation. Nothing else in this tree uses a GeometryReader.
      VStack(spacing: 10) {
        HStack(spacing: 7) {
          Button(intent: AdjustRestIntent(deltaSeconds: -15)) {
            Text("−15s")
              .font(.system(size: 12.5, weight: .semibold))
              .foregroundStyle(.white)
              .frame(width: 54, height: LATheme.controlHeight)
              .background(
                LATheme.controlFill,
                in: RoundedRectangle(cornerRadius: LATheme.controlRadius)
              )
          }
          .buttonStyle(.plain)

          if let end = state.restEndsAt {
            // `.timer` rather than `timerInterval:` — it counts down to the
            // date and then keeps counting up past it, instead of freezing at
            // 0:00 until the layout switch finally arrives.
            Text(end, style: .timer)
              .font(.system(size: 17, weight: .bold).monospacedDigit())
              .foregroundStyle(LATheme.accent)
              .multilineTextAlignment(.center)
              .lineLimit(1)
              .frame(maxWidth: .infinity)
              .frame(height: LATheme.controlHeight)
              .background(
                // Same fill as the -15s / +15s buttons beside it.
                LATheme.controlFill,
                in: RoundedRectangle(cornerRadius: LATheme.controlRadius)
              )
          }

          Button(intent: AdjustRestIntent(deltaSeconds: 15)) {
            Text("+15s")
              .font(.system(size: 12.5, weight: .semibold))
              .foregroundStyle(.white)
              .frame(width: 54, height: LATheme.controlHeight)
              .background(
                LATheme.controlFill,
                in: RoundedRectangle(cornerRadius: LATheme.controlRadius)
              )
          }
          .buttonStyle(.plain)

          Button(intent: SkipRestIntent()) {
            Text(attributes.labelSkip)
              .font(.system(size: 12.5, weight: .bold))
              .foregroundStyle(LATheme.onAccent)
              .frame(width: 58, height: LATheme.controlHeight)
              .background(
                LATheme.accent,
                in: RoundedRectangle(cornerRadius: LATheme.controlRadius)
              )
          }
          .buttonStyle(.plain)
        }
      }
    }
  }

  @available(iOS 16.2, *)
  struct LAOverdueLabel: View {
    let attributes: WorkoutActivityAttributes
    let since: Date

    var body: some View {
      HStack(spacing: 4) {
        Text(attributes.labelOverdue)
        // `.timer` style, NOT `Text(timerInterval: since...Date.distantFuture)`:
        // an interval that long makes SwiftUI reserve width for a gigantic
        // duration string, which pushes the whole row out of the container and
        // trips a layout assertion in the widget renderer.
        Text(since, style: .timer)
          .lineLimit(1)
      }
      .font(.system(size: 12, weight: .semibold).monospacedDigit())
      .foregroundStyle(LATheme.overdue)
      .padding(.top, 6)
    }
  }

  @available(iOS 16.2, *)
  struct LAWideButton: View {
    let title: String
    let filled: Bool
    var deepLink: String = "trainlibre://workout/live?action=add_exercise"

    var body: some View {
      Link(destination: URL(string: deepLink)!) {
        Text(title)
          .font(.system(size: 15, weight: filled ? .bold : .semibold))
          .foregroundStyle(filled ? LATheme.onAccent : Color.white)
          .frame(maxWidth: .infinity)
          .frame(height: LATheme.wideControlHeight)
          .background(
            filled ? LATheme.accent : LATheme.controlFill,
            in: RoundedRectangle(cornerRadius: LATheme.wideControlRadius)
          )
      }
    }
  }

  // MARK: - Lock screen / banner

  @available(iOS 16.2, *)
  struct LALockScreenView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    private var isOverdue: Bool {
      guard context.state.phase == .resting else { return false }
      if context.isStale { return true }
      if let end = context.state.restEndsAt {
        return Date() >= end
      }
      return false
    }

    var body: some View {
      VStack(alignment: .leading, spacing: 0) {
        LAHeader(attributes: context.attributes)

        switch context.state.phase {
        case .noSetsLeft:
          LAWideButton(title: context.attributes.labelAddExercise, filled: true)
        case .empty:
          LAWideButton(title: context.attributes.labelOpenApp, filled: false, deepLink: context.attributes.deepLink)
        case .setPending:
          setBody(dimmed: false, showTick: true, showTertiary: true, prominent: true)
        case .resting:
          if isOverdue {
            setBody(dimmed: false, showTick: true, showTertiary: true, prominent: true)
            if let end = context.state.restEndsAt {
              LAOverdueLabel(attributes: context.attributes, since: end)
            }
          } else {
            setBody(dimmed: false, showTick: false, showTertiary: true, prominent: false)
            if #available(iOS 17.0, *) {
              LARestControls(attributes: context.attributes, state: context.state)
                .padding(.top, LATheme.rowSpacing)
            }
          }
        }
      }
      .padding(.horizontal, 15)
      .padding(.vertical, 13)
      .activityBackgroundTint(Color(hex: 0x1C1C1E))
      .activitySystemActionForegroundColor(LATheme.accent)
    }

    @ViewBuilder
    private func setBody(
      dimmed: Bool,
      showTick: Bool,
      showTertiary: Bool,
      prominent: Bool
    ) -> some View {
      LATitleRow(state: context.state)
      HStack(spacing: 8) {
        LAMetricsRow(
          state: context.state,
          dimmed: dimmed,
          showTertiary: showTertiary,
          prominent: prominent
        )
        Spacer(minLength: 4)
        if showTick {
          LATickButton(attributes: context.attributes)
        }
      }
      .padding(.top, LATheme.rowSpacing)
    }
  }

  // MARK: - Dynamic Island Expanded Bottom View

  @available(iOS 16.2, *)
  struct LAExpandedBottomView: View {
    let context: ActivityViewContext<WorkoutActivityAttributes>

    private var isOverdue: Bool {
      guard context.state.phase == .resting else { return false }
      if context.isStale { return true }
      if let end = context.state.restEndsAt {
        return Date() >= end
      }
      return false
    }

    var body: some View {
      // No header here — it lives in the .leading/.trailing regions. Putting
      // it in this region as well overflows the bottom region's height budget
      // and the whole region stops drawing.
      VStack(alignment: .leading, spacing: 0) {
        switch context.state.phase {
        case .noSetsLeft:
          LAWideButton(title: context.attributes.labelAddExercise, filled: true)
        case .empty:
          LAWideButton(title: context.attributes.labelOpenApp, filled: false, deepLink: context.attributes.deepLink)
        case .setPending:
          setBody(dimmed: false, showTick: true, showTertiary: true, prominent: true)
        case .resting:
          if isOverdue {
            setBody(dimmed: false, showTick: true, showTertiary: true, prominent: true)
            if let end = context.state.restEndsAt {
              LAOverdueLabel(attributes: context.attributes, since: end)
            }
          } else {
            setBody(dimmed: false, showTick: false, showTertiary: true, prominent: false)
            if #available(iOS 17.0, *) {
              LARestControls(attributes: context.attributes, state: context.state)
                .padding(.top, LATheme.rowSpacing)
            }
          }
        }
      }
    }

    @ViewBuilder
    private func setBody(
      dimmed: Bool,
      showTick: Bool,
      showTertiary: Bool,
      prominent: Bool
    ) -> some View {
      LATitleRow(state: context.state)
      HStack(spacing: 8) {
        LAMetricsRow(
          state: context.state,
          dimmed: dimmed,
          showTertiary: showTertiary,
          prominent: prominent
        )
        Spacer(minLength: 4)
        if showTick {
          LATickButton(attributes: context.attributes)
        }
      }
      .padding(.top, LATheme.rowSpacing)
    }
  }

  /// Compact trailing — two short lines for S1-S3, or '+' / '—' for S4/S5.
  @available(iOS 16.2, *)
  struct LACompactTrailing: View {
    let state: WorkoutActivityAttributes.ContentState

    var body: some View {
      switch state.phase {
      case .noSetsLeft:
        Text("+")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(LATheme.accent)
          .padding(.trailing, 8)
      case .empty:
        Text("—")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(LATheme.secondaryText)
          .padding(.trailing, 8)
      case .setPending, .resting:
        VStack(alignment: .trailing, spacing: 1) {
          Text(state.compactPrimary)
            .font(.system(size: 11, weight: .bold))
            .foregroundStyle(.white)
          if !state.compactSecondary.isEmpty {
            Text(state.compactSecondary)
              .font(.system(size: 9.5, weight: .bold))
              .foregroundStyle(.white)
          }
        }
        .lineLimit(1)
        // `fixedSize()` let a long value ("110 kg") widen the pill without
        // limit. Cap it and let the text shrink instead — the compact zone is
        // a glance target, not a readout.
        .minimumScaleFactor(0.7)
        .frame(maxWidth: 58, alignment: .trailing)
        .padding(.trailing, 6)
      }
    }
  }

#endif
