//
//  LoadingView.swift
//  IosNativeBuild
//
//  Loading indicator component matching KMP LoadingIndicator
//

import SwiftUI

struct LoadingView: View {
    let message: String

    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
