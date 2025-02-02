//
//  SearchUserView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/17/23.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct SearchUserView: View {
    //view properties
    @State private var fetchedUsers: [User] = []
    @State private var searchText: String = ""
    @State private var myProfile : User?
    @AppStorage("user_UID") private var userUID: String = ""
    @Environment(\.dismiss) private var dismiss
    
    @AppStorage("first_name") private var firstName = ""
    @AppStorage("last_name") private var lastName = ""

    var body: some View {
        NavigationStack{
            List{
                ForEach(fetchedUsers){user in
                    NavigationLink{
                        ReusableProfileContent(user: user, userUID: userUID, firstName: firstName, lastName: lastName)
                        
                    }label:{
                        Text(user.username)
                            .font(.callout)
                            .hAlign(.leading)
                    }
                }
            }
            .listStyle(.plain)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Search User")
            .searchable(text: $searchText)
            .onSubmit(of: .search, {
                Task{
                    await searchUsers()
                }
            })
            .onChange(of: searchText, perform: { newValue in
                if newValue.isEmpty{
                    fetchedUsers = []
                }
            })
            .toolbar{
                ToolbarItem(placement: .topBarTrailing){
                    Button("Cancel"){
                        dismiss()
                    }
                    .tint(.black)
                }
            }
            .task {
                if myProfile != nil{return} //task will be called any time we open tab, so we need to limit it to the first time (initial fetch)
                //initial fetch
                await fetchUserData()
            }

        }
    }

    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else{return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self)
        else{return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    
    func searchUsers() async {
        guard let myUID = Auth.auth().currentUser?.uid else { return }
        
        do {
            let documents = try await Firestore.firestore().collection("Users")
                .whereField("username", isGreaterThanOrEqualTo: searchText)
                .whereField("username", isLessThanOrEqualTo: "\(searchText)\u{f8ff}")
                .getDocuments()
            
            let users = try documents.documents.compactMap { doc -> User? in
                let user = try doc.data(as: User.self)
                // Exclude users who have blocked the current user
                if user.blockedUsers.contains(myUID) {
                    return nil
                }
                return user
            }
            
            await MainActor.run {
                fetchedUsers = users
            }
            
        } catch {
            print("Error searching users: \(error.localizedDescription)")
        }
    }

}

#Preview {
    SearchUserView()
}
