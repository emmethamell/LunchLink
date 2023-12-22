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
    
    @Binding var buttonMessage: String
    
    
    var body: some View {
        //split up button, it should be split for when someone requested someone else
        if buttonMessage != "This person wants to be your friend!" {
            Button(action: {
                if buttonMessage == "pending" {
                    print("pending")
                } else if buttonMessage == "friends!" {
                    print("already friends")
                } else if buttonMessage == "add friend" {
                    // CALL THE CHECK FRIEND REQUEST HERE, IF THERE ALREADY EXISTS A REQUEST, THEN DO NOT CALL ON ADD FRIEND
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
                    completion(false)  // Call completion with false on error
                } else {
                    if let documents = querySnapshot?.documents, !documents.isEmpty {
                        // Found documents matching the query
                        for document in documents {
                            print("\(document.documentID) => \(document.data())")
                        }
                        completion(true)  // Call completion with true if documents are found
                    } else {
                        completion(false)  // Call completion with false if no documents are found
                    }
                }
            }
        

    }
    
    struct CustomButtonStyle: ButtonStyle {
        func makeBody(configuration: Configuration) -> some View {
            configuration.label
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8) // Adjust the vertical padding to make it thinner
                .padding(.horizontal, 16) // Adjust the horizontal padding as needed
                .foregroundColor(.white)
                .background(configuration.isPressed ? Color.black.opacity(0.8) : Color.black)
                .cornerRadius(8)
                .font(.headline) //Adjust the font size and style as needed
        }

    }
}

