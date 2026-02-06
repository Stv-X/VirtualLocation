//
//  DeviceCommandRunner.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftUI
import MapKit

@Observable
final class DeviceConnectionManager {
    public static let shared = DeviceConnectionManager()

    // MARK: - Device Properties
    private let runner = DeviceCommandRunner()
    var isBusy = false
    var isConnected = false
    var deviceLastError: String?
    var devices: [Device] = []
    var selectedDevice: Device?
    
    // MARK: - Tunnel Properties
    var tunnelStatus: TunnelManagerStatus = .stop
    var connectionOption: TunnelConnectionOption?
    var tunnelOutputLog = ""
    
    private var tunnelProcess: Process?
    private let pythonPath = "~/pymobiledevice3/venv/bin/python3"
    
    // MARK: - Device Methods
    enum DeviceError: LocalizedError {
        case binaryNotFound(String)
        case commandFailed(String)
        case invalidOutput(String)
        case jsonParsingFailed
        
        var errorDescription: String? {
            switch self {
            case .binaryNotFound(let name):
                return "Missing CLI binary: \(name). Ensure pymobiledevice3 is installed."
            case .commandFailed(let message):
                return message
            case .invalidOutput(let output):
                return "Unexpected output: \(output)"
            case .jsonParsingFailed:
                return "Failed to parse device list JSON."
            }
        }
    }
    
    func refreshDevices() async {
        isBusy = true
        devices = []
        selectedDevice = nil
        defer { isBusy = false }
        do {
            // 修改参数：[python3] -m pymobiledevice3 usbmux list ...
            let arguments = ["-m", "pymobiledevice3", "usbmux", "list"]
            
            let output = try await runner.run(arguments: arguments)
            
            // 解析 JSON 输出
            guard let data = output.data(using: .utf8) else {
                throw DeviceError.invalidOutput(output)
            }
            
            devices = try JSONDecoder().decode([Device].self, from: data)
            devices = devices.deduplicated()
            
            if UserDefaults.standard.bool(forKey: "usbOnly") {
                devices = devices.filter { $0.connectionType == "USB" }
            }
            
            // 优先选择 USB 连接的设备，或者列表中的第一个
            let firstDevice = devices.sorted {
                ($0.connectionType == "USB" ? 0 : 1) < ($1.connectionType == "USB" ? 0 : 1)
            }.first
            selectedDevice = firstDevice
            isConnected = firstDevice != nil
            deviceLastError = nil
        } catch {
            print("Refresh Error: \(error)")
            selectedDevice = nil
            isConnected = false
            // 如果是 JSON 解析错误，可能是因为没有连接设备导致输出为空或格式不同，降级处理
            if let outputError = error as? DeviceError, case .invalidOutput = outputError {
                 deviceLastError = "No devices found or invalid output."
            } else {
                deviceLastError = error.localizedDescription
            }
        }
    }
    
    func setVirtualLocation(
        coordinate: CLLocationCoordinate2D,
        deviceId: String?
    ) async throws {
        guard let connectionOption = self.connectionOption else {
            throw DeviceError.commandFailed("No tunnel connection established.")
        }
        
        let baseArgs = ["-m", "pymobiledevice3"]
        var locationArgs = baseArgs + ["developer"]
        locationArgs.append("dvt")
        locationArgs.append("simulate-location")
        
        locationArgs.append(contentsOf: ["set", String(format: "%.6f", coordinate.latitude), String(format: "%.6f", coordinate.longitude)])
        locationArgs.append(contentsOf: ["--rsd", connectionOption.rsdAddress, connectionOption.rsdPort])
        
        let output = try await runner.run(arguments: locationArgs)
        
        // 简单的错误检查：如果输出包含 Traceback 或 Error，则视为失败
        if output.contains("Traceback") || output.lowercased().contains("error:") {
            deviceLastError = output
            throw DeviceError.commandFailed(output)
        } else {
            deviceLastError = nil
        }
    }
    
    func clearVirtualLocation(deviceId: String?) async throws {
        let udid = deviceId ?? selectedDevice?.uniqueDeviceId
        
        var args = ["developer"]
        args.append("dvt")
        args.append(contentsOf: ["simulate-location", "clear"])
        
        if let udid {
            args.insert("--udid", at: 0)
            args.insert(udid, at: 1)
        }
        
        let _ = try await runner.run(arguments: args)
    }
    
    // MARK: - Tunnel Methods
    func startTunnel(for udid: String) {
        guard tunnelStatus == .stop else { return }
        // 重置状态
        tunnelStatus = .loading
        tunnelOutputLog = ""
        connectionOption = nil
        
        let process = Process()
        let fullPythonPath = (pythonPath as NSString).expandingTildeInPath
        
        process.executableURL = URL(fileURLWithPath: "/usr/bin/sudo")
        process.arguments = [
            fullPythonPath, "-m", "pymobiledevice3",
            "remote", "start-tunnel", "--udid", udid
        ]
        
        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe // 合并错误输出以便调试
        process.standardInput = Pipe()
        
        setupTunnelOutputHandlers(pipe: outputPipe)
        
        do {
            try process.run()
            self.tunnelProcess = process
            
            process.terminationHandler = { [weak self] _ in
                DispatchQueue.main.async {
                    self?.tunnelStatus = .stop
                }
            }
        } catch {
            self.tunnelStatus = .stop
            self.tunnelOutputLog = "Failed to start: \(error.localizedDescription)"
        }
    }
    
    private func setupTunnelOutputHandlers(pipe: Pipe) {
        pipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            guard let self = self,
                  let line = String(data: data, encoding: .utf8), !line.isEmpty else { return }
            
            DispatchQueue.main.async {
                self.tunnelOutputLog += line
                self.parseTunnelOutput(line)
            }
        }
    }
    
    private func parseTunnelOutput(_ text: String) {
        let lines = text.components(separatedBy: .newlines)
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // 匹配模式: --rsd 后跟空格，捕获第一个参数(地址)，再跟空格，捕获第二个参数(端口)
            // [^ ]+ 表示匹配非空格的连续字符
            let pattern = /--rsd\s+(?<address>[^\s]+)\s+(?<port>\d+)/
            
            if let match = trimmed.firstMatch(of: pattern) {
                let address = String(match.output.address)
                let port = String(match.output.port)
                
                self.connectionOption = TunnelConnectionOption(
                    rsdAddress: address,
                    rsdPort: port
                )
                
                self.tunnelStatus = .ready
            }
        }
    }
    
    func stopTunnel() {
        tunnelProcess?.terminate()
        tunnelProcess = nil
        tunnelStatus = .stop
        connectionOption = nil
    }

    enum TunnelManagerStatus: String {
        case stop    // 进程未启动或已结束
        case loading // 进程已启动，正在等待关键输出
        case ready   // 已成功捕获到连接参数
    }

    struct TunnelConnectionOption {
        var rsdAddress: String
        var rsdPort: String
    }
}
