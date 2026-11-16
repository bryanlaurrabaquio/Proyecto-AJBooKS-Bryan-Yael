//
//  Proyecto_Bry_y_YaelUITests.swift
//  Proyecto Bry y YaelUITests
//
//  Created by Facultad de Contaduría y Administración on 24/09/26.
//
//  Pruebas de interfaz de BYbooKS.
//
//  No dependen de la red: solo comprueban elementos que se dibujan al abrir la app
//  (el catálogo se carga de Open Library y puede tardar o fallar sin conexión).
//

import XCTest

final class Proyecto_Bry_y_YaelUITests: XCTestCase {

    override func setUpWithError() throws {
        // En las pruebas de interfaz conviene detenerse en el primer fallo.
        continueAfterFailure = false
    }

    @MainActor
    func testPantallaInicialMuestraMarcaBuscadorYFavoritos() throws {
        let app = XCUIApplication()
        app.launch()

        XCTAssertTrue(app.staticTexts["BYbooKS"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.textFields["campoBusqueda"].exists)
        XCTAssertTrue(app.buttons["botonFavoritos"].exists)
    }

    @MainActor
    func testFavoritosSeAbreDesdeInicio() throws {
        let app = XCUIApplication()
        app.launch()

        let favoritos = app.buttons["botonFavoritos"]
        XCTAssertTrue(favoritos.waitForExistence(timeout: 5))
        favoritos.tap()

        XCTAssertTrue(app.navigationBars["Favoritos"].waitForExistence(timeout: 5))
    }

    @MainActor
    func testLaunchPerformance() throws {
        // Mide cuánto tarda en abrir la aplicación.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }
}
