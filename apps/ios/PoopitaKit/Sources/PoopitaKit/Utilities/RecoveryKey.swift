import CryptoKit
import Foundation

struct RecoveryKey: Equatable, Sendable {
    static let byteCount = 32
    static let groupLength = 4
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ")
    private static let characterCount = (byteCount * 8 + 4) / 5

    let data: Data

    init?(data: Data) {
        guard data.count == Self.byteCount else { return nil }
        self.data = data
    }

    init?(text: String) {
        let symbols = text.uppercased().compactMap { Self.value(of: $0) }
        let typed = text.filter { !$0.isWhitespace && $0 != "-" }
        guard symbols.count == Self.characterCount, typed.count == symbols.count else { return nil }
        var bytes: [UInt8] = []
        var buffer = 0
        var bits = 0
        for symbol in symbols {
            buffer = (buffer << 5) | symbol
            bits += 5
            if bits >= 8 {
                bits -= 8
                bytes.append(UInt8((buffer >> bits) & 0xFF))
                buffer &= (1 << bits) - 1
            }
        }
        guard bytes.count == Self.byteCount, buffer & ((1 << bits) - 1) == 0 else { return nil }
        data = Data(bytes)
    }

    static func generate() -> RecoveryKey {
        let key = SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
        return RecoveryKey(generated: key)
    }

    var groups: [String] {
        let characters = encoded
        return stride(from: 0, to: characters.count, by: Self.groupLength).map {
            String(characters[$0 ..< min($0 + Self.groupLength, characters.count)])
        }
    }

    var symmetricKey: SymmetricKey {
        SymmetricKey(data: data)
    }

    var fingerprint: Data {
        var hash = SHA256()
        hash.update(data: Data("poopita.backup.key".utf8))
        hash.update(data: data)
        return Data(hash.finalize().prefix(8))
    }

    private init(generated data: Data) {
        self.data = data
    }

    private var encoded: [Character] {
        var characters: [Character] = []
        var buffer = 0
        var bits = 0
        for byte in data {
            buffer = (buffer << 8) | Int(byte)
            bits += 8
            while bits >= 5 {
                bits -= 5
                characters.append(Self.alphabet[(buffer >> bits) & 0x1F])
            }
            buffer &= (1 << bits) - 1
        }
        if bits > 0 {
            characters.append(Self.alphabet[(buffer << (5 - bits)) & 0x1F])
        }
        return characters
    }

    private static func value(of character: Character) -> Int? {
        switch character {
        case "O": 0
        case "I", "L": 1
        default: alphabet.firstIndex(of: character)
        }
    }
}
