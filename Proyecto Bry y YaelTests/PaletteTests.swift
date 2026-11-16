import UIKit
import XCTest
@testable import Proyecto_Bry_y_Yael

// La paleta se define en Assets.xcassets y se referencia por nombre en Palette.swift.
// Estas pruebas evitan que un nombre mal escrito deje un color vacío en la interfaz.
@MainActor
final class PaletteTests: XCTestCase {

    func testAllPaletteColorsExistInAssetCatalog() {
        for name in Palette.assetNames {
            XCTAssertNotNil(
                UIColor(named: name, in: .main, compatibleWith: nil),
                "Falta el color \(name) en Assets.xcassets"
            )
        }
    }

    func testPaletteColorsHaveLightAndDarkVariants() throws {
        for name in Palette.assetNames {
            let color = try XCTUnwrap(UIColor(named: name, in: .main, compatibleWith: nil))
            let light = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            let dark = color.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            XCTAssertNotEqual(light, dark, "\(name) debería tener una variante para modo oscuro")
        }
    }
}
