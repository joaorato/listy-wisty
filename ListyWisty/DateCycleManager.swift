//
//  DateCycleManager.swift
//  ListyWisty
//
//  Created by João Rato on 27/04/2025.
//

import Foundation
import Combine // For Timer and Cancellable
import SwiftUI // For ObservableObject, @Published

class DateCycleManager: ObservableObject {
    @Published var showModifiedDate: Bool = false // Flips between true/false

    private var timerCancellable: AnyCancellable?
    private let timerInterval: TimeInterval

    init(interval: TimeInterval = 3.0) { // Default interval 3 seconds
        self.timerInterval = interval
    }

    func start() {
        // Invalidate existing timer if any
        stop()
        print("DateCycleManager: Starting timer with interval \(timerInterval)s")
        // Create a timer publisher that runs on the main run loop in common modes (fires during scrolling)
        timerCancellable = Timer.publish(every: timerInterval, on: .main, in: .common)
            .autoconnect() // Starts immediately when subscribed
            .sink { [weak self] _ in
                guard let self = self else { return }
                // Toggle the state on each timer fire
                withAnimation(.easeInOut(duration: 1.5)) { // Animate the change
                   self.showModifiedDate.toggle()
                    print("DateCycleManager: Toggled showModifiedDate to \(self.showModifiedDate)")
                }
            }
    }

    func stop() {
        print("DateCycleManager: Stopping timer.")
        timerCancellable?.cancel()
        timerCancellable = nil
        // Optionally reset state when stopped
        // showModifiedDate = false
    }

    // Deinit to ensure timer stops if manager is destroyed
    deinit {
        print("DateCycleManager: Deinit, stopping timer.")
        stop()
    }
}
