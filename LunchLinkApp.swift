//
//  LunchLinkApp.swift
//  LunchLink
//
//  Created by Emmet Hamell on 10/22/23.
//

import SwiftUI
import Firebase
import UserNotifications

@main
struct LunchLinkApp: App {
    init() {
        FirebaseApp.configure()
    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
