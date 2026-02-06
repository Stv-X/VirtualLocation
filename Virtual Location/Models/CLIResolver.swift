//
//  CLIResolver.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import Foundation

/// 命令行接口解析器
/// 用于查找和验证系统中命令行工具的路径
struct CLIResolver {

    /// 获取Python3可执行文件路径
    /// 首先尝试虚拟环境路径，若找不到则抛出异常
    /// - Returns: Python3可执行文件的URL路径
    /// - Throws: DeviceConnectionManager.DeviceError.binaryNotFound，当找不到Python3时
    static func python3() throws -> URL {
        guard let resourceURL = Bundle.main.resourceURL else {
            throw DeviceConnectionManager.DeviceError.binaryNotFound("Resources directory")
        }
        
        let bundlePythonURL = resourceURL.appendingPathComponent("pymobiledevice3.bundle/venv/bin/python3")
        if FileManager.default.isExecutableFile(atPath: bundlePythonURL.path) {
            return bundlePythonURL
        }
        throw DeviceConnectionManager.DeviceError.binaryNotFound("Python3 in venv")
    }
}
