//
//  Proyecto_Bry_y_YaelUITestsLaunchTests.swift
//  Proyecto Bry y YaelUITests
//
//  Created by Facultad de Contaduría y Administración on 24/09/26.
//
//  Captura de la pantalla de arranque de BYbooKS en cada configuración
//  (modo claro/oscuro, orientación) que ejecute Xcode.
//

import XCTest

final class Proyecto_Bry_y_YaelUITestsLaunchTests: XCTestCase {

    override class var runsForEachTargetApplicationUIConfiguration: Bool {
        true
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunch() throws {
        let app = XCUIApplication()
        app.launch()

        // La captura queda adjunta al resultado de la prueba en Xcode (Report navigator).
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Pantalla de inicio"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
