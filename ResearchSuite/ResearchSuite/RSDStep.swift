//
//  RSDStep.swift
//  ResearchSuite
//
//  Copyright © 2017 Sage Bionetworks. All rights reserved.
//
// Redistribution and use in source and binary forms, with or without modification,
// are permitted provided that the following conditions are met:
//
// 1.  Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// 2.  Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation and/or
// other materials provided with the distribution.
//
// 3.  Neither the name of the copyright holder(s) nor the names of any contributors
// may be used to endorse or promote products derived from this software without
// specific prior written permission. No license is granted to the trademarks of
// the copyright holders even if such marks are included in this software.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE
// FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
// DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
// SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
// OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//

import Foundation

/**
 `RSDStep` is the base protocol for the steps that can compose a task for presentation using a controller appropriate to the device and applicaytion. Each `RSDStep` object represents one logical piece of data entry, information, or activity in a larger task.
 
 There are two base implementations included in this SDK. `RSDTaskStep` is used to define a subgrouping of steps such as a section in a longer survey. `RSDUIStep` is used to define a display step. Depending upon the display device, more than one `RSDUIStep` might be shown on a given page. For example, a section of a survey may display multiple fields on an iPad whereas each question in the survey is shown on a new page for an iPhone.
 
 A step can be a question, an active test, or a simple instruction. An `RSDStep` subclass is usually paired with an `RSDStepController` that controls the actions of the step.
 */
public protocol RSDStep {
    
    /**
     A short string that uniquely identifies the step within the task. The identifier is reproduced in the results of a step history.
     
     In some cases, it can be useful to link the step identifier to a unique identifier in a database; in other cases, it can make sense to make the identifier human readable.
     */
    var identifier: String { get }
    
    /**
     A String that indicates the type of the result. This is used to decode the step using a `RSDFactory`.
     */
    var type: String { get }
    
    /**
     Instantiate a step result that is appropriate for this step.
     
     @return    A result for this step.
     */
    func instantiateStepResult() -> RSDResult
    
    /**
     Validate the step to check for any configuration that should throw an error.
     */
    func validate() throws
}


/**
 A step with key/value pairs decoded from a dictionary. This is the default step returned by the factory for an unrecoginized type.
 */
public protocol RSDGenericStep : RSDStep {
    
    /**
     The decoded dictionary.
     */
    var userInfo: [String : Any]? { get }
}


/**
 `RSDSectionStep` is used to define a logical subgrouping of steps such as a section in a longer survey or an active step that includes an instruction step, countdown step, and activity step.
 */
public protocol RSDSectionStep: RSDStep, RSDTask, RSDConditionalStepNavigator {
    
    /**
     A list of the steps used to define this subgrouping of steps.
     */
    var steps: [RSDStep] { get }
}


/**
 `RSDUIStep` is used to define a single "display unit". 
 */
public protocol RSDUIStep: RSDStep, RSDUIActionHandler {
    
    /**
     The primary text to display for the step in a localized string.
     */
    var title: String? { get }
    
    /**
     Additional text to display for the step in a localized string.
     
     The additional text is displayed in a smaller font below `title`. If you need to display a long question, it can work well to keep the title short and put the additional content in the `text` property.
     */
    var text: String? { get }
    
    /**
     Additional detailed explanation for the step.
     
     The font size and display of this property will depend upon the device type.
     */
    var detail: String? { get }
    
    /**
     Additional text to display for the step in a localized string at the bottom of the view.
     
     The footnote is displayed in a smaller font at the bottom of the screen. It is intended to be used in order to include disclaimer, copyright, etc. that is important to display in the step but should not distract from the main purpose of the step.
     */
    var footnote: String? { get }

}


/**
 A step that supports copying information from a dictionary into this step.
 */
public protocol RSDMutableStep: class, RSDStep {
    
    /**
     A step to merge with this step that carries replacement info. This step will look at the replacement info in the generic step and replace properties on self as appropriate.
     */
    func replace(from step: RSDGenericStep) throws
}


/**
 A UI step that supports theme customization of the color and/or images used.
 */
public protocol RSDThemedUIStep : RSDUIStep {
    
    /**
     The view info used to create a custom step.
     */
    var viewTheme: RSDViewThemeElement? { get }
    
    /**
     The color theme (if any).
     */
    var colorTheme: RSDColorThemeElement? { get }
    
    /**
     The image theme (if any).
     */
    var imageTheme: RSDImageThemeElement? { get }
}


/**
 Additional properties used in creating a form input.
 */
public protocol RSDFormUIStep: RSDUIStep {
    
    /**
     The items array is used to hold a logical subgrouping of input fields. If this array holds more than one input field, those fields should describe an input that is uses a logical subgrouping such as blood pressure or given/family name.
     */
    var inputFields: [RSDInputField] { get }
}


/**
 For the case where a `RSDUIStep` has action such as "start walking" or "stop walking", the step may also implement the `SBAActiveUIStep` protocol to allow for spoken instruction.
 */
public protocol RSDActiveUIStep: RSDUIStep {
    
    /**
     The duration of time to run the step. If `0`, then this value is ignored.
     */
    var duration: TimeInterval { get }
    
    /**
     The set of commands to apply to this active step. These indicate actions to fire at the beginning and end of the step such as playing a sound as well as whether or not to automatically start and finish the step.
     */
    var commands: RSDActiveUIStepCommand { get }
    
    /**
     Localized text that represents an instructional voice prompt. Instructional speech begins when the step passes the time indicated by the given time.  If `timeInterval` is greater than or equal to `duration` or is equal to `Double.infinity`, then the spoken instruction should be returned for when the step is finished.
     
     If VoiceOver is active, the instruction is spoken by VoiceOver.
     
     @param timeInterval    The time interval at which to speak the instruction.
     
     @return                The localized instruction to speak.
     */
    func spokenInstruction(at timeInterval: TimeInterval) -> String?
}

/**
 The transformer step is used in decoding a step with replacement properties for some or all of the steps in a section that is defined using a different resource.
 */
public protocol RSDTransformerStep: RSDStep {
    
    /**
     A list of steps keyed by identifier with replacement values for the properties in the step.
     */
    var replacementSteps: [RSDGenericStep]? { get }
    
    /**
     The transformer for the section steps.
     */
    var sectionTransformer: RSDSectionStepTransformer! { get }
}