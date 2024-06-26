//
//  RSDFormUIHint.swift
//  Research
//

import Foundation
import JsonModel

/// The `RSDFormUIHint` enum is a key word that can be used to describe the preferred UI for a form input field.
/// This is intended as a "hint" that the designers and developers can use to indicate the preferred input style
/// for an input field. Not all ui hints are applicable to all data types or devices, and therefore the ui hint
/// may be ignored by the application displaying the input field to the user.
///
public struct RSDFormUIHint : RawRepresentable, Codable, Hashable {

    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    enum StandardHints : String, Codable, CaseIterable {
        case button, checkbox, checkmark, combobox, disclosureArrow, link, list, multipleLine, picker, popover, radioButton, section, slider, textfield, toggle
        
        var hint: RSDFormUIHint {
            return RSDFormUIHint(rawValue: self.rawValue)
        }
    }
    
    /// Input field of a button-style cell that can be used to display a detail view.
    public static let button = StandardHints.button.hint
    
    /// List with a checkbox next to each item.
    public static let checkbox = StandardHints.checkbox.hint
    
    /// List with a checkmark next to each item that is selected.
    public static let checkmark = StandardHints.checkmark.hint
    
    /// Drop-down with a textfield for "other".
    public static let combobox = StandardHints.combobox.hint
    
    /// Input field of a disclosure arrow cell that can be used to display a detail view.
    public static let disclosureArrow = StandardHints.disclosureArrow.hint
    
    /// Input field of a link-style cell that can be used to display a detail view.
    public static let link = StandardHints.link.hint
    
    /// List of selectable cells.
    public static let list = StandardHints.list.hint
    
    /// Multiple line text view.
    public static let multipleLine = StandardHints.multipleLine.hint
    
    /// Text field with a picker wheel as the keyboard.
    public static let picker = StandardHints.picker.hint
    
    /// Text entry using a modal popover box.
    public static let popover = StandardHints.popover.hint
    
    /// Radio button.
    public static let radioButton = StandardHints.radioButton.hint
    
    /// Input field for a "detail" that is displayed inline as a section.
    public static let section = StandardHints.section.hint
    
    /// Slider.
    public static let slider = StandardHints.slider.hint
    
    /// Text field.
    public static let textfield = StandardHints.textfield.hint
    
    /// Toggle (segmented) button.
    public static let toggle = StandardHints.toggle.hint
    
    /// A list of all the `RSDFormUIHint` values that are standard hints.
    public static var allStandardHints: Set<RSDFormUIHint> {
        return Set(StandardHints.allCases.map { $0.hint })
    }
    
    static func standardHintCategories() -> [String : [RSDFormUIHint]] {
        return [
            "choice" : [.list, .checkbox, .checkmark, .combobox, .radioButton],
            "picker" : [.picker, .slider],
            "text" : [.textfield, .multipleLine, .popover],
            "detail" : [.section, .disclosureArrow, .button, .link],
        ]
    }
    
    /// If the hint is not in the supported list, then look for an acceptable alternative.
    func bestHint(from supportedHints: Set<RSDFormUIHint>?) -> RSDFormUIHint {
        guard let supportedHints = supportedHints, !supportedHints.contains(self) else {
            return self
        }
        guard let matchingHints = RSDFormUIHint.standardHintCategories().first(where: { $0.value.contains(self) }),
            let matching = matchingHints.value.first(where: { supportedHints.contains($0) })
            else {
                debugPrint("WARNING!!! Could not find a UIHint to use as a replacement for \(self) that matches the supported hints: \(supportedHints)")
                return self
        }
        return matching
    }
}

extension RSDFormUIHint : Equatable {
    public static func ==(lhs: RSDFormUIHint, rhs: RSDFormUIHint) -> Bool {
        return lhs.rawValue == rhs.rawValue
    }
    public static func ==(lhs: String, rhs: RSDFormUIHint) -> Bool {
        return lhs == rhs.rawValue
    }
    public static func ==(lhs: RSDFormUIHint, rhs: String) -> Bool {
        return lhs.rawValue == rhs
    }
}

extension RSDFormUIHint : ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        self.init(rawValue: value)
    }
}

extension RSDFormUIHint : DocumentableStringLiteral {
    public static func examples() -> [String] {
        allStandardHints.map { $0.rawValue }
    }
}
