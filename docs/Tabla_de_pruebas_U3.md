# Tabla de pruebas (versión de la Unidad 3)

**Qué se prueba:** la versión de la Unidad 3 (`unidad3/Proyecto_Ventas_Inventario_U3.asm`) debe comportarse igual que la de la Unidad 2: mismas funciones, mismos mensajes, mismas validaciones y misma regla del negocio. Se vuelven a probar el registro y la búsqueda (A), las entradas de mercancía (B), las ventas aceptadas y rechazadas y la regla del negocio (C), el resumen (D), el guardado y la carga (E) y la pila y los registros (F). La sección G compara las dos versiones.

**Cómo usarla:** ejecuta el programa, cada prueba con el catálogo recién cargado (opción 8 con `inventario.dat`) salvo que se indique otra cosa, y llena la columna **Resultado obtenido** con lo que realmente pasó (puedes escribir "OK" si coincide, o describir la diferencia).

Catálogo base: CTL-001 (15 uds, $899.00), AUD-002 (8 uds, $649.50), MEM-003 (30 uds, $249.90).

## A. Registro y consulta

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| A1 | Cargar el archivo | Opción 8 | "Catalogo cargado. Productos recuperados: 3" | |
| A2 | Mostrar inventario | Opción 2 | 3 líneas, por ejemplo `CTL-001 \| Control inalambrico \| $899.00 MXN \| Existencia: 15` | |
| A3 | Alta válida | `PAP-004`, `Cuaderno profesional`, `12.05`, `20` | "Producto registrado correctamente"; en la opción 2 aparece con `$12.05 MXN` | |
| A4 | Alta con código duplicado | `CTL-001` | "Ese codigo ya existe..."; el catálogo no cambia | |
| A5 | Código con minúsculas | `abc-123` | "Codigo incorrecto..." | |
| A6 | Código sin guion | `ABC123` | "Codigo incorrecto..." | |
| A7 | Código demasiado largo | `AB-1234` | "Codigo incorrecto..." | |
| A8 | Código con letra en los dígitos | `ABC-12A` | "Codigo incorrecto..." | |
| A9 | Nombre vacío | Código válido y luego Enter | "Nombre invalido..." y no se registra | |
| A10 | Nombre de 26 caracteres | `abcdefghijklmnopqrstuvwxyz` | "Nombre invalido..." y no se registra | |
| A11 | Precio entero | `185` | Se acepta; se muestra `$185.00 MXN` | |
| A12 | Precio con un decimal | `185.5` | Se acepta; se muestra `$185.50 MXN` | |
| A13 | Precio con dos decimales | `185.50` | Se acepta; se muestra `$185.50 MXN` | |
| A14 | Precio con símbolo | `$185` | "Precio invalido..." | |
| A15 | Precio con separador de miles | `1,000` | "Precio invalido..." | |
| A16 | Precio con tercer decimal | `10.999` | "Precio invalido..." | |
| A17 | Precio cero | `0` y `0.00` | "Precio invalido..." | |
| A18 | Precio fuera de rango | `10000` | "Precio invalido..." | |
| A19 | Precio máximo | `9999.99` | Se acepta; se muestra `$9999.99 MXN` | |
| A20 | Precio mínimo | `0.01` | Se acepta; se muestra `$0.01 MXN` | |
| A21 | Precio con punto sin decimales o sin pesos | `185.` y `.50` | "Precio invalido..." en ambos | |
| A22 | Precio vacío | Enter | "Precio invalido..." | |
| A23 | Existencia fuera de rango | `101` | "Existencia invalida..." y no se registra | |
| A24 | Existencia con signo o letras | `-5` y `abc` | "Existencia invalida..." | |
| A25 | Existencia en los límites | `0` y `100` | Ambas se aceptan | |
| A26 | Capacidad llena | Registrar un 11.º producto (con 10 ya registrados) | "No se puede registrar: ya hay 10 productos..." | |
| A27 | Búsqueda existente | Opción 3, `CTL-001` | Muestra la línea de CTL-001 | |
| A28 | Búsqueda inexistente | Opción 3, `AUD-999` | "No existe un producto con ese codigo" | |
| A29 | Búsqueda con formato incorrecto | Opción 3, `xyz` | "Codigo incorrecto..." | |

## B. Recibir mercancía

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| B1 | Entrada válida hasta el límite | `MEM-003`, `70` | "Mercancia recibida. Nueva existencia: 100" | |
| B2 | Entrada que excede 100 | `MEM-003`, `71` | "No se puede: la existencia pasaria de 100 unidades"; en la opción 2 sigue en 30 | |
| B3 | Cantidad inválida | `0`, `-3`, `2.5`, `abc`, Enter | "Cantidad invalida..." en todos los casos | |
| B4 | Producto inexistente | `AUD-999`, `5` | "No existe un producto con ese codigo" | |

## C. Ventas y regla del negocio

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| C1 | Venta sin descuento (4 uds) | `CTL-001`, `4` | Base `$3596.00 MXN`; "Sin descuento..."; final `$3596.00 MXN`; restante 11 | |
| C2 | Venta con descuento (5 uds) | `CTL-001`, `5` | Base `$4495.00 MXN`; descuento `$449.50 MXN`; final `$4045.50 MXN`; restante 10 | |
| C3 | Vender toda la existencia | `AUD-002`, `8` | Base `$5196.00 MXN`; descuento `$519.60 MXN`; final `$4676.40 MXN`; restante 0 | |
| C4 | Venta sin existencias suficientes | `AUD-002`, `9` | "Existencias insuficientes... Existencia actual: 8"; ingresos y existencia no cambian | |
| C5 | Descuento sin fracción de centavo | Producto de `$12.05` (A3), vender `5` | Base `$60.25 MXN`; descuento `$6.02 MXN`; final `$54.23 MXN` | |
| C6 | Cantidad inválida | `0`, `abc` | "Cantidad invalida..." | |
| C7 | Producto inexistente | `AUD-999`, `1` | "No existe un producto con ese codigo" | |

## D. Resumen

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| D1 | Resumen con el catálogo recién cargado | Opción 6 | Unidades 53; valor `$26178.00 MXN`; ingresos `$0.00 MXN` | |
| D2 | Resumen tras la venta C2 (solo esa) | Opción 6 | Unidades 48; valor `$21683.00 MXN`; ingresos `$4045.50 MXN` | |
| D3 | Resumen sin productos | Ejecutar y opción 6 sin cargar | Unidades 0; valor `$0.00 MXN`; ingresos `$0.00 MXN` | |

## E. Archivo

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| E1 | Guardar | Opción 7 (con 3 productos) | "Catalogo guardado... Bytes escritos: 134" | |
| E2 | Aviso al salir con cambios | Hacer un alta y opción 0 | Pregunta "Hay cambios sin guardar..."; con `N` regresa al menú; con `S` sale | |
| E3 | Salir sin cambios | Guardar y opción 0 | Sale sin preguntar | |
| E4 | Recuperar en otra ejecución | Guardar, salir, volver a ejecutar, opción 8 | Recupera los mismos productos y existencias que se guardaron | |
| E5 | Archivo ausente | Renombrar `inventario.dat`, opción 8 | "No se encontro el archivo inventario.dat"; el catálogo en memoria no cambia | |
| E6 | Archivo con marca incorrecta | Copiar `pruebas/invalido_marca.dat` como `inventario.dat`, opción 8 | "El archivo es invalido o esta danado"; el catálogo no cambia | |
| E7 | Archivo con código repetido | Copiar `pruebas/invalido_duplicado.dat` como `inventario.dat`, opción 8 | "El archivo es invalido o esta danado"; el catálogo no cambia | |
| E8 | Archivo truncado | Recortar `inventario.dat` a unos 100 bytes, opción 8 | "El archivo es invalido o esta danado" (el tamaño no coincide) | |

## F. Pila y registros

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| F1 | Conservación de registros y pila | Opción 9 | Muestra `$185.50 MXN`, `77`, y los mensajes "...se conservaron. OK" y "...la pila esta equilibrada... OK" | |
| F2 | Pila en el menú | Usar varias opciones seguidas | Nunca aparece "ERROR: la pila no quedo equilibrada" | |

## G. Regresión: la Unidad 3 debe dar lo mismo que la Unidad 2

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| G1 | Misma secuencia en las dos versiones | Con cada versión: opción 8; opción 1 con `PAP-004`, `Cuaderno profesional`, `12.05`, `20`; opción 5 con `PAP-004` × 5; opción 6 | Las dos versiones muestran exactamente los mismos textos y los mismos importes (`$60.25`, descuento `$6.02`, final `$54.23 MXN`) | |
| G2 | Búsqueda por el procedimiento compartido | Opción 3 con `CTL-001`; opción 4 con `AUD-999`; opción 5 con `AUD-999` | Opción 3 muestra el producto. Las opciones 4 y 5 muestran "No existe un producto con ese codigo" en ambos casos | |
| G3 | Código con formato incorrecto en las tres opciones | Opciones 3, 4 y 5 con `abc-123` | "Codigo incorrecto..." en las tres, sin cambios en el catálogo | |
| G4 | Alta rechazada no deja datos a medias | Opción 1 con `PAP-005`, `Lapiz`, `0`; luego opción 2 | "Precio invalido..." y en la opción 2 **no** aparece `PAP-005` | |
| G5 | Guardar y cargar con la versión nueva | Opción 7 y opción 0; volver a ejecutar; opción 8; opción 2 | Se recuperan los mismos productos y existencias | |
| G6 | Archivo de la Unidad 2 con la Unidad 3 | Guardar con la versión 2, cargar con la versión 3 | Se carga sin errores (el formato del archivo no cambió) | |
| G7 | Rechazo de archivos dañados | Copiar `pruebas/invalido_marca.dat` y luego `pruebas/invalido_duplicado.dat` como `inventario.dat`; opción 8 | "El archivo es invalido o esta danado" en los dos casos y el catálogo no cambia | |
| G8 | Pila en todas las opciones | Usar las opciones 1 a 9 varias veces y luego la opción 9 | Nunca aparece "ERROR: la pila no quedo equilibrada"; la opción 9 muestra los dos mensajes de OK | |
