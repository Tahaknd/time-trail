import SwiftUI

struct ProjectEditView: View {
    @ObservedObject var viewModel: ProjectsViewModel
    let project: Project?
    let onClose: () -> Void

    @State private var name: String
    @State private var color: Color
    @ObservedObject private var themeStore = AppThemeStore.shared

    private static let palette: [String] = [
        "#0091FF", "#22C55E", "#F97316", "#A855F7",
        "#EC4899", "#EAB308", "#14B8A6", "#EF4444",
    ]

    init(viewModel: ProjectsViewModel, project: Project?, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.project = project
        self.onClose = onClose
        _name = State(initialValue: project?.name ?? "")
        _color = State(initialValue: Color(hex: project?.color ?? Self.palette[0]))
    }

    private var isNew: Bool { project == nil }

    var body: some View {
        VStack(spacing: 0) {
            header

            VStack(alignment: .leading, spacing: 20) {
                HStack(spacing: 10) {
                    Circle()
                        .fill(color)
                        .frame(width: 14, height: 14)
                    Text(name.isEmpty ? "Project name" : name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(name.isEmpty ? .tertiary : .primary)
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color(nsColor: .controlBackgroundColor))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                VStack(alignment: .leading, spacing: 6) {
                    Text("NAME")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    TextField("e.g. Client Work", text: $name)
                        .textFieldStyle(.plain)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(nsColor: .controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("COLOR")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                    HStack(spacing: 10) {
                        ForEach(Self.palette, id: \.self) { hex in
                            let swatch = Color(hex: hex)
                            Button {
                                color = swatch
                            } label: {
                                ZStack {
                                    Circle().fill(swatch).frame(width: 26, height: 26)
                                    if swatch.hexString == color.hexString {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .buttonStyle(.plain)
                        }
                        ColorPicker("", selection: $color, supportsOpacity: false)
                            .labelsHidden()
                            .frame(width: 26, height: 26)
                    }
                }
            }
            .padding(20)

            Spacer(minLength: 0)
            Divider()
            footer
        }
        .frame(width: 380, height: 320)
        .background(Color(nsColor: .textBackgroundColor))
        .tint(themeStore.theme.color)
    }

    private var header: some View {
        HStack {
            Text(isNew ? "New Project" : "Edit Project")
                .font(.system(size: 15, weight: .semibold))
            Spacer()
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 14)
    }

    private var footer: some View {
        HStack {
            if let project, let id = project.id {
                Button("Delete", role: .destructive) {
                    viewModel.deleteProject(id: id)
                    onClose()
                }
                .buttonStyle(.plain)
                .foregroundStyle(.red)
            }
            Spacer()
            Button("Cancel") { onClose() }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            Button(isNew ? "Add" : "Save") {
                if let project {
                    viewModel.update(project, name: name, color: color.hexString)
                } else {
                    viewModel.addProject(name: name, color: color.hexString)
                }
                onClose()
            }
            .buttonStyle(.borderedProminent)
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(16)
    }
}
