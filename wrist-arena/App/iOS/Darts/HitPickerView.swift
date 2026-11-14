import ArenaCore
import SwiftUI

/// Ręczne wpisanie trafienia: poprawka po źle rozpoznanym rzucie albo gra na prawdziwej tarczy.
struct HitPickerView: View {
    var onPick: @MainActor (DartHit) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var ring: DartRing = .single

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 5)

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("Pole", selection: $ring) {
                    Text("Pojedyncze").tag(DartRing.single)
                    Text("Podwójne").tag(DartRing.double)
                    Text("Potrójne").tag(DartRing.triple)
                }
                .pickerStyle(.segmented)

                LazyVGrid(columns: columns, spacing: 8) {
                    ForEach(1...20, id: \.self) { number in
                        Button(label(for: number)) { pick(DartHit(ring: ring, number: number)) }
                            .buttonStyle(.bordered)
                            .frame(maxWidth: .infinity)
                    }
                }

                HStack {
                    Button("25") { pick(.outerBull) }
                    Button("Bull 50") { pick(.innerBull) }
                    Button("Pudło") { pick(.miss) }
                }
                .buttonStyle(.borderedProminent)
                Spacer()
            }
            .padding()
            .navigationTitle("Wpisz trafienie")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Anuluj") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func label(for number: Int) -> String {
        switch ring {
        case .double: "D\(number)"
        case .triple: "T\(number)"
        default: "\(number)"
        }
    }

    private func pick(_ hit: DartHit) {
        onPick(hit)
        dismiss()
    }
}
