import SwiftUI

/// Sheet for naming and saving the current EQ curve as a custom user preset.
struct SavePresetSheetView: View {

    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @State private var submitted = false
    @FocusState private var focused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("Custom presets are stored on this device.")
                    .font(AppFont.caption())
                    .foregroundColor(.secondaryText)
                ) {
                    TextField("Preset name", text: $name)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(submit)
                        .foregroundColor(.primaryText)
                        .font(AppFont.body())
                }
            }
            .navigationTitle("Save Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                        .foregroundColor(.primaryText)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: submit)
                        .foregroundColor(.accentPrimary)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(.pressScale)
                }
            }
            .onAppear { focused = true }
        }
        .sensoryFeedback(.success, trigger: submitted)
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        submitted.toggle()
        onSave(trimmed)
    }
}
