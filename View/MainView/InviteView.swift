//
//  InviteView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 11/12/23.
//

import SwiftUI

struct InviteView: View {
    @State private var selectedActivity: String = "Choose"
    @State private var selectedGroup: String = "Choose"


    var body: some View {
        VStack {
            VStack {
                NavigationLink(destination: ProfileView()){
                    Image(systemName: "person.circle")
                        .resizable()
                        .frame(width:30, height:30)
                }
            }
            .padding(20)
            .hAlign(.trailing)
            
            //Contents in this stack
            VStack {
                    VStack(alignment: .center, spacing: 20) {
                        
                        Text("What do you want to do?")
                            .font(.title)
                        
                        NavigationLink(destination: ActivitySelectionView(selectedActivity: $selectedActivity).toolbar(.hidden)) {
                            Text(selectedActivity)
                                .font(.title)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(Color.black)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }

                            Text("With who?")
                            .font(.title)

                        NavigationLink(destination: GroupSelectionView(selectedGroup: $selectedGroup).toolbar(.hidden)) {
                                Text(selectedGroup)
                                    .font(.title)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.black)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        
                        Spacer()
                    }
                    .padding()
            }
            // end of stack

        }
        .vAlign(.top)
    }
}


struct InviteView_Previews: PreviewProvider {
    static var previews: some View {
        InviteView()
    }
}
