//
//  RegisterView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 10/30/23.
//
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import PhotosUI

//TODO: When choosing an image when registering, allow the user to take a photo,
//TODO: Also, allow the user to crop the photo
//TODO: Look up privacy laws, maybe ask the user if you can access their photos or something IDK
//FIXME: Disable allowing users to choose videos as profile pictures, it doesnt work

//fixed: Keyboard doesn't show up for register view when running on phone
//Register View
struct RegisterView: View{
    // User details
    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var userProfilePicData: Data?
    // View properties
    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false
    // userDefaults
    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    var body: some View{
        VStack(spacing: 10) {
            Text("Register Account")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Welcome!")
                .font(.title3)
                .hAlign(.leading)
            
            // for smaller size optimization
            //removing the view that fits got rid of the issue with the keyboard not showing up
         //   ViewThatFits {
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                
              //  HelperView()
          //  }
            
            //register button
            HStack{
                Text("Already have an account?")
                    .foregroundColor(.gray)
                
                Button("Login Now") {
                    dismiss()
                }
                .fontWeight(.bold)
                .foregroundColor(.black)
            }
            .font(.callout)
            //.vAlign(.bottom) removing this fixed whitespace above keyboard
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .photosPicker(isPresented: $showImagePicker, selection: $photoItem)
        .onChange(of: photoItem) { newValue in
            // Extracting UIImage from photoItem
            if let newValue{
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else {return}
                        //UI must be updated on main thread
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                        
                    } catch{}
                }
            }
        }
        // displaying alert
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    @ViewBuilder
    func HelperView()->some View {
        VStack(spacing: 12) {
            ZStack {
                if let userProfilePicData,let image = UIImage(data: userProfilePicData) {
                    Image(uiImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }else{
                    Image("NullProfile")
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                }
            }
            .frame(width: 85, height: 85)
            .clipShape(Circle())
            .contentShape(Circle())
            .onTapGesture {
                showImagePicker.toggle()
            }
            .padding(.top,25)
            
            TextField("Username", text: $userName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Email", text: $emailID)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            SecureField("Password", text: $password)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            
            Button(action: registerUser){
                //login button
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(userName == "" || emailID == "" || password == "" || userProfilePicData == nil)
            .padding(.top,10)
        }
    }
    
    func registerUser(){
        isLoading = true
        closeKeyboard()
        Task{
            do{
                print("task called")
                // step 1: creating firebase account
                try await Auth.auth().createUser(withEmail: emailID, password: password)
                print("account created")
                // step 2: Uploading profile photo into firebase storage
                guard let userUID = Auth.auth().currentUser?.uid else{return}
                guard let imageData = userProfilePicData else {return}
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                // step 3: downloading photo url
                let downloadURL = try await storageRef.downloadURL()
                // step 4: creating a user firestore object
                let user = User(username: userName, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL)
                // step 5: saving user doc into firestore database
                let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user, completion: {
                    error in
                    if error == nil{
                        // print saved succesfully
                        print("Saved Succesfully")
                        userNameStored = userName
                        self.userUID = userUID
                        profileURL = downloadURL
                        logStatus = true
                    }
                })
            }catch{
                // delete created account in case of failure
                try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
    }
    //displaying errors via alert
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
