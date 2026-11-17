; Materia: Lenguajes de Interfaz
; Alumno: Giovanni De Jesus Echevarria Yañez 
; Horario: 10-11 
; Docente: Dr. José Luis Medina Jiménez
; Proyecto: Sistema de ventas e inventario en ensamblador. Version de la Unidad 3
; Descripcion: Es el mismo sistema de la Unidad 2, con las mismas funciones, las mismas
; validaciones y la misma regla extra (descuento del 10 por ciento si se llevan 5 o mas unidades),
; pero mas facil de leer y con menos codigo repetido.
;
; Que cambie en la Unidad 3 (explicado simple):
;
; Me pidieron dejar el mismo programa pero mas ordenado. Cuando lo revise me di cuenta de que en la
; Unidad 2 repeti muchas veces las mismas lineas, y de que algunos procedimientos hacian varias
; cosas a la vez y costaba seguirlos. Lo arregle de tres formas:
;
; 1 MACROS (son 9). Una macro es como un atajo: la escribo una vez y MASM la copia donde la uso.
;   - Mostrar: antes cada mensaje eran 2 lineas (mov edx, OFFSET ... y call WriteString) y las tenia
;     escritas 63 veces. Ahora es una sola linea.
;   - FueraDeRango: para ver si un valor esta entre un minimo y un maximo escribia 4 lineas (cmp, jb,
;     cmp, ja) y lo copie 10 veces. Ahora es una linea y la uso en 12 lugares.
;   - LineaImporte y LineaNumero: mostraban un texto, un valor y un salto de linea (5 o 6 lineas cada
;     vez). Ahora es una linea.
;   - MostrarYRegresar: muestra un mensaje y sale del procedimiento.
;   - IniciaRecorrido: deja ESI en el primer producto y ECX con cuantos hay. Lo uso en 3 recorridos.
;   - CompruebaReg: revisa que un registro no haya cambiado. Lo uso en la opcion 9.
;   - ChequeaPila y OpcionMenu: estas dos llevan LOCAL porque tienen una etiqueta adentro y las uso
;     varias veces. Si no pongo LOCAL la misma etiqueta se repite y MASM marca error.
;
; 2 USES. Antes cada procedimiento guardaba sus registros con push al empezar y los regresaba con pop
;   al final, y si tenia dos salidas tenia que repetir los pop en cada una. Eran 144 lineas de push y
;   pop. Ahora pongo USES en la linea del PROC y MASM pone los push y los pop solo, en todas las
;   salidas. Los registros que regresan un resultado (como EAX) no los pongo en USES, porque si no
;   el resultado se perderia al regresar.
;
; 3 PROCEDIMIENTOS NUEVOS (son 14). Saque lo que se repetia o lo que hacia dificil seguir el programa:
;   - CmpCodigo: comparar dos codigos estaba escrito dos veces (al buscar y al revisar el archivo).
;   - PideYBuscaProducto: pedir el codigo y buscarlo estaba repetido en buscar, recibir y vender.
;   - LeeEntero, LeePrecio y PideNombre: leer un texto y convertirlo se repetia en varias capturas.
;   - GuardaProductoNuevo: lo que escribe el producto en la tabla (estaba dentro de AltaProducto).
;   - CalculaImporte y CalculaDescuento: el precio por cantidad y la regla del descuento estaban
;     revueltos dentro de Vender.
;   - MuestraVenta y CalculaTotales: separe mostrar de calcular en la venta y en el resumen.
;   - ArmaImagenArchivo, ValidaArchivo y ReemplazaCatalogo: partes de guardar y cargar que estaban
;     todas juntas en GuardarArchivo y CargarArchivo.
;   - PreguntaSiNo: la pregunta de salir sin guardar, que estaba dentro de main.
;
; Lo que NO cambie: el programa hace lo mismo que en la Unidad 2 (mismas opciones, mismos mensajes,
; mismas validaciones, mismo formato del archivo y misma regla del descuento). Los precios siguen en
; centavos, los productos siguen siendo registros de 42 bytes y los sigo recorriendo con ESI.
;
; En los comentarios, donde dice Cambio o Antes explico que fue lo que cambie con respecto a la
; Unidad 2. Cuando hablo de lineas cuento solo lineas de codigo, sin comentarios ni espacios.

INCLUDE Irvine32.inc

; constantes
MAX_PROD   = 10                     ; maximo de productos
REG_SIZE   = 42                     ; bytes que mide cada registro
OFF_COD    = 0                      ; donde empieza el codigo dentro del registro
OFF_NOM    = 8                      ; donde empieza el nombre
OFF_PRE    = 34                     ; donde esta el precio
OFF_EXI    = 38                     ; donde esta la existencia
BUFMAX     = 64                     ; maximo de caracteres que leo con ReadString
MAX_STOCK  = 100                    ; existencia maxima por producto
MAX_PRECIO = 999999                 ; 9999.99 pesos en centavos
DESC_MIN   = 5                      ; unidades minimas para el descuento
DESC_PORC  = 10                     ; porcentaje de descuento
ARCH_MAX   = 8 + MAX_PROD * REG_SIZE  ; tamano maximo del archivo
MAGICO     = 31564E49h              ; 'I','N','V','1' en little endian, sirve para reconocer mi archivo

; MACROS
; Una macro se escribe una vez y MASM copia sus instrucciones en cada lugar donde se usa.
; Con parametros sirve cuando la secuencia es casi igual y solo cambia un dato.

; Mostrar: imprime un texto. Antes eran 2 lineas repetidas en cada mensaje.
; Parametro: el nombre del texto. Modifica: EDX.
; La ia me ayudo hacer esto
; Cambio: antes cada mensaje eran 2 lineas y estaban repetidas 63 veces. Ahora es una linea.
Mostrar MACRO texto
    mov edx, OFFSET texto
    call WriteString
ENDM

; LineaImporte: imprime una etiqueta, un importe en MXN y un salto de linea.
; Parametros: la etiqueta y el valor en centavos (variable o registro). Modifica: EAX y EDX.
; La ia me ayudo hacer esto
; Cambio: antes eran 6 lineas cada vez que mostraba un texto con un importe. Ahora es una.
LineaImporte MACRO etiqueta, valor
    Mostrar etiqueta
    mov eax, valor
    call MuestraImporte
    Mostrar txtCrlf
ENDM

; LineaNumero: imprime una etiqueta, un numero entero y un salto de linea.
; Parametros: la etiqueta y el valor (variable, registro o entre <> una direccion como <[esi + 38]>).
; Modifica: EAX y EDX.
; La ia me ayudo hacer esto
; Cambio: igual que LineaImporte pero para numeros enteros (existencia, unidades, bytes).
LineaNumero MACRO etiqueta, valor
    Mostrar etiqueta
    mov eax, valor
    call MuestraNumero
    Mostrar txtCrlf
ENDM

; FueraDeRango: salta a un destino si un valor no esta entre el minimo y el maximo (sin signo).
; Parametros: registro, minimo, maximo y la etiqueta a la que salta. No cambia registros.
; Reemplaza las 4 lineas cmp, jb, cmp, ja que estaban repetidas en las validaciones.
; La ia me ayudo hacer esto
; Cambio: antes eran 4 lineas (cmp, jb, cmp, ja) repetidas 10 veces. Ahora es una linea y la uso 12 veces.
FueraDeRango MACRO registro, minimo, maximo, destino
    cmp registro, minimo
    jb  destino
    cmp registro, maximo
    ja  destino
ENDM

; MostrarYRegresar: imprime un mensaje y sale del procedimiento.
; Parametro: el texto. Modifica: EDX. Con USES el RET tambien regresa los registros guardados.
; La ia me ayudo hacer esto
; Cambio: antes eran 3 lineas: mov edx, call WriteString y ret.
MostrarYRegresar MACRO mensaje
    Mostrar mensaje
    ret
ENDM

; IniciaRecorrido: deja ESI en el primer producto y ECX con cuantos productos hay.
; Se usa al principio de cada recorrido de la tabla. Modifica: ESI y ECX.
; La ia me ayudo hacer esto
; Cambio: antes estas 2 lineas estaban escritas en LocalizaProducto, MuestraInventario y Resumen.
IniciaRecorrido MACRO
    mov esi, OFFSET inventario
    mov ecx, numProd
ENDM

; CompruebaReg: salta a un destino si un registro cambio de valor.
; Parametros: el registro, su valor original y la etiqueta. No cambia registros.
; La ia me ayudo hacer esto
; Cambio: antes eran 2 lineas (cmp y jne) escritas 4 veces en PruebaRegistros.
CompruebaReg MACRO registro, valor, destino
    cmp registro, valor
    jne destino
ENDM

; ChequeaPila: compara ESP con el valor que guarde antes. Si es igual muestra msgBien y si no msgMal.
; Parametros: la variable donde guarde ESP y los dos textos. Modifica: EDX.
; Lleva LOCAL porque tiene etiquetas adentro y se usa en main y en PruebaRegistros.
; Sin LOCAL, al usarla dos veces las etiquetas se repetirian y MASM marcaria error.
; La ia me ayudo hacer esto
; Cambio: antes esta revision de ESP estaba escrita en main y otra vez en PruebaRegistros.
ChequeaPila MACRO variable, msgBien, msgMal
    LOCAL esIgual, termina
    cmp esp, variable
    je  esIgual
    Mostrar msgMal
    jmp termina
esIgual:
    Mostrar msgBien
termina:
ENDM

; OpcionMenu: si la opcion que escribio el usuario (en AL) es este caracter, llama al
; procedimiento y regresa al menu. Si no, sigue con la siguiente opcion.
; Parametros: el caracter y el nombre del procedimiento. Lleva LOCAL por la etiqueta de adentro,
; se usa 9 veces en main. Usa el nombre inicio, que es la etiqueta del menu en main.
; La ia me ayudo hacer esto
; Cambio: antes en main eran 10 pares de cmp con je y 9 bloques de call con jmp, mas de 40 lineas.
OpcionMenu MACRO caracter, procedimiento
    LOCAL siguiente
    cmp al, caracter
    jne siguiente
    call procedimiento
    jmp inicio
siguiente:
ENDM

.data
; datos del programa
inventario  BYTE MAX_PROD * REG_SIZE DUP(0)  ; la tabla de productos
numProd     DWORD 0                 ; cuantos productos hay registrados
ingresos    DWORD 0                 ; ingresos de la sesion, en centavos
cambios     DWORD 0                 ; 1 = hay cambios sin guardar, 0 = todo guardado
diez        DWORD 10                ; MUL necesita el 10 en un registro o variable
espInicial  DWORD ?                 ; guardo ESP al empezar para comprobar que la pila se equilibra
espPrueba   DWORD ?                 ; ESP al entrar a PruebaRegistros

; buffers de trabajo
bufEntrada  BYTE BUFMAX + 1 DUP(0)  ; aqui cae todo lo que escribe el usuario
bufNum      BYTE 16 DUP(0)          ; cadena de un numero
bufImp      BYTE 32 DUP(0)          ; cadena de un importe, ej: $185.50 MXN
tmpCod      BYTE 8 DUP(0)           ; codigo capturado ya validado
tmpNom      BYTE 26 DUP(0)          ; nombre capturado
tmpPre      DWORD ?                 ; precio capturado
tmpExi      DWORD ?                 ; existencia capturada
cantidad    DWORD ?                 ; cantidad de la venta
ptrProd     DWORD ?                 ; direccion del producto encontrado
baseImp     DWORD ?                 ; importe base de la venta
descImp     DWORD ?                 ; descuento de la venta
finalImp    DWORD ?                 ; importe final de la venta
totUnid     DWORD ?                 ; unidades del resumen
totValor    DWORD ?                 ; valor del inventario en el resumen

; archivo
nomArchivo  BYTE "inventario.dat",0
archBuf     BYTE ARCH_MAX + 2 DUP(0)  ; imagen del archivo
manejador   DWORD ?                 ; handle del archivo
totalBytes  DWORD ?                 ; bytes que quiero escribir
escritos    DWORD ?                 ; bytes que realmente se escribieron
leidos      DWORD ?                 ; bytes que realmente se leyeron
cargaN      DWORD ?                 ; cuantos productos dice el archivo que trae

; textos sin acentos para que la consola no los muestre raros
txtBienv    BYTE 0dh,0ah,"=== TIENDA DE ACCESORIOS PARA VIDEOJUEGOS ===",0dh,0ah
            BYTE "Sistema de ventas e inventario (MASM x86 / Irvine32)",0dh,0ah,0
; el menu va en varias lineas BYTE porque MASM no deja lineas muy largas
txtMenu     BYTE 0dh,0ah,"----------- MENU -----------",0dh,0ah
            BYTE "1. Registrar producto",0dh,0ah
            BYTE "2. Mostrar inventario",0dh,0ah
            BYTE "3. Buscar por codigo",0dh,0ah
            BYTE "4. Recibir mercancia",0dh,0ah
            BYTE "5. Vender",0dh,0ah
            BYTE "6. Resumen",0dh,0ah
            BYTE "7. Guardar catalogo en archivo",0dh,0ah
            BYTE "8. Cargar catalogo desde archivo",0dh,0ah
            BYTE "9. Prueba de registros y pila",0dh,0ah
            BYTE "0. Salir",0dh,0ah
            BYTE "Opcion: ",0
txtCrlf     BYTE 0dh,0ah,0
txtVacio     BYTE 0                  ; texto vacio, no imprime nada
txtSep      BYTE "  |  ",0
txtSepExi   BYTE "  |  Existencia: ",0
txtMXN      BYTE " MXN",0
txtEncInv   BYTE 0dh,0ah,"CODIGO   |  NOMBRE  |  PRECIO  |  EXISTENCIA",0dh,0ah,0
txtPideCod  BYTE "Codigo (formato ABC-123): ",0
txtPideNom  BYTE "Nombre (1 a 25 caracteres): ",0
txtPidePre  BYTE "Precio en pesos (ej. 185.50 o 185): ",0
txtPideExi  BYTE "Existencia inicial (0 a 100): ",0
txtPideCant BYTE "Cantidad (entero mayor que 0): ",0
txtSalirSin BYTE "Hay cambios sin guardar. Salir de todos modos? (S/N): ",0

msgOpMala   BYTE "Opcion no valida, intenta otra vez",0dh,0ah,0
msgPilaMal  BYTE "ERROR: la pila no quedo equilibrada",0dh,0ah,0
msgLleno    BYTE "No se puede registrar: ya hay 10 productos (capacidad llena)",0dh,0ah,0
msgCodMal   BYTE "Codigo incorrecto: deben ser 3 letras mayusculas, un guion y 3 digitos",0dh,0ah,0
msgDup      BYTE "Ese codigo ya existe, no se registro el producto",0dh,0ah,0
msgNomMal   BYTE "Nombre invalido: debe tener de 1 a 25 caracteres",0dh,0ah,0
msgPreMal   BYTE "Precio invalido: de 0.01 a 9999.99, solo digitos y un punto con 1 o 2 decimales",0dh,0ah,0
msgExiMal   BYTE "Existencia invalida: debe ser un entero de 0 a 100",0dh,0ah,0
msgCantMal  BYTE "Cantidad invalida: debe ser un entero mayor que 0 (solo digitos)",0dh,0ah,0
msgNoExiste BYTE "No existe un producto con ese codigo",0dh,0ah,0
msgAlta     BYTE "Producto registrado correctamente",0dh,0ah,0
msgInvVacio BYTE "El inventario esta vacio",0dh,0ah,0
msgExcede   BYTE "No se puede: la existencia pasaria de 100 unidades. No se cambio nada",0dh,0ah,0
msgDesb     BYTE "Desbordamiento en el calculo, operacion rechazada. No se cambio nada",0dh,0ah,0
msgRecibida BYTE "Mercancia recibida. Nueva existencia: ",0
msgSinExist BYTE "Existencias insuficientes, venta rechazada. Existencia actual: ",0
msgVentaOk  BYTE 0dh,0ah,"VENTA ACEPTADA",0dh,0ah,0
txtBase     BYTE "Importe base:      ",0
txtDesc     BYTE "Descuento 10% (5 o mas unidades): -",0
txtSinDesc  BYTE "Sin descuento (se aplica desde 5 unidades)",0dh,0ah,0
txtFinal    BYTE "Importe final:     ",0
txtRestan   BYTE "Existencia restante: ",0
txtResUni   BYTE 0dh,0ah,"Unidades disponibles:        ",0
txtResVal   BYTE "Valor total del inventario: ",0
txtResIng   BYTE "Ingresos de la sesion:      ",0
msgGuardado BYTE "Catalogo guardado en inventario.dat. Bytes escritos: ",0
msgErrCrear BYTE "No se pudo crear el archivo inventario.dat",0dh,0ah,0
msgErrEscr  BYTE "Error: no se escribieron todos los bytes del archivo",0dh,0ah,0
msgNoArch   BYTE "No se encontro el archivo inventario.dat (no se cambio el catalogo)",0dh,0ah,0
msgErrLect  BYTE "Error al leer el archivo (no se cambio el catalogo)",0dh,0ah,0
msgArchMal  BYTE "El archivo es invalido o esta danado (no se cambio el catalogo)",0dh,0ah,0
msgCargado  BYTE "Catalogo cargado. Productos recuperados: ",0
msgRegOk    BYTE "Prueba: los registros EBX, ECX, ESI y EDI se conservaron. OK",0dh,0ah,0
msgRegMal   BYTE "Prueba: ALGUN registro cambio. FALLO",0dh,0ah,0
msgPilaOk   BYTE "Prueba: la pila esta equilibrada (ESP igual que al inicio). OK",0dh,0ah,0
codPrueba   BYTE "ABC-123",0

.code
; main: muestra el menu una y otra vez y llama al procedimiento de cada opcion.
; Las opciones 1 a 9 ahora las hace el macro OpcionMenu, antes eran 36 lineas.
; Cambio: antes tenia 85 lineas con las opciones escritas una por una. Ahora uso el macro OpcionMenu y la pregunta de
; salir la pase a PreguntaSiNo. Quedo en 35 lineas y hace lo mismo.
main PROC
    mov espInicial, esp           ; guardo ESP para ver que la pila no se descuadre
    Mostrar txtBienv

inicio:
    ChequeaPila espInicial, txtVacio, msgPilaMal  ; si ESP cambio avisa, si esta bien no dice nada
    mov edx, OFFSET txtMenu
    call LeeTexto                 ; muestra el menu y lee la opcion, EAX trae cuantas letras escribio
    cmp eax, 1
    jne op_mala                   ; la opcion es de un solo caracter
    mov al, bufEntrada            ; AL trae la opcion
    OpcionMenu '1', AltaProducto
    OpcionMenu '2', MuestraInventario
    OpcionMenu '3', BuscarProducto
    OpcionMenu '4', RecibirMercancia
    OpcionMenu '5', Vender
    OpcionMenu '6', Resumen
    OpcionMenu '7', GuardarArchivo
    OpcionMenu '8', CargarArchivo
    OpcionMenu '9', PruebaRegistros
    cmp al, '0'
    je  op0

op_mala:
    Mostrar msgOpMala
    jmp inicio

op0:                              ; salir, aviso si hay cambios sin guardar
    cmp cambios, 0
    je  salir
    mov edx, OFFSET txtSalirSin
    call PreguntaSiNo             ; EAX en 1 si contesto S o s
    cmp eax, 1
    je  salir
    jmp inicio

salir:
    exit
main ENDP

; LeeTexto: muestra un mensaje y lee lo que escriba el usuario.
; Entra: EDX con el mensaje. Sale: EAX con cuantas letras escribio, el texto queda en bufEntrada.
; Conserva: ECX y EDX (USES). Modifica: solo EAX.
; Cambio: ahora usa USES en vez de push y pop. Tambien lo uso en main para mostrar el menu y leer la opcion.
LeeTexto PROC USES ecx edx
    call WriteString              ; imprimo el mensaje
    mov edx, OFFSET bufEntrada    ; EDX es donde se guarda lo que escriba
    mov ecx, BUFMAX               ; ECX es el maximo de letras
    call ReadString               ; EAX queda con cuantas letras escribio
    ret
LeeTexto ENDP

; PreguntaSiNo: hace una pregunta y dice si contesto S o s.
; Antes este codigo estaba dentro de main. Ahora main solo llama al procedimiento.
; Entra: EDX con la pregunta. Sale: EAX en 1 si contesto S o s, en 0 con cualquier otra cosa.
; Conserva: todos menos EAX (LeeTexto conserva ECX y EDX). Modifica: solo EAX.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo, esta pregunta estaba dentro de main.
PreguntaSiNo PROC
    call LeeTexto
    cmp eax, 1
    jne ps_no                     ; si no escribio una sola letra es un no
    mov al, bufEntrada
    cmp al, 'S'
    je  ps_si
    cmp al, 's'
    je  ps_si
ps_no:
    mov eax, 0
    ret
ps_si:
    mov eax, 1
    ret
PreguntaSiNo ENDP

; CopiaBytes: copia ECX bytes de un lugar a otro.
; Entra: ESI origen, EDI destino, ECX cuantos bytes. Sale: nada.
; Conserva: EAX, ECX, ESI y EDI (USES). Modifica: nada.
; La ia me ayudo hacer esto
; Cambio: ahora usa USES en vez de 4 push y 4 pop a mano.
CopiaBytes PROC USES eax ecx esi edi
    cmp ecx, 0
    je  cb_fin                    ; si no hay nada que copiar me salgo
cb_ciclo:
    mov al, [esi]                 ; agarro un byte del origen
    mov [edi], al                 ; lo pongo en el destino
    inc esi
    inc edi
    loop cb_ciclo
cb_fin:
    ret
CopiaBytes ENDP

; LlenaCero: pone ECX bytes en 0 desde la direccion que traiga EDI.
; Entra: EDI y ECX. Sale: nada. Conserva: ECX y EDI (USES). Modifica: nada.
; La ia me ayudo hacer esto
; Cambio: ahora usa USES en vez de 2 push y 2 pop a mano.
LlenaCero PROC USES ecx edi
    cmp ecx, 0
    je  lz_fin
lz_ciclo:
    mov BYTE PTR [edi], 0
    inc edi
    loop lz_ciclo
lz_fin:
    ret
LlenaCero ENDP

; AgregaTexto: pega un texto al final de lo que voy escribiendo.
; Entra: EDI con el texto y ESI con donde escribir. Sale: ESI queda en el 0 final.
; Conserva: EAX y EDI (USES). Modifica: solo ESI, que es la salida.
; La ia me ayudo hacer esto
; Cambio: ahora usa USES en vez de 2 push y 2 pop a mano.
AgregaTexto PROC USES eax edi
at_ciclo:
    mov al, [edi]
    cmp al, 0
    je  at_fin                    ; llegue al 0 y ya acabe
    mov [esi], al
    inc esi
    inc edi
    jmp at_ciclo
at_fin:
    mov BYTE PTR [esi], 0
    ret
AgregaTexto ENDP

; NumACadena: convierte un numero a texto.
; Divido entre 10 y el residuo es un digito. Los meto a la pila y al sacarlos quedan en orden.
; A cada digito le sumo el codigo de 0 para volverlo letra.
; Entra: EAX con el numero y ESI con donde escribir.
; Sale: el texto con su 0 final y ESI queda en ese 0.
; Conserva: EAX, EBX, ECX y EDX (USES). Modifica: solo ESI, que es la salida.
; Los push y pop de los digitos siguen a mano porque son parte del metodo, no solo guardar registros.
; Cambio: ahora usa USES para guardar EAX, EBX, ECX y EDX. Los push y pop de los digitos siguen a mano.
NumACadena PROC USES eax ebx ecx edx
    mov ebx, 10                   ; divido entre 10
    mov ecx, 0                    ; cuento los digitos
nc_div:
    mov edx, 0                    ; limpio EDX antes de dividir
    div ebx                       ; EAX queda el cociente y EDX el residuo, que es un digito
    push edx                      ; meto el digito a la pila
    inc ecx
    cmp eax, 0
    jne nc_div                    ; sigo hasta que el cociente sea 0
nc_sacar:
    pop edx                       ; saco los digitos y ya salen en orden
    add dl, '0'                   ; le sumo el codigo de 0 para volverlo letra
    mov [esi], dl
    inc esi
    loop nc_sacar
    mov BYTE PTR [esi], 0         ; pongo el 0 del final
    ret
NumACadena ENDP

; MuestraNumero: muestra un numero en pantalla con WriteString.
; Entra: EAX con el numero. Sale: nada. Conserva: EDX y ESI (USES; NumACadena conserva el resto).
; Modifica: nada.
; La ia me ayudo hacer esto
; Cambio: ahora usa USES y el macro Mostrar para imprimir.
MuestraNumero PROC USES edx esi
    mov esi, OFFSET bufNum
    call NumACadena
    Mostrar bufNum
    ret
MuestraNumero ENDP

; MuestraImporte: muestra un importe en pesos con dos decimales y MXN.
; Divido los centavos entre 100: el cociente son los pesos y el residuo los centavos.
; Los centavos los separo en decena y unidad, asi el 5 sale como 05.
; Entra: EAX con los centavos. Sale: el texto en pantalla, por ejemplo $185.50 MXN.
; Conserva: EAX, EBX, EDX, ESI y EDI (USES). Modifica: nada.
; El push y pop de los centavos sigue a mano porque guardo un dato, no un registro del que llamo.
; Cambio: ahora usa USES (antes 5 push y 5 pop) y el macro Mostrar. El push y pop de los centavos sigue igual.
MuestraImporte PROC USES eax ebx edx esi edi
    mov edx, 0
    mov ebx, 100
    div ebx                       ; EAX queda con los pesos y EDX con los centavos
    push edx                      ; guardo los centavos en la pila
    mov esi, OFFSET bufImp
    mov BYTE PTR [esi], '$'
    inc esi
    call NumACadena               ; convierto los pesos a texto
    pop eax                       ; saco los centavos
    mov BYTE PTR [esi], '.'
    inc esi
    mov edx, 0
    mov ebx, 10
    div ebx                       ; EAX queda con la decena y EDX con la unidad, asi el 5 sale como 05
    add al, '0'
    mov [esi], al
    inc esi
    add dl, '0'
    mov [esi], dl
    inc esi
    mov BYTE PTR [esi], 0
    mov edi, OFFSET txtMXN
    call AgregaTexto              ; le pongo MXN al final
    Mostrar bufImp
    ret
MuestraImporte ENDP

; ValidaCodigo: revisa el formato ABC-123, o sea 3 letras mayusculas, un guion y 3 digitos.
; Entra: EDX con el texto y EAX con su longitud. Sale: EAX en 1 si esta bien y en 0 si no.
; Conserva: ESI y ECX (USES). Modifica: solo EAX.
; Ahora los rangos 'A' a 'Z' y '0' a '9' los revisa el macro FueraDeRango.
; Cambio: ahora usa USES (antes los pop estaban repetidos en las 2 salidas) y FueraDeRango en lugar de 2 bloques
; de cmp, jb, cmp, ja.
ValidaCodigo PROC USES esi ecx
    cmp eax, 7
    jne vc_mal                    ; tiene que medir 7
    mov esi, edx                  ; ESI recorre el texto
    mov ecx, 3                    ; reviso 3 letras
vc_letras:
    mov al, [esi]
    FueraDeRango al, 'A', 'Z', vc_mal
    inc esi
    loop vc_letras
    cmp BYTE PTR [esi], '-'       ; ahora va el guion
    jne vc_mal
    inc esi
    mov ecx, 3                    ; reviso 3 digitos
vc_digitos:
    mov al, [esi]
    FueraDeRango al, '0', '9', vc_mal
    inc esi
    loop vc_digitos
    mov eax, 1
    ret
vc_mal:
    mov eax, 0
    ret
ValidaCodigo ENDP

; ParseEntero: convierte un texto a numero.
; Recorro con ESI y voy haciendo lo que llevo por 10 mas el digito.
; Rechazo vacio y lo que no sea digito, y reviso que no se desborde con CF.
; Entra: ESI con el texto y ECX con su longitud.
; Sale: EAX con el numero, CF en 0 si salio bien y en 1 si hubo error.
; Conserva: EBX, EDX, ESI y ECX (USES). Modifica: EAX y banderas.
; Cambio: ahora usa USES (antes 4 push y 8 pop porque cada salida repetia los 4 pop) y FueraDeRango para los digitos.
; Paso de 35 a 20 lineas.
ParseEntero PROC USES ebx edx esi ecx
    cmp ecx, 0
    je  pe_mal                    ; si esta vacio lo rechazo
    mov eax, 0                    ; empiezo en 0
pe_ciclo:
    movzx ebx, BYTE PTR [esi]     ; agarro el caracter
    FueraDeRango bl, '0', '9', pe_mal  ; si no es digito lo rechazo
    sub ebx, '0'                  ; lo vuelvo numero
    mul diez                      ; multiplico lo que llevo por 10
    jc  pe_mal                    ; si no cabe en 32 bits se prende CF
    add eax, ebx                  ; le sumo el digito
    jc  pe_mal                    ; reviso CF otra vez
    inc esi
    loop pe_ciclo
    clc                           ; CF en 0 significa que salio bien
    ret
pe_mal:
    stc                           ; CF en 1 significa que hubo error
    ret
ParseEntero ENDP

; ParsePrecio: convierte un precio como 185.50 a centavos.
; Acepta pesos solos, o pesos con un punto y 1 o 2 decimales.
; Rechaza simbolos, comas, 185., .50, un tercer decimal, 0 y mas de 9999.99.
; Entra: ESI con el texto y ECX con su longitud.
; Sale: EAX con los centavos, CF en 1 si hubo error.
; Conserva: EBX, EDX, ESI, ECX y EDI (USES). Modifica: EAX y banderas.
; Cambio: ahora usa USES (antes 5 push y 10 pop) y FueraDeRango en 5 lugares (digitos, decimales y rango final).
ParsePrecio PROC USES ebx edx esi ecx edi
    cmp ecx, 0
    je  pp_mal                    ; si esta vacio lo rechazo
    mov eax, 0                    ; EAX lleva los pesos
    mov edi, 0                    ; EDI cuenta los digitos de pesos
pp_pesos:
    cmp ecx, 0
    je  pp_sin_punto              ; se acabo el texto sin punto
    movzx ebx, BYTE PTR [esi]
    cmp bl, '.'
    je  pp_punto
    FueraDeRango bl, '0', '9', pp_mal  ; si es simbolo o coma lo rechazo
    sub ebx, '0'
    mul diez                      ; pesos por 10
    jc  pp_mal
    add eax, ebx                  ; mas el digito
    jc  pp_mal
    cmp eax, 9999
    ja  pp_mal                    ; no puede pasar de 9999 pesos
    inc edi
    inc esi
    dec ecx
    jmp pp_pesos
pp_sin_punto:
    cmp edi, 0
    je  pp_mal
    mov ebx, 100
    mul ebx                       ; paso los pesos a centavos
    jmp pp_rango
pp_punto:
    cmp edi, 0
    je  pp_mal                    ; necesita pesos antes del punto
    inc esi                       ; me salto el punto
    dec ecx                       ; ECX queda con cuantos decimales hay
    FueraDeRango ecx, 1, 2, pp_mal  ; tiene que haber 1 o 2 decimales
    mov ebx, 100
    mul ebx                       ; pesos por 100
    mov edi, eax                  ; guardo los centavos de los pesos
    movzx eax, BYTE PTR [esi]     ; primer decimal
    FueraDeRango al, '0', '9', pp_mal
    sub eax, '0'
    mov ebx, 10
    mul ebx                       ; la decena de centavos
    cmp ecx, 2
    jne pp_suma                   ; solo hay un decimal
    movzx ebx, BYTE PTR [esi + 1] ; segundo decimal
    FueraDeRango bl, '0', '9', pp_mal
    sub ebx, '0'
    add eax, ebx
pp_suma:
    add eax, edi                  ; sumo los centavos de los pesos
pp_rango:
    FueraDeRango eax, 1, MAX_PRECIO, pp_mal  ; de 0.01 a 9999.99
    clc
    ret
pp_mal:
    stc
    ret
ParsePrecio ENDP

; PideCodigo: pide un codigo y lo valida, si sirve queda en tmpCod.
; Entra: nada. Sale: EAX en 1 si sirvio y en 0 si no (ya mostro el error).
; Conserva: ECX, EDX, ESI y EDI (USES). Modifica: solo EAX.
; Cambio: ahora usa USES y el macro Mostrar. Hace lo mismo que antes.
PideCodigo PROC USES ecx edx esi edi
    mov edx, OFFSET txtPideCod
    call LeeTexto                 ; el texto queda en bufEntrada
    mov edx, OFFSET bufEntrada
    call ValidaCodigo             ; EAX dice si sirvio
    cmp eax, 0
    je  pc_mal
    mov esi, OFFSET bufEntrada    ; copio el codigo a tmpCod
    mov edi, OFFSET tmpCod
    mov ecx, 7
    call CopiaBytes
    mov eax, 1
    ret
pc_mal:
    Mostrar msgCodMal
    mov eax, 0
    ret
PideCodigo ENDP

; LeeEntero: muestra un mensaje, lee un texto y lo convierte a numero.
; Antes estas lineas se repetian en PideCantidad y en AltaProducto (existencia).
; Entra: EDX con el mensaje. Sale: EAX con el numero, CF en 1 si el texto no es un numero valido.
; Conserva: ECX y ESI (USES; LeeTexto conserva EDX). Modifica: EAX y banderas.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Estas lineas (leer, pasar el largo a ECX, apuntar ESI al buffer y convertir) estaban
; dentro de PideCantidad y de AltaProducto.
LeeEntero PROC USES ecx esi
    call LeeTexto                 ; EAX trae cuantas letras escribio
    mov ecx, eax
    mov esi, OFFSET bufEntrada
    call ParseEntero              ; EAX con el numero, CF en 1 si hubo error
    ret
LeeEntero ENDP

; PideCantidad: pide una cantidad entera mayor que 0.
; Entra: nada. Sale: EAX con la cantidad, CF en 1 si se rechazo (ya mostro el error).
; Conserva: EDX (USES). Modifica: EAX y banderas.
; Cambio: antes tenia 26 lineas con la captura adentro. Ahora llama a LeeEntero y queda en 13.
PideCantidad PROC USES edx
    mov edx, OFFSET txtPideCant
    call LeeEntero                ; CF en 1 si hubo error
    jc  pq_mal
    cmp eax, 0
    je  pq_mal                    ; tiene que ser mayor que 0
    clc
    ret
pq_mal:
    Mostrar msgCantMal
    stc
    ret
PideCantidad ENDP

; LeePrecio: pide un precio y lo convierte a centavos.
; Entra: nada. Sale: EAX con los centavos, CF en 1 si el precio esta mal (no muestra el error,
; lo muestra quien lo llama). Conserva: ECX, EDX y ESI (USES). Modifica: EAX y banderas.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Estas lineas estaban dentro de AltaProducto.
LeePrecio PROC USES ecx edx esi
    mov edx, OFFSET txtPidePre
    call LeeTexto
    mov ecx, eax
    mov esi, OFFSET bufEntrada
    call ParsePrecio
    ret
LeePrecio ENDP

; PideNombre: pide el nombre, revisa que tenga de 1 a 25 letras y lo deja en tmpNom.
; Entra: nada. Sale: EAX en 1 si sirvio (queda en tmpNom) y en 0 si no (no muestra el error).
; Conserva: ECX, EDX, ESI y EDI (USES). Modifica: solo EAX.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Revisar el largo del nombre y copiarlo estaba dentro de AltaProducto.
PideNombre PROC USES ecx edx esi edi
    mov edx, OFFSET txtPideNom
    call LeeTexto                 ; EAX trae cuantas letras tiene el nombre
    FueraDeRango eax, 1, 25, pn_mal  ; vacio o de mas de 25 no vale
    mov edi, OFFSET tmpNom
    mov ecx, 26
    call LlenaCero                ; limpio tmpNom (LlenaCero conserva EAX)
    mov ecx, eax                  ; copio solo las letras del nombre
    mov esi, OFFSET bufEntrada
    mov edi, OFFSET tmpNom
    call CopiaBytes
    mov eax, 1
    ret
pn_mal:
    mov eax, 0
    ret
PideNombre ENDP

; CmpCodigo: compara dos codigos de 7 caracteres, letra por letra.
; Antes esta comparacion estaba escrita dos veces: en LocalizaProducto y en CodigoRepetidoAntes.
; Entra: ESI con un codigo y EDI con el otro. Sale: EAX en 1 si son iguales y en 0 si no.
; Conserva: EBX (USES). Modifica: solo EAX y banderas.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Con el, LocalizaProducto y CodigoRepetidoAntes ya no repiten el ciclo.
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

; LocalizaProducto: busca un codigo en la tabla recorriendo con ESI de 42 en 42 bytes.
; Entra: EDX con el codigo.
; Sale: EAX en 1 y ESI en el producto si lo encontro, EAX en 0 si no.
; Conserva: ECX y EDI (USES). Modifica: EAX y ESI, que son las salidas.
; Cambio: antes tenia su propio ciclo para comparar las 7 letras (29 lineas). Ahora llama a CmpCodigo y usa
; IniciaRecorrido. Quedo en 16 lineas y ya no tiene push ni pop.
LocalizaProducto PROC USES ecx edi
    mov edi, edx                  ; EDI es el codigo buscado, CmpCodigo lo compara contra ESI
    IniciaRecorrido               ; ESI en el primer producto y ECX con cuantos hay
    cmp ecx, 0
    je  lp_no                     ; no hay productos
lp_ciclo:
    call CmpCodigo                ; EAX en 1 si el codigo del producto es igual al buscado
    cmp eax, 1
    je  lp_fin                    ; lo encontre, EAX ya vale 1 y ESI esta en el producto
    add esi, REG_SIZE             ; siguiente producto, 42 bytes mas adelante
    loop lp_ciclo
lp_no:
    mov eax, 0
lp_fin:
    ret
LocalizaProducto ENDP

; PideYBuscaProducto: pide un codigo y busca el producto.
; Antes estas lineas estaban repetidas en BuscarProducto, RecibirMercancia y Vender.
; Entra: nada.
; Sale: EAX en 1 si lo encontro, con ESI y ptrProd en el producto. EAX en 0 si el codigo esta mal
; o no existe, y en ese caso ya mostro el error.
; Conserva: EDX (USES). Modifica: EAX y ESI, que son las salidas.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Lo uso en 3 opciones (buscar, recibir y vender).
PideYBuscaProducto PROC USES edx
    call PideCodigo               ; pido y valido el codigo
    cmp eax, 0
    je  pb_fin                    ; el codigo estaba mal, PideCodigo ya mostro el error
    mov edx, OFFSET tmpCod
    call LocalizaProducto         ; ESI queda en el producto si existe
    cmp eax, 0
    jne pb_encontrado
    Mostrar msgNoExiste
    mov eax, 0
    jmp pb_fin
pb_encontrado:
    mov ptrProd, esi              ; guardo el producto porque despues se vuelve a leer
pb_fin:
    ret
PideYBuscaProducto ENDP

; GuardaProductoNuevo: escribe en la tabla el producto que se capturo en tmpCod, tmpNom, tmpPre y tmpExi.
; Entra: las variables tmpCod, tmpNom, tmpPre y tmpExi ya validadas. Sale: un producto mas en la tabla.
; Conserva: EAX, EBX, ECX, EDX, ESI y EDI (USES). Modifica: numProd, cambios y la tabla.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Todo esto estaba en AltaProducto despues de las validaciones.
GuardaProductoNuevo PROC USES eax ebx ecx edx esi edi
    mov eax, numProd
    mov ebx, REG_SIZE
    mul ebx                       ; posicion del producto nuevo
    mov edi, OFFSET inventario
    add edi, eax                  ; EDI apunta al producto nuevo
    mov ptrProd, edi
    mov esi, OFFSET tmpCod        ; copio el codigo
    mov ecx, 8
    call CopiaBytes
    mov edi, ptrProd
    add edi, OFF_NOM              ; EDI es donde va el nombre
    mov esi, OFFSET tmpNom
    mov ecx, 26
    call CopiaBytes               ; copio el nombre
    mov esi, ptrProd              ; con ESI guardo precio y existencia
    mov eax, tmpPre
    mov [esi + OFF_PRE], eax
    mov eax, tmpExi
    mov [esi + OFF_EXI], eax
    inc numProd                   ; un producto mas
    mov cambios, 1                ; marco que hay cambios sin guardar
    ret
GuardaProductoNuevo ENDP

; AltaProducto: opcion 1, registra un producto.
; Todo se captura primero en variables temporales y solo si todo esta bien se guarda en la tabla.
; Asi, si algo se rechaza, el catalogo no cambia.
; Entra: nada. Sale: un producto nuevo o un mensaje de error.
; Conserva: EAX, EDX y ESI (USES). Modifica: nada.
; Cambio: antes tenia 85 lineas con todo adentro (pedir, validar y guardar). Ahora llama a PideNombre, LeePrecio,
; LeeEntero y GuardaProductoNuevo, y queda en 36. Hace lo mismo y sigue sin guardar nada si algo sale mal.
AltaProducto PROC USES eax edx esi
    cmp numProd, MAX_PROD
    jb  ap_hay_lugar
    MostrarYRegresar msgLleno     ; ya hay 10 productos
ap_hay_lugar:
    call PideCodigo               ; pido y valido el codigo
    cmp eax, 0
    je  ap_fin
    mov edx, OFFSET tmpCod        ; reviso que no este repetido
    call LocalizaProducto
    cmp eax, 1
    jne ap_nombre
    MostrarYRegresar msgDup       ; codigo repetido
ap_nombre:
    call PideNombre               ; EAX en 1 si el nombre sirvio
    cmp eax, 0
    je  ap_nom_mal
    call LeePrecio                ; CF en 1 si el precio esta mal
    jc  ap_pre_mal
    mov tmpPre, eax
    mov edx, OFFSET txtPideExi
    call LeeEntero                ; CF en 1 si la existencia esta mal
    jc  ap_exi_mal
    FueraDeRango eax, 0, MAX_STOCK, ap_exi_mal  ; de 0 a 100
    mov tmpExi, eax
    call GuardaProductoNuevo      ; todo es valido: ahora si lo escribo en la tabla
    MostrarYRegresar msgAlta
ap_nom_mal:
    MostrarYRegresar msgNomMal
ap_pre_mal:
    MostrarYRegresar msgPreMal
ap_exi_mal:
    Mostrar msgExiMal
ap_fin:
    ret
AltaProducto ENDP

; MuestraProducto: muestra una linea con codigo, nombre, precio y existencia.
; Entra: ESI con el producto. Sale: nada. Conserva: EAX y EDX (USES). Modifica: nada.
; Cambio: ahora usa USES (antes 2 push y 2 pop) y el macro Mostrar.
MuestraProducto PROC USES eax edx
    mov edx, esi                  ; el codigo esta al inicio del producto
    call WriteString
    Mostrar txtSep
    mov edx, esi
    add edx, OFF_NOM              ; el nombre esta 8 bytes despues
    call WriteString
    Mostrar txtSep
    mov eax, [esi + OFF_PRE]      ; el precio esta 34 bytes despues
    call MuestraImporte
    Mostrar txtSepExi
    mov eax, [esi + OFF_EXI]      ; la existencia esta 38 bytes despues
    call MuestraNumero
    Mostrar txtCrlf
    ret
MuestraProducto ENDP

; MuestraInventario: opcion 2, muestra todos los productos recorriendo con ESI.
; Entra: nada. Sale: la lista en pantalla. Conserva: ECX, EDX y ESI (USES). Modifica: nada.
; Cambio: ahora usa USES, IniciaRecorrido y Mostrar.
MuestraInventario PROC USES ecx edx esi
    cmp numProd, 0
    jne mi_hay
    MostrarYRegresar msgInvVacio
mi_hay:
    Mostrar txtEncInv
    IniciaRecorrido               ; ESI en el primer producto, ECX con cuantos hay
mi_ciclo:
    call MuestraProducto
    add esi, REG_SIZE             ; siguiente producto
    loop mi_ciclo
    ret
MuestraInventario ENDP

; BuscarProducto: opcion 3, busca un producto por codigo y lo muestra.
; Entra: nada. Sale: el producto en pantalla. Conserva: EAX, EDX y ESI (USES). Modifica: nada.
; Cambio: antes tenia 18 lineas porque pedia el codigo y lo buscaba aqui mismo. Ahora llama a PideYBuscaProducto
; y queda en 9.
BuscarProducto PROC USES eax edx esi
    call PideYBuscaProducto       ; ESI queda en el producto
    cmp eax, 0
    je  bp_fin
    Mostrar txtEncInv
    call MuestraProducto          ; ESI ya apunta al producto
bp_fin:
    ret
BuscarProducto ENDP

; RecibirMercancia: opcion 4, suma unidades a un producto sin pasar de 100.
; Primero calculo y reviso, y solo si cabe lo guardo.
; Entra: nada. Sale: la existencia nueva o un mensaje de error.
; Conserva: EAX, EBX, EDX y ESI (USES). Modifica: nada.
; Cambio: antes pedia y buscaba el codigo aqui mismo (40 lineas). Ahora usa PideYBuscaProducto y queda en 23.
RecibirMercancia PROC USES eax ebx edx esi
    call PideYBuscaProducto       ; ESI apunta al producto, ptrProd tambien
    cmp eax, 0
    je  rm_fin
    call PideCantidad             ; CF en 1 si se rechazo
    jc  rm_fin
    mov esi, ptrProd
    mov ebx, [esi + OFF_EXI]      ; existencia actual
    add ebx, eax                  ; nueva existencia
    jc  rm_desb                   ; si se desborda
    cmp ebx, MAX_STOCK
    ja  rm_excede                 ; pasaria de 100
    mov [esi + OFF_EXI], ebx      ; ya revise, ahora si guardo
    mov cambios, 1
    LineaNumero msgRecibida, ebx
    ret
rm_desb:
    MostrarYRegresar msgDesb
rm_excede:
    Mostrar msgExcede
rm_fin:
    ret
RecibirMercancia ENDP

; CalculaImporte: importe igual al precio de un producto por una cantidad.
; Antes el MUL con el precio estaba escrito en Vender y en Resumen. Ahora sirve para las dos.
; Entra: ESI con el producto y EAX con la cantidad (en el resumen, la existencia).
; Sale: EAX con el importe en centavos, CF en 1 si no cabe en 32 bits.
; Conserva: EDX (USES). Modifica: EAX y banderas.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. El MUL con el precio estaba en Vender y otra vez en Resumen.
CalculaImporte PROC USES edx
    mul DWORD PTR [esi + OFF_PRE] ; EDX:EAX es EAX por el precio, MUL prende CF si no cabe
    ret
CalculaImporte ENDP

; CalculaDescuento: regla del negocio, descuento por cantidad.
; Si se llevan 5 o mas unidades el descuento es el 10 por ciento del importe base.
; El DIV quita los centavos sobrantes, asi no quedan fracciones de centavo.
; Entra: EAX con el importe base y EBX con la cantidad.
; Sale: EAX con el descuento (0 si no aplica), CF en 1 si hubo desbordamiento.
; Conserva: EBX y EDX (USES). Modifica: EAX y banderas.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. La regla del descuento estaba metida dentro de Vender. Si cambia la regla solo
; toco este procedimiento y las constantes DESC_MIN y DESC_PORC.
CalculaDescuento PROC USES ebx edx
    cmp ebx, DESC_MIN
    jb  cd_sin_desc               ; con menos de 5 unidades no hay descuento
    mov ebx, DESC_PORC
    mul ebx                       ; base por 10
    jc  cd_desb
    mov ebx, 100
    mov edx, 0
    div ebx                       ; base por 10 entre 100, el DIV quita los centavos sobrantes
    clc
    ret
cd_sin_desc:
    mov eax, 0
    clc
    ret
cd_desb:
    stc
    ret
CalculaDescuento ENDP

; MuestraVenta: muestra el resultado de una venta aceptada.
; Entra: las variables baseImp, descImp, finalImp y ptrProd. Sale: el resultado en pantalla.
; Conserva: EAX, EDX y ESI (USES). Modifica: nada.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Era la parte final de Vender, donde mostraba el resultado de la venta.
MuestraVenta PROC USES eax edx esi
    Mostrar msgVentaOk
    LineaImporte txtBase, baseImp
    cmp descImp, 0
    je  mv_sin_desc
    LineaImporte txtDesc, descImp ; si hubo descuento lo muestro
    jmp mv_final
mv_sin_desc:
    Mostrar txtSinDesc
mv_final:
    LineaImporte txtFinal, finalImp
    mov esi, ptrProd
    LineaNumero txtRestan, <[esi + OFF_EXI]>
    ret
MuestraVenta ENDP

; Vender: opcion 5, hace una venta. Aqui va la regla extra, el descuento por cantidad.
; 1 pido el codigo y la cantidad.
; 2 reviso que haya existencias.
; 3 importe base igual a precio por cantidad.
; 4 descuento por cantidad si aplica.
; 5 reviso que los ingresos no se desborden.
; 6 hasta el final actualizo existencia e ingresos, asi no queda nada a medias si se rechaza.
; Entra: nada. Sale: la venta aceptada o un mensaje de error.
; Conserva: EAX, EBX, EDX y ESI (USES). Modifica: nada.
; Cambio: antes tenia 96 lineas. Ahora usa PideYBuscaProducto, CalculaImporte, CalculaDescuento y MuestraVenta y queda
; en 40. Las revisiones y el orden son los mismos: lo ultimo que hace es actualizar la existencia y los ingresos.
Vender PROC USES eax ebx edx esi
    call PideYBuscaProducto       ; ESI y ptrProd en el producto
    cmp eax, 0
    je  v_fin
    call PideCantidad             ; CF en 1 si se rechazo
    jc  v_fin
    mov cantidad, eax
    mov esi, ptrProd
    mov ebx, [esi + OFF_EXI]      ; EBX es la existencia actual
    cmp eax, ebx
    ja  v_sin_exist               ; quiere mas de lo que hay

    call CalculaImporte           ; EAX es la cantidad, regresa el importe base
    jc  v_desb                    ; no cabe
    mov baseImp, eax

    mov ebx, cantidad
    call CalculaDescuento         ; EAX con el descuento, 0 si no aplica
    jc  v_desb
    mov descImp, eax
    mov eax, baseImp
    sub eax, descImp              ; importe final
    mov finalImp, eax

    mov ebx, ingresos             ; ingresos de la sesion: reviso que no se desborden
    add ebx, eax
    jc  v_desb

    mov ingresos, ebx             ; venta aceptada: ahora si actualizo todo
    mov esi, ptrProd
    mov eax, [esi + OFF_EXI]
    sub eax, cantidad             ; resto las unidades vendidas
    mov [esi + OFF_EXI], eax
    mov cambios, 1
    call MuestraVenta
    ret

v_sin_exist:
    LineaNumero msgSinExist, ebx  ; EBX es la existencia actual
    ret
v_desb:
    Mostrar msgDesb
v_fin:
    ret
Vender ENDP

; CalculaTotales: suma las unidades y el valor de todo el inventario recorriendo con ESI.
; Entra: nada.
; Sale: EAX con las unidades, EDX con el valor en centavos, CF en 1 si hubo desbordamiento.
; Conserva: EBX, ECX, ESI y EDI (USES). Modifica: EAX, EDX y banderas, que son las salidas.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. El recorrido que suma estaba dentro de Resumen.
CalculaTotales PROC USES ebx ecx esi edi
    mov ebx, 0                    ; EBX cuenta las unidades
    mov edi, 0                    ; EDI suma el valor
    IniciaRecorrido               ; ESI en el primer producto y ECX con cuantos hay
    cmp ecx, 0
    je  ct_listo                  ; sin productos todo vale 0
ct_ciclo:
    mov eax, [esi + OFF_EXI]
    add ebx, eax                  ; sumo las unidades
    call CalculaImporte           ; existencia por precio, CF en 1 si no cabe
    jc  ct_desb
    add edi, eax                  ; sumo al valor
    jc  ct_desb
    add esi, REG_SIZE
    loop ct_ciclo
ct_listo:
    mov eax, ebx
    mov edx, edi
    clc
    ret
ct_desb:
    stc
    ret
CalculaTotales ENDP

; Resumen: opcion 6, muestra unidades disponibles, valor del inventario e ingresos de la sesion.
; Entra: nada. Sale: el resumen en pantalla. Conserva: EAX y EDX (USES). Modifica: nada.
; Cambio: antes tenia 54 lineas porque sumaba y tambien mostraba. Ahora llama a CalculaTotales y solo muestra (13 lineas).
Resumen PROC USES eax edx
    call CalculaTotales           ; EAX unidades, EDX valor, CF en 1 si se desbordo
    jc  rs_desb
    mov totUnid, eax              ; los guardo porque mostrar un texto cambia EDX
    mov totValor, edx
    LineaNumero txtResUni, totUnid
    LineaImporte txtResVal, totValor
    LineaImporte txtResIng, ingresos
    ret
rs_desb:
    Mostrar msgDesb
    ret
Resumen ENDP

; Formato de inventario.dat:
; bytes 0 a 3 la marca INV1
; bytes 4 a 7 cuantos productos trae
; despues los registros de 42 bytes, iguales a los de la tabla
; el tamano debe ser 8 mas productos por 42

; ArmaImagenArchivo: arma en archBuf lo que se va a escribir en el archivo.
; Antes estas lineas estaban dentro de GuardarArchivo.
; Entra: la tabla inventario y numProd. Sale: archBuf listo y totalBytes con cuantos bytes escribir.
; Conserva: EAX, EBX, ECX, EDX, ESI y EDI (USES). Modifica: archBuf y totalBytes.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Estas lineas estaban al principio de GuardarArchivo.
ArmaImagenArchivo PROC USES eax ebx ecx edx esi edi
    mov DWORD PTR [archBuf], MAGICO   ; pongo la marca INV1
    mov eax, numProd
    mov DWORD PTR [archBuf + 4], eax  ; pongo cuantos productos hay
    mov ebx, REG_SIZE
    mul ebx                       ; productos por 42
    mov ecx, eax                  ; ECX es cuantos bytes copiar
    add eax, 8
    mov totalBytes, eax           ; total a escribir
    mov esi, OFFSET inventario
    mov edi, OFFSET archBuf + 8
    call CopiaBytes               ; copio la tabla al buffer del archivo
    ret
ArmaImagenArchivo ENDP

; GuardarArchivo: opcion 7, guarda el catalogo en inventario.dat.
; Armo la imagen del archivo, creo el archivo, escribo todo y lo cierro.
; Despues reviso que se hayan escrito todos los bytes que pedi.
; Entra: nada. Sale: el archivo o un mensaje de error. Conserva: EAX, ECX y EDX (USES). Modifica: nada.
; Cambio: antes tenia 44 lineas. Ahora arma el buffer con ArmaImagenArchivo y usa LineaNumero para el mensaje final
; (25 lineas).
GuardarArchivo PROC USES eax ecx edx
    call ArmaImagenArchivo
    mov edx, OFFSET nomArchivo
    call CreateOutputFile         ; EAX trae el handle
    cmp eax, INVALID_HANDLE_VALUE
    je  gu_err_crear              ; no se pudo crear
    mov manejador, eax

    mov eax, manejador            ; EAX trae el handle
    mov edx, OFFSET archBuf       ; EDX es lo que voy a escribir
    mov ecx, totalBytes           ; ECX es cuantos bytes quiero escribir
    call WriteToFile              ; EAX regresa con los bytes escritos
    mov escritos, eax
    mov eax, manejador
    call CloseFile                ; cierro el archivo

    mov eax, escritos
    cmp eax, totalBytes           ; reviso que se escribieron todos los bytes
    jne gu_err_escr
    mov cambios, 0                ; ya no hay cambios sin guardar
    LineaNumero msgGuardado, escritos
    ret
gu_err_crear:
    MostrarYRegresar msgErrCrear
gu_err_escr:
    MostrarYRegresar msgErrEscr
GuardarArchivo ENDP

; ValidaRegistro: revisa que un producto leido del archivo sea valido.
; Codigo ABC-123, nombre de 1 a 25 letras, precio de 1 a 999999 y existencia de 0 a 100.
; Entra: ESI con el producto. Sale: EAX en 1 si esta bien y en 0 si no.
; Conserva: EBX y EDX (USES). Modifica: solo EAX.
; Cambio: ahora usa USES y FueraDeRango para revisar el precio y la existencia.
ValidaRegistro PROC USES ebx edx
    cmp BYTE PTR [esi + 7], 0     ; el codigo termina en 0
    jne vr_mal
    mov edx, esi
    mov eax, 7
    call ValidaCodigo             ; reviso el formato del codigo
    cmp eax, 0
    je  vr_mal

    mov ebx, 0                    ; EBX es la posicion en el nombre
vr_nombre:
    mov al, [esi + ebx + OFF_NOM]
    cmp al, 0
    je  vr_fin_nombre             ; encontre el 0 del final
    cmp al, 20h
    jb  vr_mal                    ; caracter raro, no vale
    inc ebx
    cmp ebx, 25
    jb  vr_nombre                 ; reviso hasta 25 letras
    cmp BYTE PTR [esi + OFF_NOM + 25], 0  ; con 25 letras sigue el 0
    jne vr_mal
    jmp vr_precio
vr_fin_nombre:
    cmp ebx, 0
    je  vr_mal                    ; nombre vacio
vr_precio:
    mov eax, [esi + OFF_PRE]
    FueraDeRango eax, 1, MAX_PRECIO, vr_mal  ; de 0.01 a 9999.99
    mov eax, [esi + OFF_EXI]
    FueraDeRango eax, 0, MAX_STOCK, vr_mal   ; de 0 a 100
    mov eax, 1
    ret
vr_mal:
    mov eax, 0
    ret
ValidaRegistro ENDP

; CodigoRepetidoAntes: revisa si el codigo ya salio en un producto anterior del archivo.
; Ahora compara con CmpCodigo, antes tenia su propio ciclo de comparacion.
; Entra: ESI con el producto. Sale: EAX en 1 si esta repetido y en 0 si no.
; Conserva: EDI (USES; CmpCodigo conserva EBX). Modifica: solo EAX.
; La ia me ayudo hacer esto
; Cambio: antes tenia su propio ciclo para comparar los 7 caracteres (28 lineas). Ahora usa CmpCodigo y queda en 15.
CodigoRepetidoAntes PROC USES edi
    mov edi, OFFSET archBuf + 8   ; EDI empieza en el primer producto del archivo
cr_registro:
    cmp edi, esi
    jae cr_no                     ; llegue al producto actual, no hubo repetidos
    call CmpCodigo                ; EAX en 1 si el codigo de EDI es igual al de ESI
    cmp eax, 1
    je  cr_fin                    ; esta repetido, EAX ya vale 1
    add edi, REG_SIZE             ; siguiente producto anterior
    jmp cr_registro
cr_no:
    mov eax, 0
cr_fin:
    ret
CodigoRepetidoAntes ENDP

; ValidaArchivo: revisa que lo que se leyo en archBuf sea un inventario valido.
; Marca INV1, cantidad de 0 a 10, tamano exacto y cada producto valido y sin codigos repetidos.
; Antes estas revisiones estaban dentro de CargarArchivo.
; Entra: archBuf y leidos (cuantos bytes se leyeron).
; Sale: EAX en 1 si todo esta bien, en 0 si no. Deja en cargaN cuantos productos trae.
; Conserva: EBX, ECX, EDX y ESI (USES). Modifica: solo EAX y cargaN.
; La ia me ayudo hacer esto con la marca y la revision del tamano exacto
; Cambio: procedimiento nuevo. Estas revisiones estaban dentro de CargarArchivo.
ValidaArchivo PROC USES ebx ecx edx esi
    mov ebx, leidos
    cmp ebx, 8
    jb  va_mal                    ; no trae ni el encabezado
    cmp DWORD PTR [archBuf], MAGICO
    jne va_mal                    ; no es mi archivo
    mov ecx, DWORD PTR [archBuf + 4]  ; ECX es cuantos productos dice que trae
    cmp ecx, MAX_PROD
    ja  va_mal                    ; mas de 10 no se puede
    mov cargaN, ecx
    mov eax, ecx
    mov edx, REG_SIZE
    mul edx                       ; productos por 42
    add eax, 8                    ; mas el encabezado es el tamano esperado
    cmp eax, leidos
    jne va_mal                    ; el tamano no coincide, archivo danado
    cmp ecx, 0
    je  va_ok                     ; archivo vacio, no hay que revisar
    mov esi, OFFSET archBuf + 8   ; ESI recorre los productos del archivo
va_revisa:
    call ValidaRegistro           ; reviso el producto
    cmp eax, 0
    je  va_mal
    call CodigoRepetidoAntes      ; reviso que no este repetido
    cmp eax, 1
    je  va_mal
    add esi, REG_SIZE             ; siguiente producto
    loop va_revisa                ; ECX es cuantos faltan
va_ok:
    mov eax, 1
    ret
va_mal:
    mov eax, 0
    ret
ValidaArchivo ENDP

; ReemplazaCatalogo: cambia la tabla por los productos que se leyeron del archivo.
; Solo se llama despues de que ValidaArchivo dijo que todo esta bien.
; Entra: archBuf y cargaN. Sale: la tabla nueva, numProd y cambios en 0.
; Conserva: EAX, EBX, ECX, EDX, ESI y EDI (USES). Modifica: la tabla, numProd y cambios.
; La ia me ayudo hacer esto
; Cambio: procedimiento nuevo. Estas lineas estaban al final de CargarArchivo.
ReemplazaCatalogo PROC USES eax ebx ecx edx esi edi
    mov edi, OFFSET inventario
    mov ecx, MAX_PROD * REG_SIZE
    call LlenaCero                ; limpio la tabla
    mov eax, cargaN
    mov ebx, REG_SIZE
    mul ebx                       ; bytes a copiar
    mov ecx, eax
    mov esi, OFFSET archBuf + 8
    mov edi, OFFSET inventario
    call CopiaBytes
    mov eax, cargaN
    mov numProd, eax
    mov cambios, 0                ; la memoria ya es igual al archivo
    ret
ReemplazaCatalogo ENDP

; CargarArchivo: opcion 8, carga el catalogo de inventario.dat.
; No cambio nada hasta comprobar que todo el archivo es valido.
; Si no existe o esta danado muestro el error y el catalogo se queda como estaba.
; Entra: nada. Sale: el catalogo nuevo o un mensaje de error.
; Conserva: EAX, EBX, ECX y EDX (USES). Modifica: nada.
; Cambio: antes tenia 78 lineas con todo adentro (abrir, leer, validar y reemplazar). Ahora usa ValidaArchivo y
; ReemplazaCatalogo y queda en 31.
CargarArchivo PROC USES eax ebx ecx edx
    mov edx, OFFSET nomArchivo
    call OpenInputFile            ; EAX trae el handle
    cmp eax, INVALID_HANDLE_VALUE
    je  ca_ausente                ; no existe o no se pudo abrir
    mov manejador, eax

    mov eax, manejador            ; EAX trae el handle
    mov edx, OFFSET archBuf       ; EDX es donde se guarda lo leido
    mov ecx, ARCH_MAX + 1         ; pido un byte de mas para saber si el archivo es muy grande
    call ReadFromFile             ; EAX regresa con los bytes leidos
    jc  ca_err_lectura
    mov leidos, eax
    mov eax, manejador
    call CloseFile

    mov ebx, leidos
    mov BYTE PTR archBuf[ebx], 0  ; pongo el 00h despues del ultimo byte leido
    call ValidaArchivo            ; EAX en 1 si todo el archivo es valido
    cmp eax, 0
    je  ca_invalido
    call ReemplazaCatalogo        ; todo es valido: ahora si reemplazo el catalogo
    LineaNumero msgCargado, numProd
    ret

ca_ausente:
    MostrarYRegresar msgNoArch
ca_err_lectura:
    mov eax, manejador            ; aunque fallo cierro el archivo
    call CloseFile
    MostrarYRegresar msgErrLect
ca_invalido:
    MostrarYRegresar msgArchMal
CargarArchivo ENDP

; PruebaRegistros: opcion 9, prueba que los procedimientos no cambien EBX, ECX, ESI y EDI
; y que la pila quede igual que al entrar.
; Con USES el push de los registros lo hace el procedimiento al entrar, asi que guardo ESP
; con la primera instruccion y lo comparo antes del RET.
; Entra: nada. Sale: mensajes de OK o FALLO.
; Conserva: EAX, EBX, ECX, EDX, ESI y EDI (USES). Modifica: nada.
; Cambio: antes guardaba EBX, ECX, ESI y EDI con push y pop a mano y comparaba ESP escrito a mano. Ahora usa USES,
; CompruebaReg y ChequeaPila. Paso de 50 a 27 lineas.
PruebaRegistros PROC USES eax ebx ecx edx esi edi
    mov espPrueba, esp            ; guardo ESP despues de que USES guardo los registros
    mov ebx, 11111111h
    mov ecx, 22222222h
    mov esi, 33333333h
    mov edi, 44444444h

    mov eax, 18550
    call MuestraImporte           ; debe salir $185.50 MXN
    Mostrar txtCrlf
    mov eax, 77
    call MuestraNumero
    Mostrar txtCrlf
    mov edx, OFFSET codPrueba
    mov eax, 7
    call ValidaCodigo

    CompruebaReg ebx, 11111111h, pr_mal
    CompruebaReg ecx, 22222222h, pr_mal
    CompruebaReg esi, 33333333h, pr_mal
    CompruebaReg edi, 44444444h, pr_mal
    Mostrar msgRegOk
    jmp pr_pila
pr_mal:
    Mostrar msgRegMal
pr_pila:
    ChequeaPila espPrueba, msgPilaOk, msgPilaMal  ; ESP debe ser igual que al entrar
    ret
PruebaRegistros ENDP

END main
