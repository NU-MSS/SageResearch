//
//  RSDTaskInfoStep.swift
//  ResearchSuite
//
//  Copyright © 2017-2018 Sage Bionetworks. All rights reserved.
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

/// A completion handler for fetching a task using the task info `fetchTask()` method.
public typealias RSDTaskFetchCompletionHandler = (String, RSDTask?, Error?) -> Void

/// The possible errors thrown when fetching a task.
public enum RSDTaskFetchError : Error {
    
    /// Unknown error
    case unknown
    
    /// The user's device is offline and a network connect is required to fetch the task.
    case offline
}

/// `RSDTaskInfo` includes information to display about a task before the task is fetched.
/// This can be used to display a collection of tasks and only load the task when selected
/// by the participant.
public protocol RSDTaskInfo : RSDCopyWithIdentifier {
    
    /// A short string that uniquely identifies the task.
    var identifier: String { get }
    
    /// The primary text to display for the task in a localized string.
    var title: String? { get }
    
    /// The subtitle text to display for the task in a localized string.
    var subtitle: String? { get }
    
    /// Additional detail text to display for the task. Generally, this would be displayed
    /// while the task is being fetched.
    var detail: String? { get }
    
    /// The estimated number of minutes that the task will take. If `0`, then this is ignored.
    var estimatedMinutes: Int { get }
    
    /// An icon image that can be used for displaying the choice.
    var imageVendor: RSDImageVendor? { get }
    
    /// Optional schema info to pass with the task info for this task.
    var schemaInfo: RSDSchemaInfo? { get }
    
    /// Optional task transformer.
    var resourceTransformer : RSDTaskTransformer? { get }
}

/// `RSDTaskInfoStep` is a reference interface for information about the task. This includes
/// information that can be displayed in a table or collection view before starting the task as
/// well as information that is displayed while the task is being fetched in the case where the
/// task is not fetched using an embedded resource or via a hardcoded task.
public protocol RSDTaskInfoStep : RSDStep {
    
    /// The task info for this step.
    var taskInfo: RSDTaskInfo { get }
    
    /// The task transformer for vending a task. Once this task step is added to a running task,
    /// this value is expected to be non-nil and will fail if not set.
    var taskTransformer: RSDTaskTransformer!  { get }
}
