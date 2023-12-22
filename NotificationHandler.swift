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

class NotificationHandler: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    static let shared = NotificationHandler()
    var deviceToken: String?


    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // Request notification permissions
        requestNotificationPermission()
        // Register for push notifications
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
        // Set the APNs token for Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken

        // Now fetch the FCM token
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                self.deviceToken = token
            }
        }
    }
    func handleRegistrationCompletion(uuid: String) {
        print("calling the registration with token", deviceToken!)
        if let token = deviceToken {
            sendDeviceTokenToServer(token, uuid: uuid)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    private func sendDeviceTokenToServer(_ token: String, uuid: String) {
        guard let url = URL(string: "http://10.0.0.220:8000/register-token") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let body: [String: Any] = ["token": token, "uuid": uuid]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Error sending FCM token and UUID to server: \(error)")
                return
            }
            if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                print("Server returned an error: \(httpResponse.statusCode)")
            } else {
                print("FCM token and UUID sent successfully")
            }
        }

        task.resume()
    }
    
    func sendNotificationRequest(title: String, body: String) {
        guard let url = URL(string: "http://10.0.0.220:8000/send-notification") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")

        let json: [String: Any] = [
            "title": title,
            "body": body
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: json)
        
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
    
    

    // Implement other UNUserNotificationCenterDelegate methods as needed...
}
