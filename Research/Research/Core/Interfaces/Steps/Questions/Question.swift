//
//  Question.swift
//  Research
//

import Foundation
import JsonModel
import ResultModel

// TODO: syoung 04/02/2020 Add documentation for the Kotlin interfaces.


public protocol Question : ResultNode {
    var isOptional: Bool { get }
    var isSingleAnswer: Bool { get }
    var answerType: AnswerType { get }
    func buildInputItems() -> [InputItem]
    func instantiateAnswerResult() -> AnswerResult
}

public extension Question {
    func instantiateResult() -> ResultData {
        instantiateAnswerResult()
    }
}

public protocol QuestionStep : Question, RSDUIStep {
}

public extension QuestionStep {
    func instantiateAnswerResult() -> AnswerResult {
        instantiateStepResult() as? AnswerResult ??
            AnswerResultObject(identifier: self.identifier, answerType: self.answerType)
    }
}

public protocol SkipCheckboxQuestion : Question {
    var skipCheckbox: SkipCheckboxInputItem? { get }
}

public protocol SimpleQuestion : SkipCheckboxQuestion {
    var inputItem: InputItemBuilder { get }
}

extension SimpleQuestion {
    
    public var isSingleAnswer: Bool {
        true
    }
    
    public var answerType: AnswerType {
        inputItem.answerType
    }
    
    public func buildInputItems() -> [InputItem] {
        return [inputItem.buildInputItem(for: self), skipCheckbox].compactMap { $0 }
    }
}

public protocol MultipleInputQuestion : SkipCheckboxQuestion {
    var inputItems: [InputItemBuilder] { get }
    var sequenceSeparator: String?  { get }
}

extension MultipleInputQuestion {
    
    public var isSingleAnswer: Bool {
        false
    }
    
    public var answerType: AnswerType {
        AnswerTypeObject()
    }
    
    public func buildInputItems() -> [InputItem] {
        var all = inputItems.map { $0.buildInputItem(for: self) }
        skipCheckbox.map { all.append($0) }
        return all
    }
}

public protocol ChoiceQuestion : Question, RSDChoiceOptions {
    var baseType: JsonType { get }
    var inputUIHint: RSDFormUIHint { get }
    var jsonChoices: [JsonChoice] { get }
}

public extension ChoiceQuestion {
    
    var choices: [RSDChoice] { jsonChoices }
    
    var answerType: AnswerType {
        return isSingleAnswer ? baseType.answerType : AnswerTypeArray(baseType: baseType)
    }
    
    var defaultAnswer: Any? { nil }
    
    func buildInputItems()-> [InputItem] {
        jsonChoices.map {
            ChoiceItemWrapper(choice: $0,
                              answerType: baseType.answerType,
                              isSingleAnswer: isSingleAnswer,
                              uiHint: inputUIHint)
        }
    }
}

public struct ChoiceItemWrapper : ChoiceInputItem {
    public let choice: JsonChoice
    public let answerType: AnswerType
    public let isSingleAnswer: Bool
    public let inputUIHint: RSDFormUIHint
    
    public init(choice: JsonChoice, answerType: AnswerType, isSingleAnswer: Bool, uiHint: RSDFormUIHint) {
        self.choice = choice
        self.answerType = answerType
        self.isSingleAnswer = isSingleAnswer
        self.inputUIHint = uiHint
    }
    
    public var identifier: String? {
        answerValue.map { "\($0)" }
    }
    
    public var fieldLabel: String? {
        choice.text
    }
    
    public var answerValue: Codable? {
        choice.answerValue
    }
    
    public var text: String? {
        choice.text
    }
    
    public var detail: String? {
        choice.detail
    }
    
    public var isExclusive: Bool {
        choice.isExclusive
    }
    
    public var imageData: RSDImageData? {
        choice.imageData
    }
    
    public func isEqualToResult(_ result: ResultData?) -> Bool {
        return choice.isEqualToResult(result)
    }
    
    public func jsonElement(selected: Bool) -> JsonElement? {
        selected ? (choice.matchingValue ?? .null) : nil
    }
}
