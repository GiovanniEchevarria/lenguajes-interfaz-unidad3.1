# Informe breve: Sistema de ventas e inventario en ensamblador

**Materia:** Lenguajes de Interfaz · **Unidades:** 2 y 3
**Alumno:** (escribe aquí tu nombre) · **Horario:** (escribe aquí tu horario)
**Docente:** Dr. José Luis Medina Jiménez

## 1. Negocio elegido

Tienda de **accesorios para videojuegos** (controles, audífonos, memorias). Productos de prueba incluidos en `inventario.dat`:

| Código | Nombre | Precio | Existencia |
|---|---|---|---|
| CTL-001 | Control inalambrico | $899.00 MXN | 15 |
| AUD-002 | Audifonos gamer | $649.50 MXN | 8 |
| MEM-003 | Memoria SD 128GB | $249.90 MXN | 30 |

## 2. Regla adicional del negocio: descuento por cantidad

- **Cuándo se aplica:** en una venta, si la cantidad es **5 o más unidades** (`DESC_MIN = 5`).
- **Qué hace:** descuenta el **10 %** (`DESC_PORC = 10`) del importe base.
- **Cálculo:** `descuento = (precio × cantidad × 10) / 100` con `DIV`. La división entera descarta la fracción de centavo. `importe final = base − descuento`.
- **Se aplica:** `CTL-001` × 5 → base $4495.00, descuento $449.50, final **$4045.50 MXN**.
- **No se aplica:** `CTL-001` × 4 → base y final **$3596.00 MXN**.
- **Fracción de centavo:** un producto de $12.05 × 5 → base $60.25, el 10 % es $6.025, se descarta el medio centavo, descuento $6.02, final **$54.23 MXN**.

## 3. Organización de los datos en memoria

Los productos se guardan en una **tabla de registros de tamaño fijo** (`inventario`, 10 × 42 = 420 bytes). Un tamaño fijo permite calcular la posición de un producto con una multiplicación y recorrer la tabla con ESI sumando 42 en cada vuelta.

| Posición dentro del registro | Campo | Tamaño |
|---|---|---|
| +0 | Código (7 caracteres + 0) | 8 bytes |
| +8 | Nombre (hasta 25 caracteres + 0) | 26 bytes |
| +34 | Precio en **centavos enteros** (DWORD) | 4 bytes |
| +38 | Existencia (DWORD) | 4 bytes |

Otras variables: `numProd` (cuántos hay), `ingresos` (centavos de la sesión), `cambios` (1 si hay cambios sin guardar), buffers (`bufEntrada`, `bufNum`, `bufImp`) y variables temporales (`tmpCod`, `tmpNom`, `tmpPre`, `tmpExi`).

**Por qué centavos enteros:** así todo el cálculo es con enteros (`MUL`, `DIV`, `ADD`) y no hay errores de redondeo. 185.50 pesos se guardan como 18550.

## 4. Formato del archivo `inventario.dat`

Archivo binario con una imagen de la tabla:

| Bytes | Contenido |
|---|---|
| 0 a 3 | Marca `INV1` (identifica que es un archivo de este programa) |
| 4 a 7 | Cantidad de productos (DWORD, de 0 a 10) |
| 8 en adelante | Los registros de 42 bytes, iguales a los de la tabla |

**Tamaño esperado:** 8 + (productos × 42) bytes. Con 3 productos son 134 bytes.

**Guardar:** se arma la imagen en `archBuf`, se crea el archivo (`CreateOutputFile`), se escribe todo de una vez (`WriteToFile`), se cierra (`CloseFile`) y se compara que los **bytes escritos sean iguales a los pedidos**.

**Cargar:** se lee el archivo a `archBuf` pidiendo **1 byte más** que el máximo esperado (para detectar archivos demasiado grandes), se cierra y se valida **todo antes de tocar el catálogo**:

1. El archivo existe (si no: mensaje de archivo ausente).
2. La lectura no falló.
3. Mide al menos 8 bytes y empieza con la marca `INV1`.
4. La cantidad de productos es de 0 a 10.
5. Los bytes leídos son exactamente 8 + productos × 42.
6. Cada registro es válido (código ABC-123, nombre de 1 a 25 caracteres imprimibles, precio de 1 a 999999, existencia de 0 a 100).
7. No hay códigos repetidos.

Solo si todo pasa, se limpia la tabla y se copian los registros. Si algo falla, el catálogo en memoria queda como estaba.

## 5. Decisiones de diseño

- **Capturar con `ReadString` y convertir a mano.** `ParseEntero` y `ParsePrecio` recorren la cadena con ESI y acumulan `acumulado × 10 + dígito`. `NumACadena` divide entre 10, guarda los residuos en la pila y los saca en orden, sumando `'0'`. No se usa `ReadDec`, `ReadInt`, `ParseDecimal32`, `WriteDec` ni `WriteHex`.
- **Errores con la bandera CF.** Los procedimientos de captura regresan CF=1 si rechazan el dato. Los desbordamientos se detectan con CF después de `MUL` y `ADD`.
- **Operaciones sin cambios a medias.** Alta y venta primero validan y calculan todo en variables temporales; solo al final escriben en la tabla.
- **Importes con dos decimales.** `MuestraImporte` divide los centavos entre 100: el cociente son los pesos y el residuo los centavos. Los centavos se separan en decena y unidad para mostrar el 5 como `05`.
- **Procedimientos documentados.** Cada uno indica entradas, salidas y registros modificados. Guardan con `PUSH` y regresan con `POP` los registros que no son su salida.
- **Evidencia de pila equilibrada.** `main` compara ESP con su valor inicial en cada vuelta del menú; la opción 9 comprueba además que los procedimientos conservan EBX, ECX, ESI y EDI.

## 6. Limitaciones conocidas

- No hay opción para borrar o editar un producto (no lo pide el proyecto).
- Si se carga un archivo con cambios sin guardar, la carga reemplaza el catálogo sin avisar.
- Los ingresos de la sesión no se guardan en el archivo (son de la sesión).
- Si se escribe una línea de más de 64 caracteres, `ReadString` solo toma los primeros 64.

## 7. Fuentes consultadas

> Verifica que realmente consultaste cada fuente y agrega la fecha de consulta. Quita las que no uses y agrega las que sí.

1. Irvine, K. R. *Assembly Language for x86 Processors* (7.ª ed.). Pearson. Capítulo 5, sección sobre la biblioteca de enlace (Irvine32): `ReadString`, `WriteString`, `CreateOutputFile`, `WriteToFile`, `CloseFile`. (Completa año y páginas según tu ejemplar.)
2. Ayuda de la biblioteca Irvine32 (lista de procedimientos): <https://csc.csudh.edu/mmccullough/asm/help/helpcontents.html>
3. Chuang, Y.-Y. (con diapositivas de K. Irvine). *Procedure* (apuntes de Computer Organization and Assembly Languages), sobre documentación de procedimientos y biblioteca Irvine32: <https://www.csie.ntu.edu.tw/~cyy/courses/assembly/06fall/lectures/handouts/lec08_procedure_4up.pdf>
4. Diapositivas del curso, *Unidad 2 – Lenguajes de Interfaz*.

**Pendiente de tu parte:** agrega la fuente que consultes sobre la regla del negocio (por ejemplo, qué es un descuento por volumen o por cantidad y por qué se usa). El proyecto pide que expliques qué investigaste y de dónde.


---

## Versión de la Unidad 3

En la Unidad 3 me pidieron dejar el mismo sistema de la Unidad 2 pero más ordenado y con menos código repetido. Cuando lo revisé vi tres cosas que se repetían muchísimo: los mensajes en pantalla, las revisiones de rangos y los `push`/`pop` para guardar registros. También había procedimientos largos que hacían varias cosas a la vez y costaba seguirlos. Lo arreglé con **macros**, **`USES`** y **procedimientos nuevos**.

El programa hace exactamente lo mismo que antes: las mismas opciones del menú, los mismos mensajes, las mismas validaciones, el mismo formato de archivo y la misma regla del descuento (10 % desde 5 unidades). Lo que cambió es cómo está escrito por dentro.

**Archivos:**
- Versión de la Unidad 2 (sin cambios): `unidad2/Proyecto_Ventas_Inventario_U2.asm`
- Versión de la Unidad 3: `unidad3/Proyecto_Ventas_Inventario_U3.asm`
- Inventario de prueba: `inventario.dat` (3 productos). Archivos dañados para pruebas: `pruebas/invalido_marca.dat` y `pruebas/invalido_duplicado.dat`.

En el código de la Unidad 3, antes de cada macro y de cada procedimiento puse una nota que empieza con **Cambio:** y dice qué cambié con respecto a la Unidad 2.

### 1. Tabla de antes y después

| Parte del programa | Problema detectado | Cambio | Beneficio |
|---|---|---|---|
| Mensajes en pantalla | Para mostrar un mensaje escribía 2 líneas (`mov edx, OFFSET texto` y `call WriteString`) y las repetí **63 veces**. | Hice el macro `Mostrar`, que recibe el nombre del texto. También hice `MostrarYRegresar`, `LineaImporte` y `LineaNumero` para cuando muestro un texto, un valor y un salto de línea. | Cada mensaje es una sola línea y se lee más rápido. Si quiero cambiar cómo se muestra un texto lo cambio en un solo lugar. |
| Revisión de rangos | Para ver si un valor estaba entre un mínimo y un máximo escribía 4 líneas (`cmp`, `jb`, `cmp`, `ja`) y las copié **10 veces** (códigos, dígitos, precios, existencias). | Hice el macro `FueraDeRango registro, mínimo, máximo, destino` y lo uso en 12 lugares. | Ya no se me olvida uno de los dos saltos y se ve de un vistazo cuál es el rango. |
| Guardar registros | Cada procedimiento tenía `push` al empezar y `pop` al terminar, y si tenía dos salidas repetía los `pop` en cada una. En total eran **144 líneas** de `push` y `pop`. | Puse `USES` en la línea del `PROC` en **38 de 40** procedimientos. Solo quedan 4 líneas `push`/`pop`: las de los dígitos en `NumACadena` y las de los centavos en `MuestraImporte`, porque son parte de cómo convierto el número. | MASM pone los `pop` en todas las salidas, así que no se me olvida ninguno y la pila queda equilibrada. |
| Menú principal (`main`) | En `main` tenía 10 pares `cmp`/`je` y 9 bloques `call`/`jmp`, y adentro estaba la pregunta de salir sin guardar. Eran **85 líneas de código**. | Hice el macro `OpcionMenu` (con `LOCAL`) y lo uso 9 veces. La pregunta de salir la pasé al procedimiento `PreguntaSiNo`. `main` quedó en **35 líneas**. | `main` se lee como una lista de las opciones del menú. |
| Comparar códigos | El ciclo que compara las 7 letras de dos códigos lo escribí dos veces: en `LocalizaProducto` y en `CodigoRepetidoAntes`. | Lo hice un procedimiento, `CmpCodigo`, y los dos lo llaman. `LocalizaProducto` pasó de 29 a 16 líneas y `CodigoRepetidoAntes` de 28 a 15. | Lo escribo y lo reviso una sola vez. |
| Pedir código y buscar | Pedir el código, buscarlo y avisar si no existe lo repetí en `BuscarProducto`, `RecibirMercancia` y `Vender`. | Hice `PideYBuscaProducto` y las tres opciones lo llaman. `BuscarProducto` pasó de 18 a 9 líneas y `RecibirMercancia` de 40 a 23. | Las tres opciones se portan igual y dan el mismo mensaje. |
| Captura de datos | Leer un texto, pasar su largo a `ECX`, apuntar `ESI` al buffer y convertirlo se repetía para la cantidad, el precio y la existencia. | Hice `LeeEntero`, `LeePrecio` y `PideNombre`. `PideCantidad` pasó de 26 a 13 líneas. | La captura queda corta y cada pieza hace una sola cosa. |
| Alta de producto | `AltaProducto` hacía todo junto: pedir, validar y guardar en la tabla (**85 líneas**). | Ahora usa `PideNombre`, `LeePrecio`, `LeeEntero` y `GuardaProductoNuevo`, y quedó en **36 líneas**. | Separé "capturar" de "guardar". Sigue sin guardar nada si algo sale mal. |
| Cálculo de importes | El `MUL` con el precio estaba en `Vender` y otra vez en `Resumen`, y la regla del descuento estaba metida en medio de `Vender` (**96 líneas**). | Hice `CalculaImporte` (la usan la venta y el resumen), `CalculaDescuento` (la regla del negocio) y `MuestraVenta`. `Vender` quedó en **40 líneas**. | Si cambia el descuento solo toco `CalculaDescuento` y las constantes `DESC_MIN` y `DESC_PORC`. |
| Resumen | `Resumen` recorría la tabla y además mostraba los resultados (**54 líneas**). | `CalculaTotales` suma y `Resumen` solo muestra. `Resumen` quedó en **13 líneas**. | El cálculo y la presentación quedan separados. |
| Archivos | `CargarArchivo` abría, leía, validaba y reemplazaba todo junto (**78 líneas**), y `GuardarArchivo` armaba el buffer ahí mismo (**44 líneas**). | Hice `ArmaImagenArchivo`, `ValidaArchivo` y `ReemplazaCatalogo`. Quedaron en **31** y **25 líneas**. | Cada paso tiene nombre y sigue validando todo el archivo antes de cambiar el catálogo. |
| Revisar la pila y los registros | La comparación de `ESP` estaba en `main` y otra vez en `PruebaRegistros`, y los 4 `cmp`/`jne` de los registros estaban escritos uno por uno. | Macro `ChequeaPila` con `LOCAL` (2 usos) y macro `CompruebaReg` (4 usos). `PruebaRegistros` pasó de 50 a 27 líneas. | Una sola definición para cada revisión. |
| Recorridos de la tabla | `mov esi, OFFSET inventario` y `mov ecx, numProd` al inicio de tres recorridos. | Macro `IniciaRecorrido` (3 usos). | El inicio de un recorrido tiene nombre. |

### 2. Fragmentos representativos

#### 2.1 Procedimiento reutilizado: `CmpCodigo`

Archivo: `unidad3/Proyecto_Ventas_Inventario_U3.asm`, líneas 713–727.

```asm
CmpCodigo PROC USES ebx
    mov ebx, 0                    ; EBX es la posicion de la letra
cc_letra:
    mov al, [esi + ebx]
    cmp al, [edi + ebx]
    jne cc_distinto
    inc ebx
    cmp ebx, 7
    jb  cc_letra
    mov eax, 1                    ; las 7 letras son iguales
    ret
cc_distinto:
    mov eax, 0
    ret
CmpCodigo ENDP
```

Compara el código al que apunta `ESI` con el código al que apunta `EDI` y regresa en `EAX` un 1 si son iguales o un 0 si no. Lo llaman dos procedimientos:

- `unidad3/Proyecto_Ventas_Inventario_U3.asm`, línea 741, dentro de `LocalizaProducto` (líneas 735–750). Ahí `EDI` trae el código que busco.
- `unidad3/Proyecto_Ventas_Inventario_U3.asm`, línea 1212, dentro de `CodigoRepetidoAntes` (líneas 1207–1221). Ahí `EDI` apunta a un producto anterior del archivo.

Antes, en `unidad2/Proyecto_Ventas_Inventario_U2.asm`, este mismo ciclo de 7 letras estaba escrito dos veces: en `LocalizaProducto` (líneas 644–656) y en `CodigoRepetidoAntes` (líneas 1167–1194). Así se veía el de `LocalizaProducto`:

```asm
lp_registro:
    mov ebx, 0
lp_caracter:
    mov al, [esi + ebx]
    cmp al, [edx + ebx]
    jne lp_siguiente
    inc ebx
    cmp ebx, 7
    jb  lp_caracter
    mov eax, 1
    pop ecx
    pop ebx
    ret
```

**Por qué lo hice procedimiento y no macro:** porque tiene un ciclo y una decisión y son como 12 líneas. Si fuera macro, MASM copiaría el ciclo completo en cada lugar donde lo use y tendría que ponerle `LOCAL` a sus etiquetas. Como procedimiento existe una sola vez, lo puedo revisar paso a paso con F11 en el depurador y tiene entradas (`ESI` y `EDI`) y una salida (`EAX`) claras.

#### 2.2 Macro con parámetros y sus puntos de uso: `FueraDeRango`

Archivo: `unidad3/Proyecto_Ventas_Inventario_U3.asm`, líneas 112–117.

```asm
FueraDeRango MACRO registro, minimo, maximo, destino
    cmp registro, minimo
    jb  destino
    cmp registro, maximo
    ja  destino
ENDM
```

Puntos de uso (`unidad3/Proyecto_Ventas_Inventario_U3.asm`):

| Línea | Procedimiento | Uso |
|---|---|---|
| 499 | `ValidaCodigo` | `FueraDeRango al, 'A', 'Z', vc_mal` |
| 508 | `ValidaCodigo` | `FueraDeRango al, '0', '9', vc_mal` |
| 532 | `ParseEntero` | `FueraDeRango bl, '0', '9', pe_mal` |
| 565 | `ParsePrecio` | `FueraDeRango bl, '0', '9', pp_mal` |
| 588 | `ParsePrecio` | `FueraDeRango ecx, 1, 2, pp_mal` |
| 593 | `ParsePrecio` | `FueraDeRango al, '0', '9', pp_mal` |
| 600 | `ParsePrecio` | `FueraDeRango bl, '0', '9', pp_mal` |
| 606 | `ParsePrecio` | `FueraDeRango eax, 1, MAX_PRECIO, pp_mal` |
| 692 | `PideNombre` | `FueraDeRango eax, 1, 25, pn_mal` |
| 837 | `AltaProducto` | `FueraDeRango eax, 0, MAX_STOCK, ap_exi_mal` |
| 1191 | `ValidaRegistro` | `FueraDeRango eax, 1, MAX_PRECIO, vr_mal` |
| 1193 | `ValidaRegistro` | `FueraDeRango eax, 0, MAX_STOCK, vr_mal` |

Antes, cada uno de estos puntos eran 4 líneas (`cmp`, `jb`, `cmp`, `ja`) en `unidad2/Proyecto_Ventas_Inventario_U2.asm`. Por ejemplo, en `ParseEntero` (líneas 451–454):

```asm
    cmp bl, '0'
    jb  pe_mal
    cmp bl, '9'
    ja  pe_mal
```

**Por qué lo hice macro y no procedimiento:** (1) salta a una etiqueta que cambia según dónde lo uso (`pe_mal`, `pp_mal`, `vc_mal`...) y un procedimiento no puede saltar a una etiqueta de quien lo llamó; (2) lo uso con registros distintos (`al`, `bl`, `eax`, `ecx`); y (3) son solo 4 instrucciones, con un procedimiento tendría que preparar parámetros y revisar el resultado y serían más líneas de las que ahorro.

#### 2.3 Macro con `LOCAL`: `OpcionMenu`

Archivo: `unidad3/Proyecto_Ventas_Inventario_U3.asm`, definición en las líneas 169–176 y usos en las líneas 295–303 (dentro de `main`).

```asm
OpcionMenu MACRO caracter, procedimiento
    LOCAL siguiente
    cmp al, caracter
    jne siguiente
    call procedimiento
    jmp inicio
siguiente:
ENDM
```

```asm
    OpcionMenu '1', AltaProducto
    OpcionMenu '2', MuestraInventario
    OpcionMenu '3', BuscarProducto
    OpcionMenu '4', RecibirMercancia
    OpcionMenu '5', Vender
    OpcionMenu '6', Resumen
    OpcionMenu '7', GuardarArchivo
    OpcionMenu '8', CargarArchivo
    OpcionMenu '9', PruebaRegistros
```

El macro tiene una etiqueta adentro (`siguiente`) y lo uso 9 veces. Sin `LOCAL`, las 9 copias tendrían la misma etiqueta y MASM marcaría error. Con `LOCAL`, MASM le pone un nombre distinto en cada uso. Lo mismo pasa con `ChequeaPila` (definición en las líneas 152–161 y usos en las líneas 289, 1366).

#### 2.4 Procedimiento que aplica `USES`: `ParseEntero`

Después, en `unidad3/Proyecto_Ventas_Inventario_U3.asm`, líneas 526–545:

```asm
ParseEntero PROC USES ebx edx esi ecx
    cmp ecx, 0
    je  pe_mal
    mov eax, 0
pe_ciclo:
    movzx ebx, BYTE PTR [esi]
    FueraDeRango bl, '0', '9', pe_mal
    sub ebx, '0'
    mul diez
    jc  pe_mal
    add eax, ebx
    jc  pe_mal
    inc esi
    loop pe_ciclo
    clc
    ret
pe_mal:
    stc
    ret
ParseEntero ENDP
```

Antes, en `unidad2/Proyecto_Ventas_Inventario_U2.asm`, líneas 441–475: tenía 4 `push` al inicio y los mismos 4 `pop` repetidos en **cada salida** (la normal y la de error), cada una con su `clc` o `stc`:

```asm
ParseEntero PROC
    push ebx
    push edx
    push esi
    push ecx
    cmp ecx, 0
    je  pe_mal
    mov eax, 0
pe_ciclo:
    movzx ebx, BYTE PTR [esi]
    cmp bl, '0'
    jb  pe_mal
    cmp bl, '9'
    ja  pe_mal
    sub ebx, '0'
    mul diez
    jc  pe_mal
    add eax, ebx
    jc  pe_mal
    inc esi
    loop pe_ciclo
    pop ecx
    pop esi
    pop edx
    pop ebx
    clc
    ret
pe_mal:
    pop ecx
    pop esi
    pop edx
    pop ebx
    stc
    ret
ParseEntero ENDP
```

**Qué entrega y qué conserva:** el resultado sale en `EAX` y en la bandera `CF` (0 = bien, 1 = error). Por eso `EAX` **no** está en `USES`. `EBX`, `EDX`, `ESI` y `ECX` sí están, porque el procedimiento los cambia y quien lo llama los necesita igual que antes. Los `pop` que pone `USES` no cambian las banderas, así que `CF` llega bien a quien lo llamó.

**Pila equilibrada:** `USES` pone el `pop` antes de cada `ret`, así que todas las salidas dejan la pila igual. La pila se revisa con `ChequeaPila` en cada vuelta del menú y con la opción 9 del programa.

### 3. Comparación de líneas de código fuente

**Cómo conté (igual en las dos versiones):** con un script. Una *línea de código* es cualquier línea que no está en blanco y que no es solo un comentario (instrucciones, directivas, datos y las líneas de las definiciones de macros). Si una línea tiene código y un comentario al final, cuenta como código.

| Medida | Unidad 2 | Unidad 3 | Diferencia |
|---|---|---|---|
| Líneas totales del archivo | 1342 | 1370 | +28 |
| Líneas en blanco | 63 | 76 | +13 |
| Líneas solo de comentario | 122 | 342 | +220 |
| **Líneas de código fuente** | **1157** | **952** | **−205 (17.7 %)** |
| De ellas, en la sección `.code` | 1055 | 795 | −260 (24.6 %) |
| Procedimientos | 26 | 40 | +14 |
| Macros | 0 | 9 | +9 |
| Líneas `push`/`pop` | 144 | 4 | −140 |

Las líneas de código bajaron 205 (−17.7 %), pero las líneas totales del archivo subieron de 1342 a 1370 porque **agregué muchos comentarios**: cada macro y cada procedimiento dice qué recibe, qué devuelve, qué registros cambia o conserva y qué cambié con respecto a la Unidad 2 (122 → 342 líneas de comentario). Las 952 líneas de código de la Unidad 3 ya incluyen las 52 líneas de las definiciones de las 9 macros y los 14 procedimientos nuevos.

**Nota sobre las macros:** una macro reduce la repetición en el archivo `.asm`, pero MASM copia sus instrucciones en cada lugar donde se usa, así que el programa ya compilado no se hace más corto. Lo que mejora es que el código es más fácil de leer y de cambiar. Las macros se copiaron 114 veces en total.

**Bloques que dejaron de repetirse:**

1. El par `mov edx, OFFSET …` / `call WriteString` (63 veces) → macro `Mostrar`.
2. El bloque `cmp`/`jb`/`cmp`/`ja` (10 veces) → macro `FueraDeRango`.
3. Los grupos de `push`/`pop` de cada procedimiento y de cada salida → `USES`.
4. El ciclo de comparar 7 letras (2 copias) → `CmpCodigo`.
5. "Pedir código, buscar y avisar si no existe" (3 copias) → `PideYBuscaProducto`.
6. "Leer texto y convertirlo a número" (3 copias) → `LeeEntero` y `LeePrecio`.
7. El `MUL` del precio (2 copias) → `CalculaImporte`.
8. La revisión de `ESP` (2 copias) → macro `ChequeaPila`.
9. Los 19 bloques de opciones del menú (10 de `cmp`/`je` y 9 de `call`/`jmp`) → macro `OpcionMenu`.

### 4. Tabla de pruebas actualizada

Son las mismas pruebas de la versión anterior (el programa tiene que hacer lo mismo) más una sección G para comparar las dos versiones. Debo llenar la columna "Resultado obtenido" al ejecutar el programa. Está también aparte en `docs/Tabla_de_pruebas_U3.md`.

**Qué se prueba:** la versión de la Unidad 3 (`unidad3/Proyecto_Ventas_Inventario_U3.asm`) debe comportarse igual que la de la Unidad 2: mismas funciones, mismos mensajes, mismas validaciones y misma regla del negocio. Se vuelven a probar el registro y la búsqueda (A), las entradas de mercancía (B), las ventas aceptadas y rechazadas y la regla del negocio (C), el resumen (D), el guardado y la carga (E) y la pila y los registros (F). La sección G compara las dos versiones.

**Cómo usarla:** ejecuta el programa, cada prueba con el catálogo recién cargado (opción 8 con `inventario.dat`) salvo que se indique otra cosa, y llena la columna **Resultado obtenido** con lo que realmente pasó (puedes escribir "OK" si coincide, o describir la diferencia).

Catálogo base: CTL-001 (15 uds, $899.00), AUD-002 (8 uds, $649.50), MEM-003 (30 uds, $249.90).

#### A. Registro y consulta

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

#### B. Recibir mercancía

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| B1 | Entrada válida hasta el límite | `MEM-003`, `70` | "Mercancia recibida. Nueva existencia: 100" | |
| B2 | Entrada que excede 100 | `MEM-003`, `71` | "No se puede: la existencia pasaria de 100 unidades"; en la opción 2 sigue en 30 | |
| B3 | Cantidad inválida | `0`, `-3`, `2.5`, `abc`, Enter | "Cantidad invalida..." en todos los casos | |
| B4 | Producto inexistente | `AUD-999`, `5` | "No existe un producto con ese codigo" | |

#### C. Ventas y regla del negocio

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| C1 | Venta sin descuento (4 uds) | `CTL-001`, `4` | Base `$3596.00 MXN`; "Sin descuento..."; final `$3596.00 MXN`; restante 11 | |
| C2 | Venta con descuento (5 uds) | `CTL-001`, `5` | Base `$4495.00 MXN`; descuento `$449.50 MXN`; final `$4045.50 MXN`; restante 10 | |
| C3 | Vender toda la existencia | `AUD-002`, `8` | Base `$5196.00 MXN`; descuento `$519.60 MXN`; final `$4676.40 MXN`; restante 0 | |
| C4 | Venta sin existencias suficientes | `AUD-002`, `9` | "Existencias insuficientes... Existencia actual: 8"; ingresos y existencia no cambian | |
| C5 | Descuento sin fracción de centavo | Producto de `$12.05` (A3), vender `5` | Base `$60.25 MXN`; descuento `$6.02 MXN`; final `$54.23 MXN` | |
| C6 | Cantidad inválida | `0`, `abc` | "Cantidad invalida..." | |
| C7 | Producto inexistente | `AUD-999`, `1` | "No existe un producto con ese codigo" | |

#### D. Resumen

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| D1 | Resumen con el catálogo recién cargado | Opción 6 | Unidades 53; valor `$26178.00 MXN`; ingresos `$0.00 MXN` | |
| D2 | Resumen tras la venta C2 (solo esa) | Opción 6 | Unidades 48; valor `$21683.00 MXN`; ingresos `$4045.50 MXN` | |
| D3 | Resumen sin productos | Ejecutar y opción 6 sin cargar | Unidades 0; valor `$0.00 MXN`; ingresos `$0.00 MXN` | |

#### E. Archivo

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

#### F. Pila y registros

| # | Prueba | Entrada | Resultado esperado | Resultado obtenido |
|---|---|---|---|---|
| F1 | Conservación de registros y pila | Opción 9 | Muestra `$185.50 MXN`, `77`, y los mensajes "...se conservaron. OK" y "...la pila esta equilibrada... OK" | |
| F2 | Pila en el menú | Usar varias opciones seguidas | Nunca aparece "ERROR: la pila no quedo equilibrada" | |

#### G. Regresión: la Unidad 3 debe dar lo mismo que la Unidad 2

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

### 5. Por qué escogí macro o procedimiento

| Cambio | Lo que escogí | Por qué |
|---|---|---|
| `Mostrar`, `MostrarYRegresar`, `LineaImporte`, `LineaNumero` | Macro con parámetros | Son secuencias cortas (2 a 6 instrucciones) que solo cambian el texto o el valor. Con un procedimiento tendría que preparar el parámetro en un registro de todas formas y no ahorraría líneas. |
| `FueraDeRango`, `CompruebaReg` | Macro con parámetros | Saltan a una etiqueta que cambia según dónde las uso y trabajan con registros distintos. Un procedimiento no puede saltar a una etiqueta de quien lo llamó. |
| `ChequeaPila`, `OpcionMenu` | Macro con `LOCAL` | Tienen una etiqueta adentro y las uso varias veces (2 y 9). Sin `LOCAL` la etiqueta se repetiría. |
| `IniciaRecorrido` | Macro sin parámetros | Son 2 instrucciones fijas que van al inicio de 3 recorridos. |
| `CmpCodigo`, `PideYBuscaProducto`, `LeeEntero`, `LeePrecio`, `PideNombre` | Procedimiento | Tienen ciclos, decisiones y llamadas a otros procedimientos, y con entradas y salidas claras. Existen una sola vez y los puedo revisar paso a paso en el depurador. |
| `CalculaImporte`, `CalculaDescuento`, `CalculaTotales`, `MuestraVenta` | Procedimiento | Separan el cálculo de lo que se muestra y dejan la regla del negocio en un solo lugar. |
| `ArmaImagenArchivo`, `ValidaArchivo`, `ReemplazaCatalogo`, `GuardaProductoNuevo`, `PreguntaSiNo` | Procedimiento | Les di nombre a pasos que antes estaban dentro de procedimientos largos. |

**Qué registros puse en `USES` y cuáles no:** `EAX` queda fuera cuando el procedimiento regresa un resultado en él (`ValidaCodigo`, `PideCodigo`, `LocalizaProducto`, `CmpCodigo`, `ParseEntero`...). `ESI` queda fuera en `LocalizaProducto`, `PideYBuscaProducto` y `AgregaTexto` porque también es una salida. Las banderas `CF` que regresan `ParseEntero`, `ParsePrecio`, `PideCantidad`, `LeeEntero`, `LeePrecio`, `CalculaImporte`, `CalculaDescuento` y `CalculaTotales` llegan bien, porque los `pop` de `USES` no cambian las banderas.
