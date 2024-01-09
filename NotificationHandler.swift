//
//  NotificationHandler.swift
//  LunchLink
//
//  Created by Emmet Hamell on 12/21/23.
//
import Firebase
import UIKit
import UserNotifications
import FirebaseMessaging
import SwiftUI


class NotificationHandler: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    @AppStorage("user_token") var userToken: String = ""
    
    static let shared = NotificationHandler()
    
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        requestNotificationPermission()
        application.registerForRemoteNotifications()
        return true
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("Notification permission granted.")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken

        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                self.userToken = token
                
            }
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    func sendNotificationRequest(header: String, body: String, fcmTokens: [String]) {
        guard let url = URL(string: "https://lunchlink-render.onrender.com/send") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = [
            "fcmTokens": fcmTokens,
            "header": header,
            "body": body
        ]
        print(json)
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: json, options: [])
        
        print("REQUEST", request)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending notification request: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Server returned an error: \(httpResponse.statusCode)")
            } else {
                print("Notification request sent successfully")
            }
        }

        task.resume()
    }
}
