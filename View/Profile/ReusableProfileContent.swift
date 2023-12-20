//
//  ReusableProfileContent.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/13/23.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore
import FirebaseFirestoreSwift
import SDWebImageSwiftUI

//FIXME: When user1 is looking at someones profile and user2 requests to be friends while they are there, the button does not get updated automatically, allowing for user1 make another friend request. There are requests going either way, with no way to actually become friends.


struct ReusableProfileContent: View {
    var user: User      //user object for the other user
    var userUID: String //userUID for the current user

    //the userUID for current user
    // @AppStorage("user_UID") private var userUID: String = ""
    @State private var friendRequestStatus: FriendRequest.RequestStatus?
    @State private var buttonMessage: String = ""
    
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @State private var fetchedInvites: [Invite] = []
    
    //keep track of the curRequest. The one between you and the user you are looking at, if any
    @State var curRequest: FriendRequest = FriendRequest(id: "", senderID: "", receiverID: "", status: .pending)
    
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            LazyVStack{
                HStack(spacing: 12){
                    WebImage(url: user.userProfileURL).placeholder{
                        //placeholder image
                        Image("NullProfile")
                            .resizable()
                    }
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 100, height: 100)
                    .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 6){
                        Text(user.username)
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                    }
                    .hAlign(.leading)
                }

                
                //if the user is NOT us, we need to add a button to make friend requests
                //TODO: add callback functions to friendship button for update. add doc listner to friendship button so any changes in firestore show
                if userUID != user.userUID {
                    Friendship_Button(
                        user: user,
                        currentUserUID: userUID,
                        friendRequestStatus: $friendRequestStatus,
                        onAddFriend: {
                                createFriendRequest(userUID: userUID, otherUserUID: user.userUID)
                        },
                        onAcceptFriendRequest: {
                            // Logic to accept friend request
                            print("accept friend request")
                            acceptFriendRequest(userUID: userUID, otherUserUID: user.userUID)
                            //add the curUserID to Otheruser friend list
                            //add the otherUserID to curUser friend list
                        },
                        onDeclineFriendRequest: {
                            // Logic to decline friend request
                            print("deny friend request")
                        },
                        buttonMessage: $buttonMessage
                    )
                }
    
                
                Text("History")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.black)
                    .hAlign(.leading)
                    .padding(.vertical, 15)
                
                if user.userUID != userUID && friendRequestStatus != .accepted{
                    Text("Add " + user.username + " as a friend to see history")
                } else {
                    ReusableInviteView(basedOnUID: true, uid: user.userUID, invites: $fetchedInvites)
                }
            }
            .padding(15)
        }
        .onAppear{
            determineFriendRequestStatus(userUID: userUID, otherUserUID: user.userUID)
        }
        
        .alert(errorMessage, isPresented: $showError, actions: {})
        
    }
    
    //query firestore friendRequest collection and check if there is a request with userUID as the senderID and user.userUID and the recieverID
    //check the status, return pending, accepted, or declined
    func determineFriendRequestStatus(userUID: String, otherUserUID: String) {
        let db = Firestore.firestore()
        // Query the FriendRequest collection
        db.collection("FriendRequests")
            .whereField("senderID", isEqualTo: userUID)
            .whereField("receiverID", isEqualTo: otherUserUID)
            .getDocuments { querySnapshot, error in
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    //none found where you are the sender and they are reciever, check other way around
                    determineStatusWhenNoDocFound(userUID: userUID, otherUserUID: otherUserUID)
                    return
                }
                
                //there should only be one request between two users
                if let friendRequest = try? documents[0].data(as: FriendRequest.self) {
                    curRequest = friendRequest
                    if friendRequest.status == .pending {
                        buttonMessage = "pending"
                    }
                    if friendRequest.status == .accepted {
                        buttonMessage = "friends!"
                    }
                    if friendRequest.status == .declined {
                        buttonMessage = "add friend"
                    }
                   friendRequestStatus = friendRequest.status
                } else {
                   friendRequestStatus = nil
                }
                return
            }
    }
    
    //try to see if the other user has requested you
    func determineStatusWhenNoDocFound(userUID: String, otherUserUID: String) {
        let db = Firestore.firestore()
        
        // Query the FriendRequest collection
        db.collection("FriendRequests")
            .whereField("receiverID", isEqualTo: userUID)
            .whereField("senderID", isEqualTo: otherUserUID)
            .getDocuments { querySnapshot, error in
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    //no request found, return .none or nil
                    buttonMessage = "add friend"  //EXAMPLE OF WHAT TO DO,
                    friendRequestStatus = nil
                    return
                }
                
                // Assuming there is only one friend request between two users
                if let friendRequest = try? documents[0].data(as: FriendRequest.self) {
                    curRequest = friendRequest
                    if friendRequest.status == .pending {
                        buttonMessage = "This person wants to be your friend!"
                    }
                    if friendRequest.status == .accepted {
                        buttonMessage = "friends!"
                    }
                    if friendRequest.status == .declined {
                        buttonMessage = "add friend"
                    }
                   friendRequestStatus = friendRequest.status
                } else {
                   friendRequestStatus = nil
                }
                return
            }
    }
    
    //in this case, the sender id = otherUserID, recieverID = userUID
    func acceptFriendRequest(userUID: String, otherUserUID: String) {
        Task{
            guard let requestID = curRequest.id else{return}
            try await Firestore.firestore().collection("FriendRequests").document(requestID).updateData([
                "status": "accepted"
            ])
        }
        addToEachothersFriendLists(userOneUID: userUID, userTwoUID: otherUserUID)
        determineFriendRequestStatus(userUID: userUID, otherUserUID: otherUserUID)
    }
    
    
    //create a friend request from user to otherUser
    //create a FriendRequest document: senderID = userUID, recieverID = otherUserUID, status = pending
    func createFriendRequest(userUID: String, otherUserUID: String) {
       // isLoading = true
            Task{
                do{
                    let request = FriendRequest(senderID: userUID, receiverID: otherUserUID, status: .pending)
                    try await createDocumentAtFirebase(request)
                }catch{
                    await setError(error)
                }
            }
            
            //update the request status so the binding var in child view changes
            determineFriendRequestStatus(userUID: userUID, otherUserUID: user.userUID)
       
    }
    
    func createDocumentAtFirebase(_ invite: FriendRequest)async throws{
        let _ = try Firestore.firestore().collection("FriendRequests").addDocument(from: invite, completion: { error in
            if error == nil{
                //post succesfully stored
                print("post stored")
            
               // isLoading = false

            }
        })
    }
    
    func addToEachothersFriendLists(userOneUID: String, userTwoUID: String) {
        Task{
            try await Firestore.firestore().collection("Users").document(userUID).updateData([
                "friends": FieldValue.arrayUnion([user.userUID])
            ])
            try await Firestore.firestore().collection("Users").document(user.userUID).updateData([
                "friends": FieldValue.arrayUnion([userUID])
            ])
        }
    }
    
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
    
}
