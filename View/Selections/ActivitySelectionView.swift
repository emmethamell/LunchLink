//
//  ActivitySelectionView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/13/23.
//

import SwiftUI
//control-command-spacebar to bring up emojis
struct ActivitySelectionView: View {
    @Binding var selectedActivity: String
    //TODO: add some emojis or little symbols or something
    @State private var activities = ["Breakfast 🥞", "Lunch 🍕", "Dinner 🍝", "Gym 💪", "Ball 🏀", "Drink 🍻", "Party 🎉", "Blaze 🔥", "Study 📚"]

    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView{
            VStack {
                Text("Choose an activity:")
                    .font(.title)
                    .padding()
                
                ForEach(activities, id: \.self) { activity in
                    Button(action: {
                        selectedActivity = activity
                        dismiss()
                    }) {
                        Text(activity)
                            .font(.title)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.all, 5)
                }
            }
        }
    }
}

struct ActivitySelectionView_Previews: PreviewProvider {
    
    static var previews: some View {
        ActivitySelectionView(selectedActivity: .constant("Choose"))
    }
}
