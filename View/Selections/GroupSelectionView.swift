//
//  GroupSelectionView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/13/23.
//

import SwiftUI

struct GroupSelectionView: View {
    @Binding var selectedGroup: String
    //TODO: "groups" list should have an option "everyone", and other custom groups
    //you can break this up into "group" objects?
    //for every user, store when they create a new group, for everyone, just send to all friends
    @State private var groups = ["Everyone", "Group 2", "Group 3", "Group 4", "Group 5", "Group 6"]
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        ScrollView{
            VStack {
                Text("Choose a Group:")
                    .font(.title)
                    .padding()
                
                ForEach(groups, id: \.self) { group in
                    Button(action: {
                        selectedGroup = group
                        dismiss()
                    }) {
                        Text(group)
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

struct GroupSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        GroupSelectionView(selectedGroup: .constant("Choose"))
    }
}
