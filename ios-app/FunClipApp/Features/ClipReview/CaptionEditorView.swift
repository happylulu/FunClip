import SwiftUI

struct CaptionEditorView: View {
    let clip: ProcessedClip
    let existingCaptions: [Caption]?
    let onSave: ([Caption]) -> Void
    
    @State private var captionText = ""
    @State private var captionStyle = CaptionStyle()
    @State private var isGenerating = false
    @State private var generatedCaption = ""
    @State private var showError = false
    @State private var errorMessage = ""
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview Card
                    CaptionPreviewCard(
                        text: captionText.isEmpty ? "Your caption will appear here" : captionText,
                        style: captionStyle
                    )
                    
                    // Auto-Generate Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Auto-Generate", systemImage: "wand.and.stars")
                            .font(.headline)
                        
                        Button(action: generateCaption) {
                            HStack {
                                if isGenerating {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Image(systemName: "sparkles")
                                }
                                Text(isGenerating ? "Generating..." : "Generate AI Caption")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                        }
                        .disabled(isGenerating)
                        
                        if !generatedCaption.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Generated Caption:")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Text(generatedCaption)
                                    .padding()
                                    .background(Color.purple.opacity(0.1))
                                    .cornerRadius(8)
                                
                                Button("Use This Caption") {
                                    captionText = generatedCaption
                                }
                                .font(.caption)
                                .foregroundColor(.purple)
                            }
                        }
                    }
                    
                    // Manual Input Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Caption Text", systemImage: "text.bubble")
                            .font(.headline)
                        
                        TextEditor(text: $captionText)
                            .frame(minHeight: 100)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                        
                        Text("\(captionText.count) characters")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    // Style Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Caption Style", systemImage: "paintbrush")
                            .font(.headline)
                        
                        // Position
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Position")
                                .font(.subheadline)
                            
                            Picker("Position", selection: $captionStyle.position) {
                                Text("Top").tag(CaptionPosition.top)
                                Text("Center").tag(CaptionPosition.center)
                                Text("Bottom").tag(CaptionPosition.bottom)
                            }
                            .pickerStyle(SegmentedPickerStyle())
                        }
                        
                        // Font Size
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Font Size")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(captionStyle.fontSize))pt")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Slider(value: $captionStyle.fontSize, in: 12...32, step: 1)
                        }
                        
                        // Colors
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Colors")
                                .font(.subheadline)
                            
                            HStack {
                                ColorPicker("Text", selection: $captionStyle.color)
                                Spacer()
                                ColorPicker("Background", selection: $captionStyle.backgroundColor)
                            }
                        }
                        
                        // Preset Styles
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Preset Styles")
                                .font(.subheadline)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 12) {
                                    ForEach(CaptionPreset.allCases, id: \.self) { preset in
                                        PresetButton(
                                            preset: preset,
                                            isSelected: false,
                                            action: {
                                                applyPreset(preset)
                                            }
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Add Captions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAndDismiss()
                    }
                    .fontWeight(.semibold)
                    .disabled(captionText.isEmpty)
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage)
            }
        }
        .onAppear {
            if let existing = existingCaptions?.first {
                captionText = existing.text
                captionStyle = existing.style
            }
        }
    }
    
    // MARK: - Actions
    
    private func generateCaption() {
        isGenerating = true
        
        Task {
            do {
                // Call AI service to generate caption
                // For now, use a mock response
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                await MainActor.run {
                    generatedCaption = generateMockCaption()
                    isGenerating = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = "Failed to generate caption"
                    showError = true
                    isGenerating = false
                }
            }
        }
    }
    
    private func generateMockCaption() -> String {
        let templates = [
            "🔥 This moment is everything! \(clip.reason)",
            "Wait for it... 😱 #viral #fyp",
            "POV: \(clip.reason) 💯",
            "Nobody: ... Me: *watches this on repeat* 🔄",
            "The \(clip.reason) we didn't know we needed ✨"
        ]
        
        return templates.randomElement() ?? "Amazing moment!"
    }
    
    private func applyPreset(_ preset: CaptionPreset) {
        captionStyle = preset.style
    }
    
    private func saveAndDismiss() {
        let caption = Caption(
            id: UUID().uuidString,
            text: captionText,
            startTime: clip.startTime,
            endTime: clip.endTime,
            style: captionStyle
        )
        
        onSave([caption])
        dismiss()
    }
}

// MARK: - Subviews

struct CaptionPreviewCard: View {
    let text: String
    let style: CaptionStyle
    
    var body: some View {
        ZStack {
            // Video preview placeholder
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.black, Color.gray.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(height: 200)
                .overlay(
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.5))
                )
            
            // Caption overlay
            VStack {
                if style.position == .top {
                    captionView
                    Spacer()
                } else if style.position == .center {
                    Spacer()
                    captionView
                    Spacer()
                } else {
                    Spacer()
                    captionView
                }
            }
            .padding()
        }
    }
    
    var captionView: some View {
        Text(text)
            .font(.system(size: style.fontSize))
            .foregroundColor(style.color)
            .multilineTextAlignment(.center)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(style.backgroundColor)
            .cornerRadius(8)
    }
}

struct PresetButton: View {
    let preset: CaptionPreset
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(preset.style.backgroundColor)
                        .frame(width: 60, height: 40)
                    
                    Text("Aa")
                        .font(.system(size: 16))
                        .foregroundColor(preset.style.color)
                }
                
                Text(preset.rawValue)
                    .font(.caption2)
                    .foregroundColor(.primary)
            }
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.indigo : Color.clear, lineWidth: 2)
            )
        }
    }
}

// MARK: - Caption Presets

enum CaptionPreset: String, CaseIterable {
    case classic = "Classic"
    case bold = "Bold"
    case minimal = "Minimal"
    case neon = "Neon"
    case shadow = "Shadow"
    case gradient = "Gradient"
    
    var style: CaptionStyle {
        switch self {
        case .classic:
            return CaptionStyle(
                position: .bottom,
                fontSize: 18,
                color: .white,
                backgroundColor: .black.opacity(0.7)
            )
        case .bold:
            return CaptionStyle(
                position: .center,
                fontSize: 24,
                color: .yellow,
                backgroundColor: .black.opacity(0.9)
            )
        case .minimal:
            return CaptionStyle(
                position: .bottom,
                fontSize: 16,
                color: .white,
                backgroundColor: .clear
            )
        case .neon:
            return CaptionStyle(
                position: .center,
                fontSize: 22,
                color: .cyan,
                backgroundColor: .black.opacity(0.8)
            )
        case .shadow:
            return CaptionStyle(
                position: .bottom,
                fontSize: 20,
                color: .white,
                backgroundColor: .black.opacity(0.5)
            )
        case .gradient:
            return CaptionStyle(
                position: .center,
                fontSize: 20,
                color: .white,
                backgroundColor: .purple.opacity(0.6)
            )
        }
    }
}