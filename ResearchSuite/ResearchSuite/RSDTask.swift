//
//  RSDTask.swift
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
 This is the interface for running a task. It includes information about how to calculate progress, validation, and the order of display for the steps.
 */
public protocol RSDTask : RSDUIActionHandler {
    
    /**
     A short string that uniquely identifies the task.
     */
    var identifier: String { get }
    
    /**
     Additional information about the task.
     */
    var taskInfo: RSDTaskInfoStep? { get }
    
    /**
     Additional information about the result schema.
     */
    var schemaInfo: RSDSchemaInfo? { get }
    
    /**
     The step navigator for this task.
     */
    var stepNavigator: RSDStepNavigator { get }
    
    /**
     A list of asynchronous actions to run on the task.
     */
    var asyncActions: [RSDAsyncActionConfiguration]? { get }
    
    /**
     Instantiate a task result that is appropriate for this task.
     
     @return    A task result for this task.
     */
    func instantiateTaskResult() -> RSDTaskResult

    /**
     Validate the task to check for any model configuration that should throw an error.
     */
    func validate() throws
}

extension RSDTask {
    
    public func asyncActionsToStart(at step: RSDStep, isFirstStep: Bool) -> [RSDAsyncActionConfiguration] {
        guard let actions = self.asyncActions else { return [] }
        return actions.filter {
            ($0.startStepIdentifier == step.identifier) || ($0.startStepIdentifier == nil && isFirstStep)
        }
    }
    
    public func asyncActionsToStop(after step: RSDStep?) -> [RSDAsyncActionConfiguration] {
        guard let actions = self.asyncActions else { return [] }
        return actions.filter {
            guard let recorder = $0 as? RSDRecorderConfiguration else { return false }
            if recorder.stopStepIdentifier == nil && step == nil {
                return true
            } else if let stopIdentifier = recorder.stopStepIdentifier,
                let stepIdentifier = step?.identifier {
                return stopIdentifier == stepIdentifier
            } else {
                return false
            }
        }
    }
}