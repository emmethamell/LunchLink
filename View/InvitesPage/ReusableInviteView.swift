//
//  ReusableInviteView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/15/23.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct ReusableInviteView: View {
    var basedOnUID: Bool = false
    var uid: String = ""
    
    @Binding var invites: [Invite]
    
    @State private var users: [String: User] = [:]
    @State private var isFetching: Bool = true
    @State private var paginationDoc: QueryDocumentSnapshot?
    
    @AppStorage("user_name") private var userName: String = ""
    
    @State private var curUser: User?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            LazyVStack {
                if isFetching {
                    EmptyView()
                        .padding(.top, 30)
                } else {
                    if invites.isEmpty {
                        // User has no invites
                        Text("You have no invites")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.top, 30)
                    } else {
                        Invites()
                    }
                }
            }
            .padding(15)
        }
        .refreshable {
            guard !basedOnUID else { return }
            isFetching = true
            invites = []
            paginationDoc = nil
            
            await fetchUserData()
            await fetchInvites()
            await fetchUsersForInvites()
            await filterBlockedInvites()
            
            isFetching = false
        }
        .task {
            guard invites.isEmpty else { return }
            if curUser != nil { return }
            
            await fetchUserData()
            await fetchInvites()
            await fetchUsersForInvites()
            await filterBlockedInvites()
            
            isFetching = false
        }
    }
    
    // MARK: - Fetch Current User
    func fetchUserData() async {
        guard let userUID = Auth.auth().currentUser?.uid else { return }
        do {
            let user = try await Firestore.firestore()
                .collection("Users")
                .document(userUID)
                .getDocument(as: User.self)
            await MainActor.run {
                curUser = user
            }
        } catch {
            print("Error fetching current user: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch All Invite Owners
    func fetchUsersForInvites() async {
        let userUIDs = Set(invites.map { $0.userUID }) // unique user UIDs from invites
        for uid in userUIDs {
            do {
                let user = try await Firestore.firestore()
                    .collection("Users")
                    .document(uid)
                    .getDocument(as: User.self)
                await MainActor.run {
                    self.users[uid] = user
                }
            } catch {
                print("Error fetching user doc for \(uid): \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - Display Invites
    @ViewBuilder
    func Invites() -> some View {
        ForEach(invites) { invite in
            if let user = users[invite.userUID] {
                InviteCardView(invite: invite, user: user) { updatedInvite in
                    // onUpdate callback
                    if let index = invites.firstIndex(where: { $0.id == updatedInvite.id }) {
                        invites[index].likedIDs = updatedInvite.likedIDs
                    }
                } onDelete: {
                    // removing post from array
                    withAnimation(.easeInOut(duration: 0.25)) {
                        invites.removeAll { $0.id == invite.id }
                    }
                }
                .onAppear {
                    // When last invite appears, fetch the next page
                    if invite.id == invites.last?.id, paginationDoc != nil {
                        Task {
                            await fetchInvites()
                            await fetchUsersForInvites()
                            await filterBlockedInvites()
                        }
                    }
                }
                
                Divider()
                    .padding(.horizontal, -15)
            }
        }
    }
    
    // MARK: - Fetch Invites
    func fetchInvites() async {
        if basedOnUID {
            do {
                var query: Query!
                
                if let paginationDoc {
                    query = Firestore.firestore().collection("Invites")
                        .order(by: "publishedDate", descending: true)
                        .start(afterDocument: paginationDoc)
                        .limit(to: 20)
                } else {
                    query = Firestore.firestore().collection("Invites")
                        .order(by: "publishedDate", descending: true)
                        .limit(to: 20)
                }
                
                query = query.whereField("userUID", isEqualTo: uid)
                
                let docs = try await query.getDocuments()
                print("Fetched \(docs.documents.count) invites for user \(uid).")
                
                let fetchedInvites = docs.documents.compactMap { doc -> Invite? in
                    try? doc.data(as: Invite.self)
                }
                
                await MainActor.run {
                    invites.append(contentsOf: fetchedInvites)
                    paginationDoc = docs.documents.last
                }
            } catch {
                print("Error fetching invites (basedOnUID): \(error.localizedDescription)")
            }
            
        } else {
            let db = Firestore.firestore()
            
            var ids = curUser?.friends ?? []
            if let currentUser = curUser {
                ids.append(currentUser.userUID)
            }
            let chunkedArray = ids.chunked(into: 10)
            
            for idsChunk in chunkedArray {
                do {
                    var query = db.collection("Invites")
                        .order(by: "publishedDate", descending: true)
                        .whereField("userUID", in: idsChunk)
                        .limit(to: 20)
                    
                    if let paginationDoc = paginationDoc {
                        query = query.start(afterDocument: paginationDoc)
                    }
                    
                    let snapshot = try await query.getDocuments()
                    let newInvites = snapshot.documents.compactMap { doc in
                        try? doc.data(as: Invite.self)
                    }
                    
                    if newInvites.isEmpty {
                        break
                    }
                    await MainActor.run {
                        invites.append(contentsOf: newInvites)
                    }
                    
                    if let lastDocument = snapshot.documents.last {
                        paginationDoc = lastDocument
                    } else {
                        break
                    }
                } catch {
                    print("Error fetching documents: \(error.localizedDescription)")
                    break
                }
            }
        }
    }

    func filterBlockedInvites() async {
        await MainActor.run {
            guard let currentUser = curUser else { return }
            
            invites.removeAll { invite in
                // If we haven't fetched the owner's doc, skip or keep
                guard let inviteOwner = users[invite.userUID] else {
                    return false
                }
                // Condition 1: currentUser blocked them
                if currentUser.blockedUsers.contains(inviteOwner.userUID) {
                    return true
                }
                // Condition 2: they blocked currentUser
                if inviteOwner.blockedUsers.contains(currentUser.userUID) {
                    return true
                }
                return false
            }
        }
    }
}

// Helper for splitting array into chunks of size N
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

#Preview {
    ContentView()
}

