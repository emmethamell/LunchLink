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

    var body: some View {
        NavigationStack{
            List{
                ForEach(fetchedUsers){user in
                    NavigationLink{
                        //TODO: Isolate the cause for why everything freezes when you add this link.
                        ReusableProfileTEST(user: user, userUID: userUID)
                        
                        
                        //ReusableProfileContent(user: user, userUID: userUID)
                        
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
                //fetch user from firebase
                print("one")
                Task{
                    await searchUsers()
                }
                print("two")
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
    //emmet
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else{return}
        print("three, userUID: ", userUID)
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self)
        else{return}
        await MainActor.run(body: {
            print("myprofile: ", user)
            myProfile = user
        })
    }
    
    func searchUsers()async{
        do{
            print("four")
            
            let documents = try await Firestore.firestore().collection("Users")
                .whereField("username", isGreaterThanOrEqualTo: searchText)
                .whereField("username", isLessThanOrEqualTo: "\(searchText)\u{f8ff}")
                .getDocuments()
            print("five")
            let users = try documents.documents.compactMap{ doc -> User? in
                try doc.data(as: User.self)
            }
            print("six")
            
            await MainActor.run(body: {
                fetchedUsers = users
                for user in fetchedUsers{
                    print("user: ", user)
                }
            })
            print("seven")
        }catch{
            print(error.localizedDescription)
        }
    }
}

#Preview {
    SearchUserView()
}
