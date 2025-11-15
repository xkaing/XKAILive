//
//  StorageService.swift
//  XKAILive
//
//  Created by wxk on 2025/11/8.
//

import Foundation
import UIKit
import Supabase

/// 存储服务，管理 Supabase Storage 的操作
class StorageService {
    static let shared = StorageService()
    private let supabase = SupabaseManager.shared.client
    
    private init() {}
    
    /// 上传图片到 Supabase Storage
    /// - Parameters:
    ///   - image: 要上传的图片
    ///   - bucketName: 存储桶名称（默认为配置中的值）
    ///   - fileName: 文件名（如果不提供，将自动生成）
    /// - Returns: 上传后的公开 URL
    func uploadImage(
        image: UIImage,
        bucketName: String = SupabaseConfig.imageBucket,
        fileName: String? = nil
    ) async throws -> String {
        // 生成文件名（如果未提供）
        let finalFileName: String
        if let fileName = fileName {
            finalFileName = fileName
        } else {
            // 使用 UUID 和时间戳生成唯一文件名
            let uuid = UUID().uuidString
            let timestamp = Int(Date().timeIntervalSince1970)
            finalFileName = "\(timestamp)_\(uuid).jpg"
        }
        
        // 将 UIImage 转换为 JPEG 数据
        guard let imageData = image.jpegData(compressionQuality: SupabaseConfig.imageCompressionQuality) else {
            throw NSError(
                domain: "StorageService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法将图片转换为数据"]
            )
        }
        
        do {
            // 上传文件到 Supabase Storage
            try await supabase.storage
                .from(bucketName)
                .upload(
                    path: finalFileName,
                    file: imageData,
                    options: FileOptions(
                        contentType: "image/jpeg",
                        upsert: true
                    )
                )
            
            // 获取公开 URL
            let publicURL = try supabase.storage
                .from(bucketName)
                .getPublicURL(path: finalFileName)
            
            print("✅ 成功上传图片: \(finalFileName)")
            return publicURL.absoluteString
        } catch {
            print("❌ 上传图片失败: \(error)")
            throw error
        }
    }
    
    /// 上传用户头像
    /// - Parameters:
    ///   - image: 头像图片
    ///   - userId: 用户 ID（用于生成唯一文件名）
    /// - Returns: 上传后的公开 URL
    func uploadAvatar(image: UIImage, userId: String) async throws -> String {
        let fileName = "\(SupabaseConfig.avatarPathPrefix)/\(userId)_\(Int(Date().timeIntervalSince1970)).jpg"
        return try await uploadImage(image: image, bucketName: SupabaseConfig.imageBucket, fileName: fileName)
    }
    
    /// 删除文件
    /// - Parameters:
    ///   - path: 文件路径
    ///   - bucketName: 存储桶名称（默认为配置中的值）
    func deleteFile(path: String, bucketName: String = SupabaseConfig.imageBucket) async throws {
        do {
            try await supabase.storage
                .from(bucketName)
                .remove(paths: [path])
            
            print("✅ 成功删除文件: \(path)")
        } catch {
            print("❌ 删除文件失败: \(error)")
            throw error
        }
    }
}

