//
//  VirtualLocationViewModel.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftUI
import SwiftData
import MapKit

/// 虚拟定位应用的视图模型类
/// 负责管理应用的状态、数据和业务逻辑
@Observable
final class VirtualLocationViewModel: NSObject, MKLocalSearchCompleterDelegate {
    
    // MARK: - 单例实例
    /// 应用的单例视图模型实例
    public static let shared = VirtualLocationViewModel()

    private static let defaultMapSpan = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
    
    // MARK: - 地图状态
    /// 当前地图位置
    var mapPosition: MapCameraPosition = .region(MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
        span: defaultMapSpan
    ))
    
    // MARK: - 选中项状态
    /// 选中的项目ID
    var selectedItemId: UUID?
    /// 选中的名称
    var selectedName: String = ""
    /// 选中的坐标
    var selectedCoordinate: CLLocationCoordinate2D?
    /// 选中的 MapKit 地点
    var selectedMapItem: MKMapItem?
    /// 是否显示信息面板
    var showInspector = true
    /// 是否显示隧道连接失败警告
    var showTunnelConnectionFailedAlert = false
    
    // MARK: - 上下文菜单状态
    /// 菜单位置
    var menuLocation: CGPoint?
    
    // MARK: - 手动坐标输入
    /// 手动输入的纬度
    var manualLatitude = ""
    /// 手动输入的经度
    var manualLongitude = ""
    
    // MARK: - 搜索属性
    /// 地理搜索完成器
    private let completer = MKLocalSearchCompleter()
    /// 搜索查询文本
    var searchQuery = "" {
        didSet {
            completer.queryFragment = searchQuery
        }
    }
    /// 搜索结果列表
    var searchResults: [MKLocalSearchCompletion] = []
    /// 是否正在搜索
    var isSearching = false
    /// 最后一次搜索错误
    private var searchLastError: String?
    
    // MARK: - 搜索配置
    /// 配置搜索结果类型
    var searchResultTypes: MKLocalSearchCompleter.ResultType = [.address, .pointOfInterest] {
        didSet {
            completer.resultTypes = searchResultTypes
        }
    }
    /// 配置搜索区域优先级
    var searchRegionPriority: MKLocalSearchRegionPriority = .required
    
    /// 设置地址过滤器
    func setAddressFilter(_ filter: MKAddressFilter?) {
        completer.addressFilter = filter
    }
    
    /// 设置兴趣点过滤器
    func setPointOfInterestFilter(_ filter: MKPointOfInterestFilter?) {
        completer.pointOfInterestFilter = filter
    }
    
    // MARK: - 初始化
    /// 初始化方法
    override init() {
        super.init()
        completer.delegate = self
        // Allow both addresses and points of interest in search results
        completer.resultTypes = [.address, .pointOfInterest, .physicalFeature]
    }

    // MARK: - 搜索功能
    /// 更新搜索区域
    /// - Parameter region: 坐标区域
    func updateSearchRegion(_ region: MKCoordinateRegion) {
        completer.region = region
    }
    
    /// 执行地图搜索
    /// - Parameter completion: 搜索完成项
    /// - Returns: 搜索到的地图项
    /// - Throws: 搜索过程中发生的错误
    func performSearch(with completion: MKLocalSearchCompletion) async throws -> MKMapItem {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        
        let response = try await search.start()
        
        guard let item = response.mapItems.first else {
            throw NSError(domain: "MapSearch", code: -1, userInfo: [NSLocalizedDescriptionKey: "No results found"])
        }
        
        return item
    }
    
    /// 执行自然语言地图搜索
    /// - Parameters:
    ///   - query: 搜索查询
    ///   - region: 搜索区域
    /// - Returns: 搜索到的地图项数组
    /// - Throws: 搜索过程中发生的错误
    func performSearch(query: String, in region: MKCoordinateRegion? = nil) async throws -> [MKMapItem] {
        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        
        if let searchRegion = region {
            request.region = searchRegion
            request.regionPriority = .required
        }
        
        // Default to showing both addresses and points of interest
        request.resultTypes = [.address, .pointOfInterest, .physicalFeature]
        
        let search = MKLocalSearch(request: request)
        let response = try await search.start()
        
        return response.mapItems
    }
    
    /// 搜索结果更新回调
    /// - Parameter completer: 搜索完成器
    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        searchResults = completer.results
        searchLastError = nil
    }
    
    /// 搜索失败回调
    /// - Parameters:
    ///   - completer: 搜索完成器
    ///   - error: 错误信息
    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        searchLastError = error.localizedDescription
    }
    
    /// 处理搜索结果选择
    /// - Parameter completion: 搜索完成项
    func handleSearchSelection(_ completion: MKLocalSearchCompletion) {
        isSearching = false
        Task {
            do {
                let item = try await performSearch(with: completion)
                updateSelection(mapItem: item)
                selectedItemId = nil
            } catch {
                searchLastError = error.localizedDescription
            }
        }
    }
    
    // MARK: - 位置更新
    /// 更新选中位置
    /// - Parameters:
    ///   - name: 名称
    ///   - coordinate: 坐标
    func updateSelection(name: String, coordinate: CLLocationCoordinate2D) {
        withAnimation {
            selectedName = name
            selectedCoordinate = coordinate
            updateMapPosition(center: coordinate)
        }
    }

    /// 更新选中位置
    /// - Parameters:
    ///   - name: 名称
    ///   - coordinate: 坐标
    func updateSelection(mapItem: MKMapItem) {
        withAnimation {
            selectedName = mapItem.name ?? "Unknown"
            selectedCoordinate = mapItem.location.coordinate
            selectedMapItem = mapItem
            updateMapPosition(center: mapItem.location.coordinate)
        }
    }
    
    func updateMapPosition(center coordinate: CLLocationCoordinate2D) {
        withAnimation {
            mapPosition = .region(MKCoordinateRegion(center: coordinate, span: VirtualLocationViewModel.defaultMapSpan))
        }
    }

    func clearSelection() {
        withAnimation {
            selectedItemId = nil
            selectedCoordinate = nil
            selectedName = ""
        }
    }


    func resetManualCoordinate() {
        manualLatitude = ""
        manualLongitude = ""
    }
    
    // MARK: - Location Record Management
    /// Add a location record to favorites
    func addToFavorites(_ record: LocationRecord, in modelContext: ModelContext) {
        withAnimation {
        // Update the existing record to mark as favorite
            record.isFavorite = true
            
            do {
                try modelContext.save()
            } catch {
                print("Error saving favorite: \(error)")
            }
        }
    }

    /// Remove a location record from favorites
    func removeFromFavorites(_ record: LocationRecord, in modelContext: ModelContext) {
        withAnimation {
            // Update the existing record to mark as not favorite
            record.isFavorite = false
            
            do {
                try modelContext.save()
            } catch {
                print("Error removing from favorites: \(error)")
            }
        }
    }

    /// Delete a location record
    func deleteRecord(_ record: LocationRecord, in modelContext: ModelContext) {
        withAnimation {
            do {
                modelContext.delete(record)
                try modelContext.save()
            } catch {
                print("Error deleting record: \(error)")
            }
        }
    }
}
