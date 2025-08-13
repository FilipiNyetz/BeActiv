//
//  ActivityCard.swift
//  BeActiv
//
//  Created by Filipi Romão on 10/08/25.
//

import SwiftUI

struct Activity{
    let id: Int
    let title: String
    let subtitle: String
    let image: String
    let amount: String
}



struct ActivityCard: View {
    
    @State var activity: Activity
    
    var body: some View {
        ZStack{
            Color(.systemGray6)
                .cornerRadius(6)
            VStack {
                HStack(alignment: .top){
                    
                    VStack(alignment: .leading, spacing: 5){
                        Text(activity.title)
                        
                        Text(activity.subtitle)
                            .font(.caption)
                    }
                    
                    Spacer()
                    
                    Image(systemName: activity.image)
                        .foregroundColor(.green)
                }
                .padding()
                
                Text(activity.amount)
            }
            .padding()
        }
       
    }
}

#Preview {
    ActivityCard(activity: Activity(id:0, title: "Daily Steps", subtitle: "Goal: 10.000", image: "figure.walk", amount: "6.830"))
}
