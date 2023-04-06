//
//  ResponseView.swift
//  ChartAI
//
//  Created by Stephen Nelson on 4/4/23.
//

import SwiftUI

struct ResponseView: View {
    let responseText: String

    var body: some View {
        VStack {
            Text("Upload Response")
                .font(.title)
                .padding()

            ScrollView {
                Text(responseText)
                    .padding()
            }

            Spacer()

            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Close")
                    .padding()
                    .foregroundColor(Color.white)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.bottom)
        }
        .padding()
    }
    @Environment(\.presentationMode) var presentationMode
}

