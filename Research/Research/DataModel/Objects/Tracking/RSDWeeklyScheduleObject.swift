//
//  RSDWeeklyScheduleObject.swift
//  Research
//

import Foundation
import JsonModel

/// A weekly schedule item is a lightweight codable struct that can be used to store and track events
/// that happen at regularily scheduled intervals. This schedule assumes a ISO8601 7-day calendar.
///
/// - example: `Codable` protocol schema.
/// ```
///    let json = """
///            {
///                "daysOfWeek": ["Sunday", "Tuesday", "Thursday"],
///                "timeOfDay": "08:00"
///            }
///            """.data(using: .utf8)! // our data in native (JSON) format
/// ```
public struct RSDWeeklyScheduleObject : Codable, RSDSchedule {
    
    private enum CodingKeys : String, CodingKey, CaseIterable {
        case daysOfWeek, timeOfDayString = "timeOfDay"
    }
    
    /// The days of the week to include in the schedule. By default, this will be set to daily.
    public var daysOfWeek: Set<RSDWeekday> = RSDWeekday.all
    
    /// The time of the day as a string with the format "HH:mm".
    public var timeOfDayString: String?
    
    /// Return the current time zone.
    public var timeZone: TimeZone {
        return TimeZone.current
    }
    
    /// Is this a daily scheduled item?
    public var isDaily: Bool {
        return self.daysOfWeek == RSDWeekday.all
    }
    
    /// Get an array of the date components to use to set up notification triggers. This will return a
    /// `DateComponents` for each day of the week, unless the reminder should be posted daily.
    ///
    /// - note: The date components will *not* include the participant's current timezone.
    /// - returns: The date components to use to set up a trigger for each scheduling instance.
    public func notificationTriggers() -> [DateComponents] {
        guard let timeComponents = self.timeComponents
            else {
                return []
        }
        
        if isDaily {
            // A daily scheduled trigger will include *only* the day and time.
            return [timeComponents]
        }
        else {
            // If this is scheduled for one or more days of the week then need to build a reminder for
            // each.
            return self.daysOfWeek.map {
                var dateComponents = timeComponents
                dateComponents.weekday = $0.rawValue
                return dateComponents
            }
        }
    }
    
    /// Set the weekdays by converting from Any array.
    mutating public func setWeekdays(from value: [Any]?) {
        if let weekdays = value as? Array<RSDWeekday> {
            self.daysOfWeek = Set(weekdays)
        } else if let weekdays = value as? Array<Int> {
            self.daysOfWeek = weekdays.rsd_flatMapSet { RSDWeekday(rawValue: $0) }
        } else {
            self.daysOfWeek = RSDWeekday.all
        }
    }
    
    public init(timeOfDayString: String? = nil, daysOfWeek: Set<RSDWeekday> = RSDWeekday.all) {
        self.timeOfDayString = timeOfDayString
        self.daysOfWeek = daysOfWeek
    }
}

extension RSDWeeklyScheduleObject : Hashable, Comparable {
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(daysOfWeek)
        hasher.combine(timeOfDayString ?? "")
    }
    
    public static func ==(lhs: RSDWeeklyScheduleObject, rhs: RSDWeeklyScheduleObject) -> Bool {
        return lhs.daysOfWeek == rhs.daysOfWeek && lhs.timeOfDayString == rhs.timeOfDayString
    }
    
    public static func <(lhs: RSDWeeklyScheduleObject, rhs: RSDWeeklyScheduleObject) -> Bool {
        guard let lTime = lhs.timeOfDayString else { return (rhs.timeOfDayString != nil) }
        guard let rTime = rhs.timeOfDayString else { return false }
        return lTime < rTime
    }
}

/// `RSDWeeklyScheduleFormatter` can be used to display formatted text for a weekly schedule item.
public class RSDWeeklyScheduleFormatter : Formatter {
    
    /// The style of the display text for a weekly schedule item.
    ///
    /// - example:
    ///     - long: "Thursday, Friday, and Saturday at 4:00 PM and 7:00 PM"
    ///     - medium: "4:00 PM, 7:30 PM\n Thursday, Friday, Saturday"
    ///     - short: "4:00 PM, 7:30 PM, Thu, Fri, Sat"
    public var style : DateFormatter.Style! {
        get { return _style }
        set { _style = newValue ?? .medium }
    }
    private var _style : DateFormatter.Style = .medium
    
    /// Formatted string for a weekly schedule item.
    public func string(from weeklySchedule: RSDWeeklyScheduleObject) -> String? {
        return string(from: [weeklySchedule])
    }
    
    /// Formatted string for an array of weekly schedule items.
    public func string(from weeklySchedules: [RSDWeeklyScheduleObject]) -> String? {
        let daysOfWeek = Set(weeklySchedules.map { $0.daysOfWeek })
        if daysOfWeek.count == 1 {
            let days = daysOfWeek.first!
            let daysString = _joinedDays(days, style: _style)
            let timesString = _joinedTimes(weeklySchedules)
            return _joinString(days: daysString, times: timesString, style: _style)
        } else {
            let formatterStyle = (_style == .medium) ? .short : _style
            let schedules = weeklySchedules.compactMap { (item) -> String? in
                let daysString = _joinedDays(item.daysOfWeek, style: formatterStyle)
                let timesString = _joinedTimes([item])
                return _joinString(days: daysString, times: timesString, style: formatterStyle)
            }
            return schedules.joined(separator: "\n")
        }
    }
    
    /// Formatted string from a set of integers for each weekday.
    public func string(from days: Set<Int>) -> String? {
        let daysOfWeek = days.rsd_flatMapSet { RSDWeekday(rawValue: $0) }
        return _joinedDays(daysOfWeek, style: _style)
    }
    
    /// Formatted string from a set of weekday objects.
    public func string(from daysOfWeek: Set<RSDWeekday>) -> String? {
        return _joinedDays(daysOfWeek, style: _style)
    }
    
    private func _joinString(days: String?, times: String?, style: DateFormatter.Style) -> String? {
        if let days = days, let times = times {
            switch style {
            case .full, .long:
                return String.localizedStringWithFormat(Localization.localizedString("SCHEDULE_FORMAT_%1$@_at_%2$@"), days, times)
            case .medium, .none:
                return "\(times)\n\(days)"
            case .short:
                return "\(times), \(days)"
            @unknown default:
                return "\(times), \(days)"
            }
        } else {
            return days ?? times
        }
    }
    
    private func _joinedDays(_ daysOfWeek: Set<RSDWeekday>, style: DateFormatter.Style) -> String? {
        guard daysOfWeek.count > 0 else {
            return nil
        }
        if daysOfWeek == RSDWeekday.all {
            return Localization.localizedString("SCHEDULE_EVERY_DAY")
        }
        switch style {
        case .full, .long:
            let days = daysOfWeek.sorted().map { $0.text! }
            return Localization.localizedAndJoin(days)
        case .medium, .none:
            let days = daysOfWeek.sorted().map { $0.text! }
            let delimiter = Localization.localizedString("LIST_FORMAT_DELIMITER")
            return days.joined(separator: delimiter)
        case .short:
            let days = daysOfWeek.sorted().map { $0.shortText! }
            let delimiter = Localization.localizedString("LIST_FORMAT_DELIMITER")
            return days.joined(separator: delimiter)
        @unknown default:
            let days = daysOfWeek.sorted().map { $0.shortText! }
            let delimiter = Localization.localizedString("LIST_FORMAT_DELIMITER")
            return days.joined(separator: delimiter)
        }
    }
    
    private func _joinedTimes(_ weeklySchedules: [RSDWeeklyScheduleObject]) -> String? {
        let times = weeklySchedules.compactMap { $0.localizedTime() }
        if _style == .full || _style == .long {
            return Localization.localizedAndJoin(times)
        } else {
            let delimiter = Localization.localizedString("LIST_FORMAT_DELIMITER")
            return times.joined(separator: delimiter)
        }
    }
    
    /// Override to provide generic formatter for formatting a string.
    override public func string(for obj: Any?) -> String? {
        if let schedules = obj as? [RSDWeeklyScheduleObject] {
            return self.string(from: schedules)
        } else if let schedule = obj as? RSDWeeklyScheduleObject {
            return self.string(from: schedule)
        } else if let days = obj as? Array<Int> {
            return self.string(from: Set(days))
        } else if let days = obj as? Set<Int> {
            return self.string(from: days)
        } else {
            return nil
        }
    }
}

extension RSDWeeklyScheduleObject : DocumentableStruct {
    public static func codingKeys() -> [CodingKey] {
        CodingKeys.allCases
    }
    
    public static func isRequired(_ codingKey: CodingKey) -> Bool {
        guard let key = codingKey as? CodingKeys else { return false }
        return key == .daysOfWeek
    }
    
    public static func documentProperty(for codingKey: CodingKey) throws -> DocumentProperty {
        guard let key = codingKey as? CodingKeys else {
            throw DocumentableError.invalidCodingKey(codingKey, "\(codingKey) is not recognized for this class")
        }
        switch key {
        case .daysOfWeek:
            return .init(propertyType: .referenceArray(RSDWeekday.documentableType()))
        case .timeOfDayString:
            return .init(propertyType: .primitive(.string))
        }
    }
    
    public static func examples() -> [RSDWeeklyScheduleObject] {
        let exampleA = RSDWeeklyScheduleObject()
        var exampleB = RSDWeeklyScheduleObject()
        exampleB.daysOfWeek = [.monday, .friday]
        exampleB.timeOfDayString = "08:20"
        return [exampleA, exampleB]
    }
}
