//
//  DeviceCommandRunner.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import Foundation

final class DeviceCommandRunner {
    func run(arguments: [String]) async throws -> String {
        let process = Process()
        process.executableURL = try CLIResolver.python3()

        var env = ProcessInfo.processInfo.environment
        env["PYTHONUNBUFFERED"] = "1" // 确保实时输出
        // 如果用户使用 brew 安装，可能需要补充 PATH
        if let path = env["PATH"] {
            env["PATH"] = path + ":/usr/local/bin:/opt/homebrew/bin"
        } else {
            env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
        }
        process.environment = env

        process.arguments = arguments

        let outputPipe = Pipe()
        let errorPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        return try await withCheckedThrowingContinuation { continuation in
            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                let output = String(data: outputData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                let errorMsg = String(data: errorData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                if process.terminationStatus == 0 {
                    continuation.resume(returning: output)
                } else {
                    let fullError = errorMsg.isEmpty ? output : errorMsg
                    continuation.resume(throwing: DeviceConnectionManager.DeviceError.commandFailed(fullError))
                }
            }
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: error)
            }
        }
    }
}
