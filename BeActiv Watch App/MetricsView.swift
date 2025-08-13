//
//  MetricsView.swift
//  MyWorkouts Watch App
//
//  Created by Gustavo Souto Pereira on 11/08/25.
//

import SwiftUI
import HealthKit

// The main view for displaying workout metrics.
struct MetricsView: View {
    @ObservedObject var workoutManager: WorkoutManager

    var body: some View {
        TimelineView(
            MetricsTimeLineSchedule(from: workoutManager.builder?.startDate ?? Date())
        ) { (context: TimelineViewDefaultContext) in
            VStack(alignment: .leading) {
                ElapsedTimeView(
                    elapsedTime: workoutManager.builder?.elapsedTime ?? 0,
                    showSubseconds: context.cadence == .live
                )
                .foregroundStyle(.yellow)

                Text(
                    Measurement(
                        value: workoutManager.activeEnergy,
                        unit: UnitEnergy.kilocalories
                    ).formatted(
                        .measurement(
                            width: .abbreviated,
                            usage: .workout,
                            numberFormatStyle: .number.precision(.fractionLength(0))
                        )
                    )
                )

                Text(
                    workoutManager.heartRate.formatted(.number.precision(.fractionLength(0))) + " bpm"
                )

                Text(
                    Measurement(
                        value: workoutManager.distance,
                        unit: UnitLength.meters
                    ).formatted(
                        .measurement(
                            width: .abbreviated,
                            usage: .road
                        )
                    )
                )
            }
        }
        .font(
            .system(.title, design: .rounded)
                .monospacedDigit()
                .lowercaseSmallCaps()
        )
        .frame(maxWidth: .infinity, alignment: .leading)
        .ignoresSafeArea(edges: .bottom)
        .scenePadding()
    }
}




// A custom TimelineSchedule to control the view's update frequency.
private struct MetricsTimeLineSchedule: TimelineSchedule {
    var startDate: Date

    // The fix is in this initializer's signature.
    // The external parameter name 'from' is followed by the internal parameter name 'startDate'.
    init(from startDate: Date) {
        self.startDate = startDate
    }

    func entries(from startDate: Date, mode: TimelineScheduleMode) -> PeriodicTimelineSchedule.Entries {
        PeriodicTimelineSchedule(
            from: self.startDate,
            by: (mode == .lowFrequency ? 1.0 : 1.0 / 30.0)
        ).entries(from: startDate, mode: mode)
    }
}
