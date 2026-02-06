//
//  ContentView.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftUI
import MapKit
import SwiftData

/// 主内容视图
/// 应用的主要界面，包含侧边栏、地图和详情面板
struct ContentView: View {
    /// 数据库上下文环境
    @Environment(\.modelContext) private var modelContext
    /// 位置记录查询（按时间倒序，favorites和history统一管理）
    @Query(sort: \LocationRecord.timestamp,
           order: .reverse) private var locationRecords: [LocationRecord]

    /// 虚拟位置视图模型
    @State private var viewModel = VirtualLocationViewModel.shared
    /// 设备连接管理器
    @State private var deviceConnectionManager = DeviceConnectionManager.shared

    var body: some View {
        NavigationSplitView {
            Sidebar()
                .environment(viewModel)
        } detail: {
            ZStack(alignment: .topLeading) {
                MapReader { proxy in
                    Map(position: $viewModel.mapPosition) {
                        if let selectedCoordinate = viewModel.selectedCoordinate {
                            Annotation("Pinned Location", coordinate: selectedCoordinate) {
                                Image(systemName: "mappin")
                                    .font(.largeTitle)
                                    .foregroundStyle(.white)
                                    .shadow(color: .red, radius: 4)
                                    .padding(8)
                                    .glassEffect(.regular.tint(.red), in: .circle)
                            }
                        }
                    }
                    .mapControls {
                        MapCompass()
                    }
                    .onContinuousHover { phase in
                        if case .active(let location) = phase {
                            viewModel.menuLocation = location
                        }
                    }
                    .contextMenu {
                        Button {
                            if let screenLocation = viewModel.menuLocation,
                               let mapCoordinate = proxy.convert(screenLocation, from: .local) {
                                viewModel.updateSelection(name: "Pinned Location", coordinate: mapCoordinate)
                                viewModel.selectedItemId = nil
                            }
                        } label: {
                            Label("Add Pin Here", systemImage: "plus")
                        }
                    }
                    .onMapCameraChange(frequency: .onEnd) { context in
                        viewModel.updateSearchRegion(context.region)
                    }
                }

                Group {
                    if let selectedCoordinate = viewModel.selectedCoordinate {
                        SelectionCard(coordinate: selectedCoordinate)
                            .environment(viewModel)
                            .environment(deviceConnectionManager)
                            .padding(.leading)
                    }
                }
                .transition(.move(edge: .top).combined(with: .blurReplace))
            }
            .inspector(isPresented: $viewModel.showInspector) {
                Inspector()
                .environment(deviceConnectionManager)
                .frame(minWidth: 260)
            }
            .toolbar {
                ToolbarItem {
                    Button("Inspector", systemImage: "sidebar.trailing") { viewModel.showInspector.toggle() }
                }
            }
        }
        .onChange(of: viewModel.selectedItemId) {
            if let itemId = viewModel.selectedItemId {
                handleItemSelected(by: itemId)
            }
        }
        .task {
            await deviceConnectionManager.refreshDevices()
        }
    }

    /// 处理项目选择的方法
    /// 根据选中的项目ID更新地图上的位置信息
    /// - Parameter itemId: 选中项目的唯一标识符
    private func handleItemSelected(by itemId: UUID) {
        if let record = locationRecords.first(where: { $0.id == itemId }) {
            viewModel.updateSelection(name: record.name, coordinate: record.coordinate)
        }
    }
}
