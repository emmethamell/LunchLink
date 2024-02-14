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
    @State private var activities = ["🥞 Breakfast", "🍕 Lunch", "🍝 Dinner", "💪 Gym", "🏀 Ball", "🍻 Drink", "🎉 Party", "📚Study", "🙏 Pray"]

    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView(.vertical, showsIndicators: false){
            VStack {
                ForEach(activities, id: \.self) { activity in
                    Button(action: {
                        if activity == selectedActivity {
                            selectedActivity = "Choose"
                        } else {
                            selectedActivity = activity
                        }
                        //dismiss()
                    }) {
                        HStack{
                            Text(activity)
                                .font(.title)
                            
                            if selectedActivity == activity {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.green)
                            }
                            
                        }
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.black)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding(.all, 5)
                }
            }
            .padding()
        }
        .overlay(
            VStack {
                LinearGradient(gradient: Gradient(colors: [.white, .clear]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 10)

                Spacer()
                LinearGradient(gradient: Gradient(colors: [.white, .clear]), startPoint: .bottom, endPoint: .top)
                    .frame(height: 10) 
            }
            .edgesIgnoringSafeArea(.vertical)
            )
    }
}

struct ActivitySelectionView_Previews: PreviewProvider {
    
    static var previews: some View {
        ActivitySelectionView(selectedActivity: .constant("Choose"))
    }
}
