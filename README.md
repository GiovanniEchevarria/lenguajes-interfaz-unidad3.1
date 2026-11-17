# Sistema de ventas e inventario en ensamblador (MASM x86 / Irvine32)

## Datos generales

| | |
|---|---|
| **Materia** | Lenguajes de Interfaz |
| **Unidades** | Unidad 2 (proyecto original) y Unidad 3 (refactorización con procedimientos, macros y `USES`) |
| **Alumno** | Giovanni De Jesus Echevarria Yañez |
| **Horario** | 10-11 |
| **Docente** | Dr. José Luis Medina Jiménez |

## Contenido del repositorio

| Archivo | Descripción |
|---|---|
| [unidad3/Proyecto_Ventas_Inventario_U3.asm](unidad3/Proyecto_Ventas_Inventario_U3.asm) | **Versión de la Unidad 3**: mismas funciones, validaciones y regla del negocio, con procedimientos nuevos, 9 macros y `USES` |
| [unidad2/Proyecto_Ventas_Inventario_U2.asm](unidad2/Proyecto_Ventas_Inventario_U2.asm) | Versión original de la Unidad 2, para comparar |
| [inventario.dat](inventario.dat) | Archivo de inventario de prueba (3 productos) |
| [pruebas/invalido_marca.dat](pruebas/invalido_marca.dat) | Archivo dañado: marca incorrecta |
| [pruebas/invalido_duplicado.dat](pruebas/invalido_duplicado.dat) | Archivo dañado: código repetido |
| [docs/Reporte.md](docs/Reporte.md) | Reporte: informe de la Unidad 2 y sección **Versión de la Unidad 3** |
| [docs/Tabla_de_pruebas_U3.md](docs/Tabla_de_pruebas_U3.md) | Tabla de pruebas con entrada, resultado esperado y resultado obtenido |
| [docs/Instrucciones_compilacion.md](docs/Instrucciones_compilacion.md) | Cómo compilar y ejecutar |

## Resumen de la versión de la Unidad 3

- **Procedimientos:** 14 nuevos (por ejemplo `CmpCodigo`, `PideYBuscaProducto`, `CalculaDescuento`, `ValidaArchivo`) que quitan bloques repetidos y separan captura, validación, cálculo y presentación.
- **Macros:** 9 (`Mostrar`, `LineaImporte`, `LineaNumero`, `FueraDeRango`, `MostrarYRegresar`, `IniciaRecorrido`, `CompruebaReg`, `ChequeaPila` y `OpcionMenu`). Las dos últimas llevan `LOCAL`.
- **`USES`:** en 38 de los 40 procedimientos, en lugar de `push` y `pop` a mano.
- **Líneas de código fuente:** de 1157 a 952, contadas con el mismo criterio en las dos versiones (detalle en el reporte).
