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
            .foregroundStyle(.white)
        }
    }

    private var rulesSection: some View {
        Section {
            ForEach(Array(viewModel.state.rules.enumerated()), id: \.offset) { idx, rule in
                SmartPlaylistRuleRowView(rule: rule) { updated in
                    viewModel.send(.updateRule(idx, updated))
                }
            }
            .onDelete { offsets in
                offsets.forEach { viewModel.send(.removeRule($0)) }
            }
            Button {
                viewModel.send(.addRule)
            } label: {
                Label("Add Rule", systemImage: "plus.circle.fill")
                    .foregroundStyle(.white)
            }
        } header: {
            Text("Rules (AND)")
        }
    }

    private var previewSection: some View {
        Section("Preview") {
            Text("\(viewModel.state.matchCount) song\(viewModel.state.matchCount == 1 ? "" : "s") match")
                .foregroundStyle(.white.opacity(0.7))
                .font(AppFont.callout())
        }
    }

    private var deleteSection: some View {
        Section {
            Button(role: .destructive) {
                viewModel.send(.delete)
            } label: {
                Text("Delete Smart Playlist")
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarItems: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") { viewModel.send(.dismiss) }
                .foregroundStyle(.white)
        }
        ToolbarItem(placement: .confirmationAction) {
            Button("Save") { viewModel.send(.save) }
                .foregroundStyle(.white)
                .disabled(viewModel.state.isSaving)
        }
    }
}

// MARK: - Rule Row

private struct SmartPlaylistRuleRowView: View {

    let rule: SmartPlaylistRule
    let onChange: (SmartPlaylistRule) -> Void

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Picker("Field", selection: Binding(
                    get: { rule.field },
                    set: { onChange(SmartPlaylistRule(field: $0, operator: rule.operator, value: rule.value)) }
                )) {
                    ForEach(RuleField.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .foregroundStyle(.white)

                Picker("Operator", selection: Binding(
                    get: { rule.operator },
                    set: { onChange(SmartPlaylistRule(field: rule.field, operator: $0, value: rule.value)) }
                )) {
                    ForEach(RuleOperator.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.menu)
                .foregroundStyle(.white)
            }

            TextField("Value", text: Binding(
                get: { rule.value },
                set: { onChange(SmartPlaylistRule(field: rule.field, operator: rule.operator, value: $0)) }
            ))
            .foregroundStyle(.white)
            .font(AppFont.body())
        }
        .padding(.vertical, 4)
    }
}
