//
//  ProfileView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/12/23.
//

import SwiftUI
import Firebase
import FirebaseStorage
import FirebaseFirestore

struct ProfileView: View {
    //My Profile Data
    @State private var myProfile : User?
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_UID") var userUID: String = ""
    //View properties
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let myProfile{
                    ReusableProfileContent(user: myProfile, userUID: userUID)
                        //MARK: Make view refreshable, add this to friends page
                        .refreshable {
                            //Refresh user data
                            self.myProfile = nil
                            await fetchUserData()
                        }
                } else {
                   ProgressView()
                }
            }
            .navigationTitle("My Profile")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        //logout
                        //delete account
                        Button("Logout", action: logOutUser)
                        Button("Delete Account", role: .destructive, action: deleteAccount)
                    } label: {
                        Image(systemName: "ellipsis")
                            .rotationEffect(.init(degrees: 90))
                            .tint(.black)
                            .scaleEffect(0.8)
                    }
                }
            }
        }
        .overlay {
            LoadingView(show: $isLoading)
        }
        .alert(errorMessage, isPresented: $showError) {
        }
        .task {
            //this modifier is like onappear
            //so fetching for the first time only
            if myProfile != nil{return} //task will be called any time we open tab, so we need to limit it to the first time (initial fetch)
            //initial fetch
            await fetchUserData()
        }
    }
    
    //fetching user data
    func fetchUserData()async{
        guard let userUID = Auth.auth().currentUser?.uid else{return}
        guard let user = try? await Firestore.firestore().collection("Users").document(userUID).getDocument(as: User.self)
        else{return}
        await MainActor.run(body: {
            myProfile = user
        })
    }
    
    //Logging user out
    func logOutUser() {
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    //Deleting entire use account
    func deleteAccount() {
        isLoading = true
        Task {
            do {
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                //Step one: delete profile image from storage
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                //Step two: delete firestore user document
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                //Step three: deleting auth account and setting and setting log status to false
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            } catch {
                await setError(error)
            }
        }
    }
    
    //setting error
    func setError(_ error: Error)async {
        //UI Must be run on main thread
        await MainActor.run(body: {
            isLoading = false
            errorMessage = error.localizedDescription
            showError.toggle()
        })
    }
}
    

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
    }
}
