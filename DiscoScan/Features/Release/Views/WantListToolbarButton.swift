//
//  WantListToolbarButton.swift
//  DiscoScan
//

import SwiftUI

struct WantListToolbarButton: View {

    let releaseId: Int

    @Environment(\.wantListStore) private var wantListStore
    @State private var showErrorAlert = false
    @State private var successFeedbackTrigger = 0
    @State private var errorFeedbackTrigger = 0

    private var isInWantList: Bool {
        wantListStore.isInWantList(releaseId: releaseId)
    }

    private var isDisabled: Bool {
        isInWantList || wantListStore.isMutating
    }

    var body: some View {
        Button {
            addToWantList()
        } label: {
            Image(systemName: isInWantList ? "heart.fill" : "heart")
        }
        .disabled(isDisabled)
        .accessibilityLabel(accessibilityLabel)
        .accessibilityHint("Tap to add to Want List")
        .accessibilityAddTraits(isInWantList ? .isSelected : [])
        .sensoryFeedback(.success, trigger: successFeedbackTrigger)
        .sensoryFeedback(.error, trigger: errorFeedbackTrigger)
        .alert("Could Not Add to Want List", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            if let message = wantListStore.lastMutationError {
                Text(message)
            }
        }
    }

    private var accessibilityLabel: String {
        if wantListStore.isMutating {
            return "Updating want list"
        }
        return isInWantList ? "Release is in your Want List" : "Add to Want List"
    }

    private func addToWantList() {
        guard !isInWantList else { return }

        Task {
            await wantListStore.addRelease(releaseId: releaseId)

            if wantListStore.lastMutationError == nil {
                successFeedbackTrigger += 1
            } else {
                showErrorAlert = true
                errorFeedbackTrigger += 1
            }
        }
    }
}

#if DEBUG
#Preview("In Want List") {
    NavigationStack {
        Text("Release Detail")
            .toolbar {
                WantListToolbarButton(releaseId: 1_867_708)
            }
    }
    .environment(\.wantListStore, previewWantListStore(.wantsLoaded))
}

#Preview("Not In Want List") {
    NavigationStack {
        Text("Release Detail")
            .toolbar {
                WantListToolbarButton(releaseId: 999_999)
            }
    }
    .environment(\.wantListStore, previewWantListStore(.wantsLoaded))
}
#endif
