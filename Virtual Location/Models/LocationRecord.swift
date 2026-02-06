//
//  LocationRecord.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftData
import CoreLocation
import MapKit

/// 位置记录模型
/// 统一的历史记录和收藏地点模型，通过 isFavorite 属性区分是否为收藏
@Model
public final class LocationRecord {
    /// 唯一标识符
    public var id: UUID
    /// 位置/地点名称
    public var name: String
    /// 是否为收藏地点
    public var isFavorite: Bool
    /// 可选备注信息
    public var note: String?
    /// 纬度坐标
    public var latitude: Double
    /// 经度坐标
    public var longitude: Double
    /// 时间戳 - 根据类型不同表示创建时间或发送时间
    public var timestamp: Date
    /// 设备ID（可选）
    public var deviceId: String?
    /// MapKit 地点分类（可选）
    public var mapKitPointOfInterestCategory: String?

    /// 初始化方法
    /// - Parameters:
    ///   - name: 位置/地点名称
    ///   - isFavorite: 是否为收藏地点
    ///   - note: 可选备注
    ///   - latitude: 纬度
    ///   - longitude: 经度
    ///   - coordinateSystem: 坐标系统类型
    ///   - timestamp: 时间戳，默认为当前时间
    ///   - deviceId: 设备ID，可选
    init(
        name: String,
        isFavorite: Bool = false,
        note: String? = nil,
        latitude: Double,
        longitude: Double,
        timestamp: Date = Date(),
        deviceId: String? = nil,
        mapKitPointOfInterestCategory: String? = nil
    ) {
        self.id = UUID()
        self.name = name
        self.isFavorite = isFavorite
        self.note = note
        self.latitude = latitude
        self.longitude = longitude
        self.timestamp = timestamp
        self.deviceId = deviceId
        self.mapKitPointOfInterestCategory = mapKitPointOfInterestCategory
    }

    /// 计算属性：CLLocationCoordinate2D坐标对象
    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public var formattedCoordinate: String {
        String(format: "%.5f, %.5f", self.latitude, self.longitude)
    }
}
