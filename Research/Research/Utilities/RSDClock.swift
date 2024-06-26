//
//  RSDClock.swift
//  Research
//

import Foundation

#if os(iOS)
import UIKit
#endif

/// The purpose of this struct is to allow using a normalized "uptime" for processes that may need to track
/// the time while the device is asleep. This clock "stopwatch" will keep running even when the device has
/// gone to sleep.
///
/// - seealso: https://stackoverflow.com/questions/12488481/getting-ios-system-uptime-that-doesnt-pause-when-asleep/45068046#45068046
public class RSDClock {
    
    public init() {
        self.timeMarkers = [(RSDClock.uptime(), ProcessInfo.processInfo.systemUptime)]
        self.startDate = Date()
        
        #if os(iOS)
        NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { [weak self] (_) in
            self?.addTimeMarkers(RSDClock.uptime(), ProcessInfo.processInfo.systemUptime)
        }
        #endif
    }
    
    private var timeMarkers: [(clock: TimeInterval, system: TimeInterval)]
    
    /// The absolute start uptime for when this clock was instantiated. This uses the clock time rather than
    /// the system uptime that is used for tasks that will only fire when the device is awake.
    public var startUptime: TimeInterval {
        return timeMarkers[0].clock
    }
    
    /// The system uptime for when the clock was instantiated.
    public var startSystemUptime: TimeInterval {
        return timeMarkers[0].system
    }
    
    /// The date timestamp for when the clock was instantiated.
    public let startDate: Date
    
    /// This will be non-nil if the clock has been paused.
    private var pauseStartTime: TimeInterval?
    
    /// The amount of time that the clock has been paused.
    private var pauseCumulation: TimeInterval = 0
    
    /// Is the clock paused?
    public var isPaused: Bool {
        return pauseStartTime != nil
    }
    
    /// The time interval for how long the step has been running.
    public func runningDuration(for uptime: TimeInterval = RSDClock.uptime()) -> TimeInterval {
        return uptime - startUptime - pauseCumulation
    }
    
    /// Pause the clock.
    public func pause() {
        guard pauseStartTime == nil else { return }
        pauseStartTime = RSDClock.uptime()
    }
    
    /// resume the clock.
    public func resume() {
        guard let pauseTime = pauseStartTime else { return }
        pauseCumulation += (RSDClock.uptime() - pauseTime)
        pauseStartTime = nil
    }
    
    /// Get the clock uptime for a system awake time.
    public func relativeUptime(to systemUptime: TimeInterval) -> TimeInterval {
        let marker = timeMarkers.last { systemUptime >= $0.system } ?? timeMarkers.first!
        return marker.clock + (systemUptime - marker.system)
    }
    
    /// Get the clock uptime for a system awake time.
    public func zeroRelativeTime(to systemUptime: TimeInterval) -> TimeInterval {
        let marker = timeMarkers.last { systemUptime >= $0.system } ?? timeMarkers.first!
        return (systemUptime - marker.system) + (marker.clock - timeMarkers[0].clock)
    }
    
    /// Clock time.
    public static func uptime() -> TimeInterval {
        var uptime = timespec()
        guard 0 == clock_gettime(CLOCK_MONOTONIC_RAW, &uptime) else {
            print("ERROR: Could not execute clock_gettime, errno: \(errno)")
            return 0
        }
        return Double(uptime.tv_sec) + Double(uptime.tv_nsec) * 1.0e-9
    }
    
    // MARK: Test methods
    
    // DO NOT PUBLICLY EXPOSE. Included for testing only. This is a class, not a struct. It is used to
    // allow for shared logic for tracking relative times across different view controllers and recorders
    // and is not intended to be used as a Codable model object.
    
    internal init(clock: TimeInterval, system: TimeInterval, date: Date) {
        self.timeMarkers = [(clock, system)]
        self.startDate = date
    }
    
    internal func addTimeMarkers(_ clock: TimeInterval, _ system: TimeInterval) {
        self.timeMarkers.append((clock, system))
    }
}
