//
//  DislikedUsersView.swift
//  LunchLink
//
//  Created by Emmet Hamell on 12/22/23.
//

import SwiftUI

struct DislikedUsersView: View {
    var userUIDs: [String]

    var body: some View {
        List(userUIDs, id: \.self) { userUID in
            Text("User: \(userUID)")
            // Display more user info here
        }
    }
}


