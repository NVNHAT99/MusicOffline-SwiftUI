import SwiftUI

/// Sheet for naming and saving the current EQ curve as a custom user preset.
struct SavePresetSheetView: View {

    let onSave: (String) -> Void
    let onCancel: () -> Void

    @State private var name: String = ""
    @FocusState private var focused: Bool

    var body: some View {
        NavigationView {
            Form {
                Section(footer: Text("Custom presets are stored on this device.")) {
                    TextField("Preset name", text: $name)
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(submit)
                }
            }
            .navigationTitle("Save Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: onCancel)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: submit)
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .onAppear { focused = true }
        }
    }

    private func submit() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onSave(trimmed)
    }
}
