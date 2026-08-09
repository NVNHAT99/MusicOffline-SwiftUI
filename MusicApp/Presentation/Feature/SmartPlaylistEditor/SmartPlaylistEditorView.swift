import SwiftUI

struct SmartPlaylistEditorView: View {

    @ObservedObject var viewModel: SmartPlaylistEditorViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.backgroundColor.ignoresSafeArea()
                content
            }
            .navigationTitle(viewModel.state.name.isEmpty ? "New Smart Playlist" : viewModel.state.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarItems }
        }
        .onChange(of: viewModel.state.isDismissed) { _, dismissed in
            if dismissed { dismiss() }
        }
    }

    // MARK: - Content

    private var content: some View {
        List {
            nameSection
            rulesSection
            previewSection
            if !viewModel.state.name.isEmpty {
                deleteSection
            }
        }
        .scrollContentBackground(.hidden)
        .listStyle(.insetGrouped)
    }

    private var nameSection: some View {
        Section("Name") {
            TextField("Playlist name", text: Binding(
                get: { viewModel.state.name },
                set: { viewModel.send(.setName($0)) }
            ))
            .foregroundColor(.primaryText)
            .font(AppFont.body())
        }
    }

    private var rulesSection: some View {
        Section {
            ForEach(Array(viewModel.state.rules.enumerated()), id: \.offset) { idx, rule in
                SmartPlaylistRuleRowView(rule: rule) { updated in
                    viewModel.send(.updateRule(idx, updated))
                }
                .entrance(index: idx)
            }
            .onDelete { offsets in
                offsets.forEach { viewModel.send(.removeRule($0)) }
            }
            Button {
                viewModel.send(.addRule)
            } label: {
                Label("Add Rule", systemImage: "plus.circle.fill")
                    .foregroundColor(.accentPrimary)
                    .font(AppFont.body())
            }
            .buttonStyle(.pressScale)
        } header: {
            Text("Rules (AND)")
                .font(AppFont.caption())
                .foregroundColor(.secondaryText)
        }
    }

    private var previewSection: some View {
        Section("Preview") {
            Text("\(viewModel.state.matchCount) song\(viewModel.state.matchCount == 1 ? "" : "s") match")
                .foregroundColor(.secondaryText)
                .font(AppFont.callout())
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.send(.delete)
            } label: {
                Text("Delete Smart Playlist")
                    .font(AppFont.body())
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { viewModel.send(.dismiss) }
                .foregroundColor(.primaryText)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { viewModel.send(.save) }
                .foregroundColor(.accentPrimary)
                .font(AppFont.headline())
                .disabled(viewModel.state.isSaving)
                .buttonStyle(.pressScale)
        }
    }
}

// MARK: - Rule Row

private struct SmartPlaylistRuleRowView: View {

    let rule: SmartPlaylistRule
    let onChange: (SmartPlaylistRule) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Two labelled columns share the row evenly so the pickers stay
            // aligned instead of the menu labels drifting out of place.
            HStack(alignment: .top, spacing: 12) {
                labeledColumn("Field") {
                    Picker("Field", selection: Binding(
                        get: { rule.field },
                        set: { onChange(SmartPlaylistRule(field: $0, operator: rule.operator, value: rule.value)) }
                    )) {
                        ForEach(RuleField.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(.accentPrimary)
                }

                labeledColumn("Operator") {
                    Picker("Operator", selection: Binding(
                        get: { rule.operator },
                        set: { onChange(SmartPlaylistRule(field: rule.field, operator: $0, value: rule.value)) }
                    )) {
                        ForEach(RuleOperator.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .tint(.accentPrimary)
                }
            }

            TextField("Value", text: Binding(
                get: { rule.value },
                set: { onChange(SmartPlaylistRule(field: rule.field, operator: rule.operator, value: $0)) }
            ))
            .foregroundColor(.primaryText)
            .font(AppFont.body())
            .textFieldStyle(.roundedBorder)
        }
        .padding(.vertical, 4)
    }

    // A small caption label stacked above its control, taking equal row width.
    @ViewBuilder
    private func labeledColumn<Content: View>(_ title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(AppFont.caption())
                .foregroundColor(.secondaryText)
            content()
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
