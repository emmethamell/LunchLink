//
//  Report.swift
//  LunchLink
//
//  Created by Emmet Hamell on 1/30/25.
//

import SwiftUI
import FirebaseFirestoreSwift

struct Report: Identifiable, Codable {
    @DocumentID var id: String?
    var reporterUID: String
    var reportedUserUID: String?
    var reportedPostID: String?
    var reason: String
    var additionalInfo: String?
    var timestamp: Date 
    
    enum CodingKeys: CodingKey {
        case id
        case reporterUID
        case reportedUserUID
        case reportedPostID
        case reason
        case additionalInfo
        case timestamp
    }
}

