//
//  StandardPermissionsStep.swift
//  Research
//

import Foundation
import MobilePassiveData

/// `PermissionsStep` extends the `RSDUIStep` to include information about an activity including
/// what permissions are required by this step or task. Without these preconditions, the task cannot
/// measure or collect the data needed for this task.
public protocol StandardPermissionsStep : RSDStep, PermissionsConfiguration {
    
    /// The permissions used by this task.
    var standardPermissions: [StandardPermission]? { get }
}

extension StandardPermissionsStep {
    
    /// List of the permissions required for this action.
    public var permissionTypes: [PermissionType] {
        return standardPermissions?.map { $0.permissionType } ?? []
    }
}
