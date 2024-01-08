//
//  Friendship Button.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/20/23.
//

import SwiftUI
import SDWebImageSwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift

struct Friendship_Button: View {
    enum FriendshipStatus {
        case notFriends, pending, friends
    }
    
    var user: User
    var currentUserUID: String
    @Binding var friendRequestStatus: FriendRequest.RequestStatus?
    var onAddFriend: () -> Void
    var onAcceptFriendRequest: () -> Void
    var onDeclineFriendRequest: () -> Void
    var onRemoveFriend: () -> Void
    @State private var showAlert = false
    
    @Binding var buttonMessage: String
    
    var body: some View {
        if buttonMessage != "This person wants to be your friend!" {
            Button(action: {
                if buttonMessage == "pending" {
                    print("pending")
                } else if buttonMessage == "friends!" {
                    //TODO: Add popup screen that asks them if they want to remove the friend
                    self.showAlert = true

                    print("already friends")
                } else if buttonMessage == "add friend" {
                    checkFriendRequest(curUserID: currentUserUID, otherUserID: user.id!) { exists in
                        if exists {
                            print("A friend request already exists.")
                        } else {
                            onAddFriend()
                        }
                    }
                    
                } else {
                    print("SOMETHING WENT WRONG")
                }
                
            }) {
                Text(buttonMessage)
            }
            .buttonStyle(CustomButtonStyle())
            .alert(isPresented: $showAlert){
                Alert(
                    title: Text("Remove Friend"),
                    message: Text("Are you sure you want to remove this friend?"),
                    primaryButton: .destructive(Text("Yes")) {
                        print("Friend removed")
                        onRemoveFriend()
                    },
                    secondaryButton: .cancel()
                )
            }
        } else {
            Text("This person wants to be your friend!")
            HStack {
                
                Button(action: {
                    onAcceptFriendRequest()
                }) {
                    Text("Accept")
                }
                .buttonStyle(CustomButtonStyle())
                
                Button(action: {
                    onDeclineFriendRequest()
                }) {
                    Text("Decline")
                }
                .buttonStyle(CustomButtonStyle())
            }
            
        }
    }
    
    func checkFriendRequest(curUserID: String, otherUserID: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        let friendRequestsRef = db.collection("FriendRequests")
        friendRequestsRef.whereField("receiverID", isEqualTo: curUserID)
            .whereField("senderID", isEqualTo: otherUserID)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    completion(false)
                } else {
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        for document in documents {
                            print("\(document.documentID) => \(document.data())")
                        }
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
    }
    
    struct CustomButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8) 
                .padding(.horizontal, 16)
                .foregroundColor(.white)
                .background(configuration.isPressed ? Color.black.opacity(0.8) : Color.black)
                .cornerRadius(8)
                .font(.headline)
        }

    }
    
}

