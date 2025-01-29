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


struct ReusableProfileContent: View {
    var user: User      //user object for the other user
    var userUID: String //userUID for the current user
    var firstName: String
    var lastName: String

    @State private var friendRequestStatus: FriendRequest.RequestStatus?
    @State private var buttonMessage: String = ""
    
    @State private var showError: Bool = false
    @State private var errorMessage: String = ""
    
    @State private var fetchedInvites: [Invite] = []
    
    //keep track of the curRequest. The one between you and the user you are looking at, if any
    @State var curRequest: FriendRequest = FriendRequest(senderID: "", receiverID: "", status: .pending) //CHANGED
    
    @State private var myProfile: User?
    
    var body: some View {
        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack {
                    profileHeader
                    if userUID != user.userUID {
                        Friendship_Button(
                            user: user,
                            currentUserUID: userUID,
                            friendRequestStatus: $friendRequestStatus,
                            onAddFriend: {
                                createFriendRequest(userUID: userUID, otherUserUID: user.userUID)
                            },
                            onAcceptFriendRequest: {
                                acceptFriendRequest(userUID: userUID, otherUserUID: user.userUID)
                            },
                            onDeclineFriendRequest: {
                                deleteFriendRequest(receiverID: userUID, senderID: user.id!)
                            },
                            onRemoveFriend: {
                                deleteFriendRequest(receiverID: userUID, senderID: user.id!)
                                deleteFriendRequest(receiverID: user.id!, senderID: userUID)
                                removeFromEacothersFriendLists()
                            },
                            buttonMessage: $buttonMessage
                        )
                    }
                    
                    // History / Invites
                    Text("History")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.black)
                        .hAlign(.leading)
                        .padding(.vertical, 15)
                    
                    if user.userUID != userUID && friendRequestStatus != .accepted {
                        Text("Add \(user.username) as a friend to see history!")
                    } else {
                        ReusableInviteView(basedOnUID: true, uid: user.userUID, invites: $fetchedInvites)
                    }
                }
                .padding(15)
            }
            // MARK: - Toolbar with "Block/Unblock"
            .navigationTitle(user.username)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                // Show the toolbar ONLY if looking at someone else's profile
                if userUID != user.userUID {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Menu {
                            // (Optional) Add your "Add/Remove Friend" here if you want
                            Divider()
                            
                            // BLOCK/UNBLOCK
                            if let currentUser = myProfile {
                                if currentUser.blockedUsers.contains(user.userUID) {
                                    Button("Unblock \(user.username)") {
                                        Task {
                                            do {
                                                try await UserBlockService.shared.unblockUser(
                                                    currentUserID: currentUser.userUID,
                                                    blockedUserID: user.userUID
                                                )
                                                // Refresh local copy of currentUser (myProfile) in the background
                                                await fetchCurrentUser()
                                            } catch {
                                                print("Error unblocking user: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                } else {
                                    Button("Block \(user.username)", role: .destructive) {
                                        Task {
                                            do {
                                                try await UserBlockService.shared.blockUser(
                                                    currentUserID: currentUser.userUID,
                                                    blockedUserID: user.userUID
                                                )
                                                await fetchCurrentUser()
                                            } catch {
                                                print("Error blocking user: \(error.localizedDescription)")
                                            }
                                        }
                                    }
                                }
                            }
                            
                        } label: {
                            Image(systemName: "ellipsis")
                                .rotationEffect(.init(degrees: 90))
                                .tint(.black)
                        }
                    }
                }
            }
            // Alert for errors
            .alert(errorMessage, isPresented: $showError) {}
            // On appear: fetch friend request status + get current user
            .onAppear {
                determineFriendRequestStatus(userUID: userUID, otherUserUID: user.userUID)
                Task {
                    await fetchCurrentUser()
                }
            }
        }
    }
    
    // MARK: - Subviews
    @ViewBuilder
    var profileHeader: some View {
        HStack(spacing: 12) {
            WebImage(url: user.userProfileURL).placeholder {
                Image("NullProfile")
                    .resizable()
            }
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 100, height: 100)
            .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(user.username)
                    .font(.title3)
                    .fontWeight(.semibold)
            }
            .hAlign(.leading)
        }
    }
}

// MARK: - Firestore / Friend Request Logic
extension ReusableProfileContent {
    
    /// Fetch current user's doc to check `blockedUsers`
    func fetchCurrentUser() async {
        guard let currentUID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let userDoc = try await Firestore.firestore()
                .collection("Users")
                .document(currentUID)
                .getDocument(as: User.self)
            
            await MainActor.run {
                myProfile = userDoc
            }
        } catch {
            print("Error fetching current user doc: \(error.localizedDescription)")
        }
    }
    
    func determineFriendRequestStatus(userUID: String, otherUserUID: String) {
        let db = Firestore.firestore()
        db.collection("FriendRequests")
            .whereField("senderID", isEqualTo: userUID)
            .whereField("receiverID", isEqualTo: otherUserUID)
            .getDocuments { querySnapshot, error in
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    determineStatusWhenNoDocFound(userUID: userUID, otherUserUID: otherUserUID)
                    return
                }
                
                if let friendRequest = try? documents[0].data(as: FriendRequest.self) {
                    curRequest = friendRequest
                    switch friendRequest.status {
                    case .pending:
                        buttonMessage = "Pending"
                    case .accepted:
                        buttonMessage = "Friends!"
                    case .declined:
                        buttonMessage = "Add friend"
                    }
                    friendRequestStatus = friendRequest.status
                } else {
                    friendRequestStatus = nil
                    buttonMessage = "Add friend"
                }
            }
    }
    
    func determineStatusWhenNoDocFound(userUID: String, otherUserUID: String) {
        let db = Firestore.firestore()
        db.collection("FriendRequests")
            .whereField("receiverID", isEqualTo: userUID)
            .whereField("senderID", isEqualTo: otherUserUID)
            .getDocuments { querySnapshot, error in
                guard let documents = querySnapshot?.documents, !documents.isEmpty else {
                    buttonMessage = "Add friend"
                    friendRequestStatus = nil
                    return
                }
                if let friendRequest = try? documents[0].data(as: FriendRequest.self) {
                    curRequest = friendRequest
                    switch friendRequest.status {
                    case .pending:
                        buttonMessage = "This person wants to be your friend!"
                    case .accepted:
                        buttonMessage = "Friends!"
                    case .declined:
                        buttonMessage = "Add friend"
                    }
                    friendRequestStatus = friendRequest.status
                } else {
                    friendRequestStatus = nil
                }
            }
    }
    
    func acceptFriendRequest(userUID: String, otherUserUID: String) {
        Task {
            guard let requestID = curRequest.id else { return }
            try await Firestore.firestore().collection("FriendRequests")
                .document(requestID)
                .updateData(["status": "accepted"])
            
            addToEachothersFriendLists()
            determineFriendRequestStatus(userUID: userUID, otherUserUID: otherUserUID)
        }
    }
    
    func createFriendRequest(userUID: String, otherUserUID: String) {
        Task {
            do {
                let request = FriendRequest(senderID: userUID, receiverID: otherUserUID, status: .pending)
                try await Firestore.firestore().collection("FriendRequests").addDocument(from: request)
            } catch {
                await setError(error)
            }
        }
        determineFriendRequestStatus(userUID: userUID, otherUserUID: user.userUID)
        fetchTokensAndSendNotification(forUserUID: otherUserUID)
    }
    
    func fetchTokensAndSendNotification(forUserUID userUID: String) {
        let db = Firestore.firestore()
        db.collection("Users").document(userUID).getDocument { (document, error) in
            if let document = document, document.exists {
                if let token = document.data()?["token"] as? String {
                    NotificationHandler.shared.sendNotificationRequest(
                        header: "LunchLink",
                        body: "\(firstName) \(lastName) wants to be friends!",
                        fcmTokens: [token]
                    )
                }
            } else {
                print("Document does not exist or error: \(error?.localizedDescription ?? "")")
            }
        }
    }
    
    func addToEachothersFriendLists() {
        Task {
            try await Firestore.firestore().collection("Users").document(userUID)
                .updateData(["friends": FieldValue.arrayUnion([user.userUID])])
            
            try await Firestore.firestore().collection("Users").document(user.userUID)
                .updateData(["friends": FieldValue.arrayUnion([userUID])])
        }
    }
    
    func removeFromEacothersFriendLists() {
        Task {
            try await Firestore.firestore().collection("Users").document(userUID)
                .updateData(["friends": FieldValue.arrayRemove([user.userUID])])
            
            try await Firestore.firestore().collection("Users").document(user.userUID)
                .updateData(["friends": FieldValue.arrayRemove([userUID])])
        }
    }
    
    func setError(_ error: Error) async {
        await MainActor.run {
            errorMessage = error.localizedDescription
            showError.toggle()
        }
    }
    
    func deleteFriendRequest(receiverID: String, senderID: String) {
        let db = Firestore.firestore()
        let friendRequestsRef = db.collection("FriendRequests")
        
        friendRequestsRef
            .whereField("receiverID", isEqualTo: receiverID)
            .whereField("senderID", isEqualTo: senderID)
            .getDocuments { (querySnapshot, err) in
                if let err = err {
                    print("Error getting documents: \(err)")
                    return
                }
                if let document = querySnapshot?.documents.first {
                    document.reference.delete { err in
                        if let err = err {
                            print("Error removing document: \(err)")
                        } else {
                            buttonMessage = "Add friend"
                            print("Document successfully removed!")
                        }
                    }
                } else {
                    print("No matching document found")
                }
            }
        
        determineFriendRequestStatus(userUID: userUID, otherUserUID: user.id!)
    }
    
}
