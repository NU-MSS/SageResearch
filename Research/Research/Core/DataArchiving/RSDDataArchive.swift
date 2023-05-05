//
//  RSDDataArchive.swift
//  Research
//

import Foundation
import JsonModel
import ResultModel


/// A data archive is a class object that can be used to add multiple files to a zipped archive for upload as
/// a package. The data archive could also be a service that implements the logic for uploading results where
/// the results are sent individually. It is the responsibility of the developer who implements this protocol
/// for their services to ensure that the data is cached (if offline) and to re-attempt upload of the
/// encrypted results.
@available(*, deprecated, message: "Support for BridgeSDK archive and export is deprecated. Please use BridgeClient and implement `FileArchivable` directly instead of `RSDArchivable`.")
public protocol RSDDataArchive : AnyObject {
    
    /// A unique identifier for this archive.
    var identifier: String { get }
    
    /// Identifier for this task that can be mapped back to a notification. This may be the same
    /// as the task identifier, or it might be that a task is scheduled multiple times per day,
    /// and the app needs to track what the scheduled timing is for the task.
    var scheduleIdentifier: String? { get }
    
    /// Should the data archive include inserting data for the given reserved filename?
    func shouldInsertData(for filename: RSDReservedFilename) -> Bool
    
    /// Method for adding data to an archive.
    /// - parameters:
    ///     - data: The data to insert.
    ///     - manifest: The file manifest for this data.
    func insertDataIntoArchive(_ data: Data, manifest: RSDFileManifest) throws
    
    /// Mark the archive as completed.
    /// - parameter metadata: The metadata for this archive.
    func completeArchive(with metadata: RSDTaskMetadata) throws
    
    /// Returns an archivable object for the given result.
    ///
    /// - parameters:
    ///     - result: The result to archive.
    ///     - sectionIdentifier: The section identifier for the task.
    ///     - stepPath: The full step path to the given result.
    /// - returns: An archivable object or `nil` if the result should be skipped.
    func archivableData(for result: ResultData, sectionIdentifier: String?, stepPath: String?) -> RSDArchivable?
}

/// An archivable result is an object wrapper for results that allows them to be transformed into
/// data for a zipped archive or service.
@available(*, deprecated, message: "Support for BridgeSDK archive and export is deprecated. Please use BridgeClient and implement `FileArchivable` directly instead of `RSDArchivable`.")
public protocol RSDArchivable : FileArchivable {
    
    /// Build the archiveable or uploadable data for this result.
    func buildArchiveData(at stepPath: String?) throws -> (manifest: RSDFileManifest, data: Data)?
}

@available(*, deprecated, message: "Support for BridgeSDK archive and export is deprecated. Please use BridgeClient and implement `FileArchivable` directly instead of `RSDArchivable`.")
extension RSDArchivable {
    
    /// Convenience method for calling `buildArchiveData()` without a step path.
    public func buildArchiveData() throws -> (manifest: RSDFileManifest, data: Data)? {
        return try self.buildArchiveData(at: nil)
    }
    
    /// Implement the newer protocol that is not dependent on SageResearch.
    public func buildArchivableFileData(at stepPath: String?) throws -> (fileInfo: FileInfo, data: Data)? {
        try self.buildArchiveData(at: stepPath).map {
            (.init(from: $0.manifest), $0.data)
        }
    }
}

@available(*, deprecated, message: "Support for BridgeSDK archive and export is deprecated. Please use BridgeClient and implement `FileArchivable` directly instead of `RSDArchivable`.")
internal class TaskArchiver : NSObject {
    
    let manager: RSDDataArchiveManager
    let taskResult: RSDTaskResult
    let archive: RSDDataArchive?
    
    fileprivate var childArchives: [RSDDataArchive] = []
    fileprivate var files: Set<RSDFileManifest> = []
    fileprivate var answerMap: [String : JsonElement] = [:]
    
    init(manager: RSDDataArchiveManager, taskResult: RSDTaskResult, scheduleIdentifier: String?) {
        self.archive = manager.dataArchiver(for: taskResult, scheduleIdentifier: scheduleIdentifier, currentArchive: nil)
        self.taskResult = taskResult
        self.manager = manager
        super.init()
    }
    
    init?(manager: RSDDataArchiveManager, taskResult: RSDTaskResult, inputArchive: RSDDataArchive?) {
        guard let archive = manager.dataArchiver(for: taskResult, scheduleIdentifier: nil, currentArchive: inputArchive),
            (archive.identifier != inputArchive?.identifier)
            else {
                return nil
        }
        self.taskResult = taskResult
        self.manager = manager
        self.archive = archive
        super.init()
    }
    
    func buildArchives() throws -> [RSDDataArchive] {
        
        // recursively add all the archives to this archiver.
        try recursiveAddFunc(nil, nil, nil, taskResult.stepHistory)
        if self.archive != nil, let asyncResults = taskResult.asyncResults {
            try recursiveAddFunc(nil, nil, nil, asyncResults)
        }
        
        // The archives include any child archives
        var archives = childArchives
        
        if let archive = self.archive {
            do {
                // Check if there are any answers to add.
                if answerMap.count > 0, archive.shouldInsertData(for: .answers) {
                    let data = try answerMap.jsonEncodedData()
                    let manifest = RSDFileResultUtility.fileManifest(for: .answers)
                    try archive.insertDataIntoArchive(data, manifest: manifest)
                    self.files.insert(manifest)
                }
                
                // Check if there is a task result to add.
                if archive.shouldInsertData(for: .taskResult) {
                    let data = try taskResult.jsonEncodedData()
                    let manifest = RSDFileResultUtility.fileManifest(for: .taskResult)
                    try archive.insertDataIntoArchive(data, manifest: manifest)
                    self.files.insert(manifest)
                }
                
                // Only include the task archive if it is not empty.
                let metadata = RSDTaskMetadata(taskResult: self.taskResult, files: Array(self.files))
                try archive.completeArchive(with: metadata)
                archives.insert(archive, at: 0)
                
            } catch let err {
                // If this is not swallowed, then rethrow the error.
                // Otherwise, ignore the failure to add the archive and continue.
                if !manager.shouldContinueOnFail(for: archive, error: err) {
                    throw err
                }
            }
        }
        
        return archives
    }
    
    func recursiveAddFunc(_ sectionIdentifier: String?, _ collectionIdentifier: String?, _ stepPath: String?, _ results: [ResultData]) throws {
        for result in results {
            if let taskResult = result as? RSDTaskResult {
                if let subArchiver = TaskArchiver(manager: manager, taskResult: taskResult, inputArchive: archive) {
                    // If there is an archiver for this subtask, then append the archives with that result.
                    let archives = try subArchiver.buildArchives()
                    self.childArchives.append(contentsOf: archives)
                }
                else {
                    // Otherwise, recurse into the task result and add its results to this archive.
                    let path = (stepPath != nil) ? "\(stepPath!)/\(taskResult.identifier)" : taskResult.identifier
                    try recursiveAddFunc(taskResult.identifier, nil, path, taskResult.stepHistory)
                    if let asyncResults = taskResult.asyncResults {
                        try recursiveAddFunc(taskResult.identifier, nil, path, asyncResults)
                    }
                }
            }
            else {
                try addToArchive(sectionIdentifier, collectionIdentifier, stepPath, result)
            }
        }
    }
    
    func addToArchive(_ sectionIdentifier: String?, _ collectionIdentifier: String?, _ stepPath: String?, _ result: ResultData) throws {
        // If there is no archive for this level, then all the non-task results are ignored.
        guard let archive = self.archive else { return }
        
        // Look to see if the result conforms to the archivable protocol or the collection
        // protocol. If it conforms to both, then *only* archive it at this level and do not
        // recurse into the result.
        if let archivable = archive.archivableData(for: result, sectionIdentifier: sectionIdentifier, stepPath: stepPath) {
            do {
                if let (manifest, data) = try archivable.buildArchiveData(at: stepPath) {
                    try self.archive?.insertDataIntoArchive(data, manifest: manifest)
                    self.files.insert(manifest)
                }
            } catch let err {
                // If this is not swallowed, then rethrow the error
                if !manager.shouldContinueOnFail(for: archive, error: err) {
                    throw err
                }
            }
        }
        else if let fileArchivable = result as? FileArchivable {
            do {
                if let (fileInfo, data) = try fileArchivable.buildArchivableFileData(at: stepPath) {
                    let manifest = RSDFileManifest(from: fileInfo)
                    try self.archive?.insertDataIntoArchive(data, manifest: manifest)
                    self.files.insert(manifest)
                }
            } catch let err {
                // If this is not swallowed, then rethrow the error
                if !manager.shouldContinueOnFail(for: archive, error: err) {
                    throw err
                }
            }
        }
        else if let collection = result as? CollectionResult {
            let path = (stepPath != nil) ? "\(stepPath!)/\(collection.identifier)" : collection.identifier
            try recursiveAddFunc(sectionIdentifier, collection.identifier, path, collection.children)
        }
        
        // If this result conforms to the answer result protocol then add it to the answer map
        if let answerResult = result as? AnswerResult,
           let answer = try answerResult.encodingValue(), answer != .null {
            let answerIdentifier = self.answerIdentifier(for: result.identifier, sectionIdentifier, collectionIdentifier)
            answerMap[answerIdentifier] = answer
        }
    }
    
    private func answerIdentifier(for resultIdentifier: String,
                                  _ sectionIdentifier: String?,
                                  _ collectionIdentifier: String?) -> String {
        if let key = self.manager.answerKey?(for: resultIdentifier, with: sectionIdentifier) {
            return key
        }
        let sectionPrefix = (sectionIdentifier != nil) ? "\(sectionIdentifier!)_" : ""
        let collectionPrefix = (collectionIdentifier != nil && collectionIdentifier != resultIdentifier) ? "\(collectionIdentifier!)_" : ""
        return "\(sectionPrefix)\(collectionPrefix)\(resultIdentifier)"
    }
}

