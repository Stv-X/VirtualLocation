//
//  Inspector.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftUI

struct Inspector: View {
    @Environment(DeviceConnectionManager.self) var deviceConnectionManager

    @AppStorage("usbOnly") private var usbOnly = true

    @State private var showOSBuildVersion = false
    @State private var showTunnelStatus = false
    @State private var showAdcancedOptions = false
    
    var body: some View {
        Form {
            Section("Device") {
                HStack {
                    let statusColor = deviceConnectionManager.isConnected ? deviceConnectionManager.tunnelStatus == .ready ? Color.green : Color.orange : Color.gray
                    let statusText = deviceConnectionManager.isConnected ? deviceConnectionManager.tunnelStatus == .ready ? "Ready" : "Loading" : "Disconnected"
                    Circle()
                        .fill(statusColor)
                        .frame(width: 10, height: 10)
                    Text(statusText)
                    Spacer()
                    if deviceConnectionManager.isBusy {
                        ProgressView().controlSize(.small)
                    } else {
                        Button("Refresh", systemImage: "arrow.clockwise") {
                            deviceConnectionManager.stopTunnel()
                            Task { await deviceConnectionManager.refreshDevices() }
                        }
                        .labelStyle(.iconOnly)
                        .buttonBorderShape(.circle)
                        .disabled(deviceConnectionManager.isBusy)
                    }
                }

                if deviceConnectionManager.isConnected {
                    @Bindable var bindableDeviceConnectionManager = deviceConnectionManager
                    Picker("Select Device", selection: $bindableDeviceConnectionManager.selectedDevice) {
                        ForEach(deviceConnectionManager.devices) { device in
                            let deviceIcon = switch device.deviceClass {
                            case "iPhone": "iphone"
                            case "iPad": "ipad"
                            default: "macbook"
                            }
                            Label(device.deviceName, systemImage: deviceIcon)
                                .tag(device)
                        }
                    }
                    if let selectedDevice = deviceConnectionManager.selectedDevice {
                        LabeledContent("Connection") {
                            switch selectedDevice.connectionType {
                            case "Network":
                                Label("Network", systemImage: "network")
                            case "USB":
                                Label("USB", systemImage: "cable.connector")
                            default:
                                Label("Unknown", systemImage: "questionmark")
                            }
                        }
                        LabeledContent("Model") {
                            Text(selectedDevice.localizedModel)
                        }
                        LabeledContent("\(selectedDevice.systemName) Version") {
                            Text("\(selectedDevice.productVersion)\(showOSBuildVersion ? " (\(selectedDevice.buildVersion))" : "")")
                        }
                        .onTapGesture { showOSBuildVersion.toggle() }
                    }
                }
                if let error = deviceConnectionManager.deviceLastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            Section("Tunnel Status", isExpanded: $showTunnelStatus) {
                statusHeader
                @Bindable var bindableDeviceConnectionManager = deviceConnectionManager
                if !deviceConnectionManager.tunnelOutputLog.isEmpty {
                    ScrollView {
                        Text(bindableDeviceConnectionManager.tunnelOutputLog)
                            .fontDesign(.monospaced)
                            .padding(4)
                    }
                    .frame(maxHeight: 100)
                    .glassEffect(.clear, in: .rect(cornerRadius: 8))
                }
            }
            Section("Advanced Options", isExpanded: $showAdcancedOptions) {
                Toggle("USB Only", isOn: $usbOnly)
                    .onChange(of: usbOnly) {
                        deviceConnectionManager.stopTunnel()
                        Task { await deviceConnectionManager.refreshDevices() }
                    }
            }
        }
        .onChange(of: deviceConnectionManager.selectedDevice) {
            deviceConnectionManager.stopTunnel()
            if let udid = deviceConnectionManager.selectedDevice?.uniqueDeviceId {
                deviceConnectionManager.startTunnel(for: udid)
            }
        }
    }
    private var statusHeader: some View {
        HStack {
            statusIcon
            Text("Status: \(deviceConnectionManager.tunnelStatus.rawValue.capitalized)")
            Spacer()
            Button(deviceConnectionManager.tunnelStatus == .stop ? "Start Service" : "Stop Service") {
                if deviceConnectionManager.tunnelStatus != .stop {
                    deviceConnectionManager.stopTunnel()
                } else {
                    if let udid = deviceConnectionManager.selectedDevice?.uniqueDeviceId {
                        deviceConnectionManager.startTunnel(for: udid)
                    }
                }
            }
        }
    }
    @ViewBuilder
    private var statusIcon: some View {
        switch deviceConnectionManager.tunnelStatus {
        case .loading:
            ProgressView().controlSize(.small)
        case .ready:
            Image(systemName: "checkmark.circle.fill").foregroundColor(.green)
        case .stop:
            Image(systemName: "stop.circle.fill").foregroundColor(.gray)
        }
    }
}
