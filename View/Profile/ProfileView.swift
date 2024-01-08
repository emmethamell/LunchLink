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
import SwiftMessages

struct ProfileView: View {
    //My Profile Data
    @State private var myProfile : User?
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_UID") var userUID: String = ""
    //View properties
    @State var errorMessage: String = ""
    @State var showError: Bool = false
    @State var isLoading: Bool = false
    
    @State var userProfilePicData: Data?
    @State var showImagePicker = false
    
    var body: some View {
        NavigationStack {
            VStack {
                if let myProfile{
                    ReusableProfileContent(user: myProfile, userUID: userUID)
                        .refreshable {
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
                        Button("Change Profile Photo", action: {
                            showImagePicker.toggle()
                        })
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
            if myProfile != nil{return} //task will be called any time we open tab, so we need to limit it to the first time (initial fetch)
            await fetchUserData()
        }
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: Binding(
                get: { UIImage(data: userProfilePicData ?? Data()) },
                set: { newImage in userProfilePicData = newImage?.jpegData(compressionQuality: 1.0) }
            ), isPresented: $showImagePicker) { croppedImage in
                userProfilePicData = croppedImage.jpegData(compressionQuality: 1.0)
                uploadProfilePic(imageData: userProfilePicData!)
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
    
    func uploadProfilePic(imageData: Data) {
        isLoading = true
        Task {
            do{
                guard let imageData = userProfilePicData else {return}
                
                //delete the old photo in storage
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)

                let downloadURL = try await storageRef.downloadURL()

                try await Firestore.firestore().collection("Users").document(userUID).updateData([
                    "userProfileURL": downloadURL.absoluteString
                ])
                
                
                let query = Firestore.firestore().collection("Invites").whereField("userUID", isEqualTo: userUID)
                let querySnapshot = try await query.getDocuments()
                if querySnapshot.documents.isEmpty {
                    print("No documents found")
                } else {
                    for document in querySnapshot.documents {
                        try await document.reference.updateData([
                            "userProfileURL": downloadURL.absoluteString
                        ])
                        print("Document \(document.documentID) successfully updated")
                    }
                }
                isLoading = false
                DispatchQueue.main.async {
                    self.showNotification()
                }
                
                
            }catch{
                await setError(error)
            }
        }
    }
    
    func showNotification() {
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(.success)
        view.configureContent(title: "Profile Updated", body: "Pull down to refresh")
        view.button?.isHidden = true
        
        var config = SwiftMessages.Config()
        config.presentationStyle = .top
        config.presentationContext = .window(windowLevel: .normal)
        
        SwiftMessages.show(config: config, view: view)
    }


    func logOutUser() {
        try? Auth.auth().signOut()
        logStatus = false
    }
    
    func deleteAccount() {
        isLoading = true
        Task {
            do {
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                let reference = Storage.storage().reference().child("Profile_Images").child(userUID)
                try await reference.delete()
                try await Firestore.firestore().collection("Users").document(userUID).delete()
                try await Auth.auth().currentUser?.delete()
                logStatus = false
            } catch {
                await setError(error)
            }
        }
    }
    
    func setError(_ error: Error)async {
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
