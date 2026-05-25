import CoreLocation
import Foundation

// TODO: replace with real news feed wired through APIClient + a `NewsService`.
enum MockNewsData {
    static func seed(reference: Date = Date()) -> [NewsEvent] {
        let hour: TimeInterval = 3600
        let day: TimeInterval = 86_400

        func ago(_ hours: Double) -> Date {
            reference.addingTimeInterval(-hours * hour)
        }

        func daysAgo(_ days: Double) -> Date {
            reference.addingTimeInterval(-days * day)
        }

        return [
            NewsEvent(
                headline: "Sesión maratónica en el Congreso por la ley ómnibus",
                body: "El recinto sesiona desde el mediodía con quórum justo. Bloques dialoguistas exigen modificaciones al capítulo fiscal antes de habilitar la votación en general.",
                province: .caba,
                coordinate: .init(latitude: -34.61, longitude: -58.38),
                timestamp: ago(1.5),
                category: .politica,
                severity: .breaking
            ),
            NewsEvent(
                headline: "BCRA convalida licitación con tasa más alta",
                body: "La autoridad monetaria adjudicó deuda corta a tasa efectiva superior al 38% buscando contener la dolarización en la previa de la próxima licitación.",
                province: .caba,
                coordinate: .init(latitude: -34.60, longitude: -58.42),
                timestamp: ago(2.4),
                category: .economia
            ),
            NewsEvent(
                headline: "Paro de transporte interurbano en el conurbano",
                body: "Choferes nucleados en UTA detuvieron servicios en La Matanza y Almirante Brown reclamando la actualización de paritarias y el pago de adicionales adeudados.",
                province: .buenosAires,
                coordinate: .init(latitude: -34.80, longitude: -58.30),
                timestamp: ago(4.0),
                category: .social
            ),
            NewsEvent(
                headline: "Operativo conjunto contra el narcomenudeo en Rosario",
                body: "Fuerzas federales y provinciales realizaron 14 allanamientos simultáneos en distintos barrios del sur de la ciudad durante la madrugada de este miércoles, en el marco de una investigación que se extendió por más de ocho meses. El operativo, que contó con la participación de más de 200 efectivos de Gendarmería, la Policía Federal y la fuerza provincial, dejó como saldo seis detenidos directamente vinculados a una organización que operaba en la zona desde fines de 2024 y que, según la fiscalía, había logrado consolidar el control territorial de al menos tres barrios populares. Entre el material secuestrado figuran tres armas largas, dos pistolas, dos vehículos de alta gama, casi un kilo de cocaína fraccionada en dosis listas para la venta, balanzas de precisión, anotaciones contables y cinco millones de pesos en efectivo distribuidos en distintos domicilios. Los investigadores destacaron que la banda utilizaba a menores de edad para tareas de vigilancia y distribución, lo que agravará la calificación penal. La fiscalía especializada en narcocriminalidad solicitó la indagatoria de los detenidos para mañana por la mañana y no descarta nuevas detenciones en las próximas horas, a medida que se analice la documentación y los teléfonos celulares secuestrados durante los procedimientos. Vecinos de la zona, que durante meses denunciaron la presencia de la organización, expresaron alivio aunque también temor a posibles represalias por parte de las facciones que aún permanecen activas en el territorio.",
                province: .santaFe,
                coordinate: .init(latitude: -32.95, longitude: -60.65),
                timestamp: ago(6.2),
                category: .seguridad,
                severity: .breaking
            ),
            NewsEvent(
                headline: "Acuerdo paritario en industria automotriz Córdoba",
                body: "SMATA y las terminales cerraron una pauta del 18% en tres tramos hasta marzo. La medida alcanza a más de 12.000 trabajadores de la provincia.",
                province: .cordoba,
                coordinate: .init(latitude: -31.42, longitude: -64.18),
                timestamp: ago(7.5),
                category: .economia
            ),
            NewsEvent(
                headline: "Tensión en mesa de diálogo minero",
                body: "Comunidades originarias exigen estudios de impacto ambiental ampliados antes de avanzar con la prospección en el Valle Calingasta.",
                province: .sanJuan,
                timestamp: ago(9.0),
                category: .politica
            ),
            NewsEvent(
                headline: "Hallazgo arqueológico en quebrada jujeña",
                body: "Investigadores del CONICET datan piezas cerámicas en más de 1.500 años. La pieza central viajará al museo de Tilcara para su exhibición pública.",
                province: .jujuy,
                coordinate: .init(latitude: -23.59, longitude: -65.35),
                timestamp: ago(11.0),
                category: .social
            ),
            NewsEvent(
                headline: "Repunta exportación de soja por puertos de Rosario",
                body: "El Gran Rosario embarcó 2,1 millones de toneladas en la última quincena, el mejor registro del año. Productores aceleran ventas previo a la liquidación.",
                province: .santaFe,
                coordinate: .init(latitude: -33.05, longitude: -60.62),
                timestamp: ago(14.0),
                category: .economia
            ),
            NewsEvent(
                headline: "Vientos extremos cortan rutas patagónicas",
                body: "Defensa Civil cerró tramos de la Ruta 3 entre Trelew y Comodoro por ráfagas superiores a 120 km/h. Se recomienda no transitar hasta nuevo aviso.",
                province: .chubut,
                coordinate: .init(latitude: -43.30, longitude: -65.10),
                timestamp: ago(18.0),
                category: .otro,
                severity: .breaking
            ),
            NewsEvent(
                headline: "Reunión de gobernadores del NOA por coparticipación",
                body: "Los mandatarios de Salta, Jujuy, Tucumán y Catamarca acordaron una postura común para reclamar a Nación una recomposición de los fondos automáticos.",
                province: .salta,
                coordinate: .init(latitude: -24.78, longitude: -65.41),
                timestamp: ago(22.0),
                category: .politica
            ),
            NewsEvent(
                headline: "Brote de dengue mantiene alerta sanitaria",
                body: "El ministerio provincial reporta más de 4.200 casos en la última semana. Se intensifica la fumigación y se distribuye repelente en zonas de mayor circulación.",
                province: .misiones,
                coordinate: .init(latitude: -27.36, longitude: -55.90),
                timestamp: daysAgo(1.3),
                category: .social
            ),
            NewsEvent(
                headline: "Inauguración de parque eólico en Bahía Blanca",
                body: "El complejo aporta 122 MW al sistema interconectado nacional y abastece a más de 180.000 hogares. Es la mayor obra renovable del año en la provincia.",
                province: .buenosAires,
                coordinate: .init(latitude: -38.72, longitude: -62.27),
                timestamp: daysAgo(1.9),
                category: .economia
            ),
            NewsEvent(
                headline: "Demoras en la represa Cóndor Cliff",
                body: "La obra hidroeléctrica binacional acumula 18 meses de retraso. La empresa concesionaria adujo trabas logísticas y reclama una nueva renegociación.",
                province: .santaCruz,
                coordinate: .init(latitude: -49.70, longitude: -70.20),
                timestamp: daysAgo(2.4),
                category: .economia
            ),
            NewsEvent(
                headline: "Detención clave en causa por tierras fiscales",
                body: "El juez federal de Bariloche ordenó la captura de un ex funcionario provincial acusado de adjudicar lotes sin licitación entre 2019 y 2022.",
                province: .rioNegro,
                coordinate: .init(latitude: -41.13, longitude: -71.31),
                timestamp: daysAgo(3.1),
                category: .seguridad
            ),
            NewsEvent(
                headline: "Pesca regional reporta caída del 12% interanual",
                body: "Cámaras del sector alertan por la baja captura de merluza y calamar. Aducen condiciones oceanográficas adversas y mayor presión de flotas extranjeras.",
                province: .tierraDelFuego,
                coordinate: .init(latitude: -54.81, longitude: -68.30),
                timestamp: daysAgo(4.0),
                category: .economia
            ),
            NewsEvent(
                headline: "Crece tensión por toma de tierras en Plottier",
                body: "Vecinos del oeste ocupan un predio fiscal de 14 hectáreas reclamando viviendas. El municipio convocó a una mesa de diálogo para el viernes.",
                province: .neuquen,
                coordinate: .init(latitude: -38.96, longitude: -68.23),
                timestamp: daysAgo(5.2),
                category: .seguridad
            ),
            NewsEvent(
                headline: "Récord de turismo de fin de semana largo",
                body: "La provincia recibió más de 320.000 visitantes con una ocupación promedio del 92%. El gasto turístico superó los 8.000 millones de pesos.",
                province: .mendoza,
                coordinate: .init(latitude: -32.89, longitude: -68.85),
                timestamp: daysAgo(8.0),
                category: .social
            ),
            NewsEvent(
                headline: "Lluvias récord generan evacuados en el norte",
                body: "El sistema frontal dejó más de 220 mm en menos de 48 horas. Hay 1.400 evacuados en Formosa y Clorinda y se mantienen cortes en la Ruta 11.",
                province: .formosa,
                coordinate: .init(latitude: -25.30, longitude: -58.20),
                timestamp: daysAgo(12.0),
                category: .otro
            ),
            NewsEvent(
                headline: "Sequía complica cosecha de algodón",
                body: "Productores chaqueños reportan caídas de rendimiento del 35% promedio. Reclaman al gobierno la activación de un fondo de emergencia agropecuaria.",
                province: .chaco,
                coordinate: .init(latitude: -27.45, longitude: -58.99),
                timestamp: daysAgo(18.0),
                category: .economia
            ),
            NewsEvent(
                headline: "Conflicto azucarero suma asambleas en Tucumán",
                body: "Cañeros y obreros de los ingenios paralizaron actividades en cuatro plantas. Reclaman precio sostén y la actualización de salarios atrasados.",
                province: .tucuman,
                coordinate: .init(latitude: -26.85, longitude: -65.20),
                timestamp: daysAgo(24.0),
                category: .social
            ),
        ]
    }
}
