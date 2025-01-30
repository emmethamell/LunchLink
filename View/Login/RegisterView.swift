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


struct RegisterView: View{

    @State var emailID: String = ""
    @State var password: String = ""
    @State var userName: String = ""
    @State var firstName: String = ""
    @State var lastName: String = ""
    @State var userProfilePicData: Data?

    @Environment(\.dismiss) var dismiss
    @State var showImagePicker: Bool = false
    @State var photoItem: PhotosPickerItem?
    @State var showError: Bool = false
    @State var errorMessage: String = ""
    @State var isLoading: Bool = false

    @AppStorage("log_status") var logStatus: Bool = false
    @AppStorage("user_profile_url") var profileURL: URL?
    @AppStorage("user_name") var userNameStored: String = ""
    @AppStorage("user_UID") var userUID: String = ""
    @AppStorage("first_name") var firstNameStored = ""
    @AppStorage("last_name") var lastNameStored = ""
    @AppStorage("user_token") var userToken: String = ""
    
    var body: some View{
        VStack(spacing: 10) {
            Text("Register Account")
                .font(.largeTitle.bold())
                .hAlign(.leading)
            
            Text("Welcome!")
                .font(.title3)
                .hAlign(.leading)

      
                ScrollView(.vertical, showsIndicators: false) {
                    HelperView()
                }
                
            
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
        }
        .vAlign(.top)
        .padding(15)
        .overlay(content: {
            LoadingView(show: $isLoading)
        })
        .sheet(isPresented: $showImagePicker) {
            ImagePickerView(image: Binding(
                get: { UIImage(data: userProfilePicData ?? Data()) },
                set: { newImage in userProfilePicData = newImage?.jpegData(compressionQuality: 1.0) }
            ), isPresented: $showImagePicker) { croppedImage in
                userProfilePicData = croppedImage.jpegData(compressionQuality: 1.0)
            }
        }
        .onChange(of: photoItem) { newValue in
            if let newValue{
                Task{
                    do{
                        guard let imageData = try await newValue.loadTransferable(type: Data.self) else {return}
                        await MainActor.run(body: {
                            userProfilePicData = imageData
                        })
                        
                    } catch{}
                }
            }
        }
        .alert(errorMessage, isPresented: $showError, actions: {})
    }
    @ViewBuilder
    func HelperView()->some View {
        VStack(spacing: 12) {
          
                ZStack {
                    if let userProfilePicData = userProfilePicData,let image = UIImage(data: userProfilePicData) {
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
                Text("Choose Profile Photo!")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 25)

            
            TextField("First Name", text: $firstName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
            TextField("Last Name", text: $lastName)
                .textContentType(.emailAddress)
                .border(1, .gray.opacity(0.5))
            
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
                Text("Sign up")
                    .foregroundColor(.white)
                    .hAlign(.center)
                    .fillView(.black)
            }
            .disableWithOpacity(userName == "" || emailID == "" || password == "" || firstName == "" || lastName == "" || userProfilePicData == nil)
            .padding(.top,10)
        }
    }
    
    func registerUser() {
        isLoading = true
        closeKeyboard()
        
        Task {
            do {
                print("task called")

                try await Auth.auth().createUser(withEmail: emailID, password: password)
                print("account created")

                guard let userUID = Auth.auth().currentUser?.uid else { return }
                guard let imageData = userProfilePicData else { return }
                
                // Upload Image to Firebase Storage
                let storageRef = Storage.storage().reference().child("Profile_Images").child(userUID)
                let _ = try await storageRef.putDataAsync(imageData)
                let downloadURL = try await storageRef.downloadURL()

                // Call the ai moderation to see if safe
                let isSafe = await moderateImage(url: downloadURL.absoluteString)

                if isSafe {
                    let user = User(username: userName, userUID: userUID, userEmail: emailID, userProfileURL: downloadURL, first: firstName, last: lastName, token: userToken)

                    let _ = try Firestore.firestore().collection("Users").document(userUID).setData(from: user) { error in
                        if error == nil {
                            print("Saved Successfully")
                            userNameStored = userName
                            firstNameStored = firstName
                            lastNameStored = lastName
                            self.userUID = userUID
                            profileURL = downloadURL
                            logStatus = true
                        }
                    }
                } else {
                    // Image flagged as inappropriate, delete it
                    try await storageRef.delete()
                    try await Auth.auth().currentUser?.delete()
                    await setError(NSError(domain: "ImageModeration", code: 1, userInfo: [NSLocalizedDescriptionKey: "Profile picture violates content policy."]))
                }
            } catch {
                // Delete account if failure occurs
                try await Auth.auth().currentUser?.delete()
                await setError(error)
            }
        }
    }
    
    func setError(_ error: Error)async{
        await MainActor.run(body: {
            errorMessage = error.localizedDescription
            showError.toggle()
            isLoading = false
        })
    }
    
    func moderateImage(url: String) async -> Bool {
        //TODO: Add API key as environment variable
        let apiKey = ""
        let endpoint = "https://vision.googleapis.com/v1/images:annotate?key=\(apiKey)"
        
        let requestBody: [String: Any] = [
            "requests": [
                [
                    "image": ["source": ["imageUri": url]],
                    "features": [["type": "SAFE_SEARCH_DETECTION"]]
                ]
            ]
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody) else {
            return false
        }

        var request = URLRequest(url: URL(string: endpoint)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let response = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            
            if let responses = response?["responses"] as? [[String: Any]],
               let safeSearch = responses.first?["safeSearchAnnotation"] as? [String: String] {
                
                let adult = safeSearch["adult"] ?? "UNKNOWN"
                let violence = safeSearch["violence"] ?? "UNKNOWN"
                
                return adult == "VERY_UNLIKELY" && violence == "VERY_UNLIKELY"
            }
        } catch {
            print("Error in image moderation: \(error.localizedDescription)")
        }
        
        return false
    }
}

struct RegisterView_Previews: PreviewProvider {
    static var previews: some View {
        RegisterView()
    }
}
