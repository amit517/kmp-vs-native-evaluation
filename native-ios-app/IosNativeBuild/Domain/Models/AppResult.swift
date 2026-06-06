//
//  AppResult.swift
//  IosNativeBuild
//
//  Result type matching KMP sealed class Result<T>
//  Named AppResult to avoid conflict with Swift.Result
//

import Foundation

enum AppResult<T> {
    case success(T)
    case error(Error, String?)
    case loading

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

    var isError: Bool {
        if case .error = self { return true }
        return false
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    func getOrNull() -> T? {
        if case .success(let data) = self { return data }
        return nil
    }

    func messageOrNull() -> String? {
        if case .error(_, let message) = self { return message }
        return nil
    }
}

/// Execute an async block and wrap result in AppResult<T>
/// Equivalent to KMP's safeCall
func safeCall<T>(_ block: () async throws -> T) async -> AppResult<T> {
    do {
        let data = try await block()
        return .success(data)
    } catch {
        return .error(error, error.localizedDescription)
    }
}
