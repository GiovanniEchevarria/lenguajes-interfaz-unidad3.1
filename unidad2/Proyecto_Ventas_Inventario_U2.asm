; Materia: Lenguajes de Interfaz
; Alumno: Giovanni De Jesus Echevarria Yañez 
; Horario: 10-11 
; Docente: Dr. José Luis Medina Jiménez
; Proyecto: Sistema de ventas e inventario en ensamblador
; Descripcion: Tienda de accesorios para videojuegos. Registra hasta 10 productos,
; recibe mercancia, vende, muestra un resumen y guarda y carga el catalogo en un archivo.
; Regla extra: descuento del 10 por ciento si se llevan 5 o mas unidades.
;
; Como lo hice:
; Los numeros se leen con ReadString y se muestran con WriteString.
; Las conversiones de texto a numero y de numero a texto las hice yo.
; Los precios se guardan en centavos, asi 185.50 pesos son 18550.
; Cada producto es un registro de 42 bytes dentro de la tabla inventario.
; En el registro el codigo empieza en 0, el nombre en 8, el precio en 34 y la existencia en 38.
; Con ESI recorro la tabla y los textos.

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
main PROC
    mov espInicial, esp           ; guardo ESP para ver que la pila no se descuadre. La ia me ayudo hacer esto
    mov edx, OFFSET txtBienv
    call WriteString

inicio:
    cmp esp, espInicial           ; si ESP cambio la pila quedo mal
    je  pila_ok
    mov edx, OFFSET msgPilaMal
    call WriteString
pila_ok:
    mov edx, OFFSET txtMenu
    call WriteString
    mov edx, OFFSET bufEntrada
    mov ecx, BUFMAX
    call ReadString               ; EAX trae cuantas letras escribio
    cmp eax, 1
    jne op_mala                   ; la opcion es de un solo caracter
    mov al, bufEntrada            ; AL trae la opcion
    cmp al, '1'
    je  op1
    cmp al, '2'
    je  op2
    cmp al, '3'
    je  op3
    cmp al, '4'
    je  op4
    cmp al, '5'
    je  op5
    cmp al, '6'
    je  op6
    cmp al, '7'
    je  op7
    cmp al, '8'
    je  op8
    cmp al, '9'
    je  op9
    cmp al, '0'
    je  op0

op_mala:
    mov edx, OFFSET msgOpMala
    call WriteString
    jmp inicio

op1:
    call AltaProducto
    jmp inicio
op2:
    call MuestraInventario
    jmp inicio
op3:
    call BuscarProducto
    jmp inicio
op4:
    call RecibirMercancia
    jmp inicio
op5:
    call Vender
    jmp inicio
op6:
    call Resumen
    jmp inicio
op7:
    call GuardarArchivo
    jmp inicio
op8:
    call CargarArchivo
    jmp inicio
op9:
    call PruebaRegistros
    jmp inicio

op0:                              ; salir, aviso si hay cambios sin guardar
    cmp cambios, 0
    je  salir
    mov edx, OFFSET txtSalirSin
    call LeeTexto
    cmp eax, 1
    jne inicio                    ; cualquier otra cosa y no sale
    mov al, bufEntrada
    cmp al, 'S'
    je  salir
    cmp al, 's'
    je  salir
    jmp inicio

salir:
    exit
main ENDP

; LeeTexto: muestra un mensaje y lee lo que escriba el usuario.
; Entra: EDX con el mensaje. Sale: EAX con cuantas letras escribio, el texto queda en bufEntrada.
; Cambia: solo EAX.
; La ia me ayudo hacer esto
LeeTexto PROC
    push ecx
    push edx
    call WriteString              ; imprimo el mensaje
    mov edx, OFFSET bufEntrada    ; EDX es donde se guarda lo que escriba
    mov ecx, BUFMAX               ; ECX es el maximo de letras
    call ReadString               ; EAX queda con cuantas letras escribio
    pop edx
    pop ecx
    ret
LeeTexto ENDP

; CopiaBytes: copia ECX bytes de un lugar a otro.
; Entra: ESI origen, EDI destino, ECX cuantos bytes. Sale: nada. Cambia: nada.
; La ia me ayudo hacer esto
CopiaBytes PROC
    push eax
    push ecx
    push esi
    push edi
    cmp ecx, 0
    je  cb_fin                    ; si no hay nada que copiar me salgo
cb_ciclo:
    mov al, [esi]                 ; agarro un byte del origen
    mov [edi], al                 ; lo pongo en el destino
    inc esi
    inc edi
    loop cb_ciclo
cb_fin:
    pop edi
    pop esi
    pop ecx
    pop eax
    ret
CopiaBytes ENDP

; LlenaCero: pone ECX bytes en 0 desde la direccion que traiga EDI.
; Entra: EDI y ECX. Sale: nada. Cambia: nada.
; La ia me ayudo hacer esto
LlenaCero PROC
    push ecx
    push edi
    cmp ecx, 0
    je  lz_fin
lz_ciclo:
    mov BYTE PTR [edi], 0
    inc edi
    loop lz_ciclo
lz_fin:
    pop edi
    pop ecx
    ret
LlenaCero ENDP

; AgregaTexto: pega un texto al final de lo que voy escribiendo.
; Entra: EDI con el texto y ESI con donde escribir. Sale: ESI queda en el 0 final. Cambia: ESI.
; La ia me ayudo hacer esto
AgregaTexto PROC
    push eax
    push edi
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
    pop edi
    pop eax
    ret
AgregaTexto ENDP

; NumACadena: convierte un numero a texto.
; Divido entre 10 y el residuo es un digito. Los meto a la pila y al sacarlos quedan en orden.
; A cada digito le sumo el codigo de 0 para volverlo letra.
; Entra: EAX con el numero y ESI con donde escribir.
; Sale: el texto con su 0 final y ESI queda en ese 0. Cambia: ESI.
NumACadena PROC
    push eax
    push ebx
    push ecx
    push edx
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
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
NumACadena ENDP

; MuestraNumero: muestra un numero en pantalla con WriteString.
; Entra: EAX con el numero. Sale: nada. Cambia: nada.
; La ia me ayudo hacer esto
MuestraNumero PROC
    push edx
    push esi
    mov esi, OFFSET bufNum
    call NumACadena
    mov edx, OFFSET bufNum
    call WriteString
    pop esi
    pop edx
    ret
MuestraNumero ENDP

; MuestraImporte: muestra un importe en pesos con dos decimales y MXN.
; Divido los centavos entre 100: el cociente son los pesos y el residuo los centavos.
; Los centavos los separo en decena y unidad, asi el 5 sale como 05.
; Entra: EAX con los centavos. Sale: el texto en pantalla, por ejemplo $185.50 MXN. Cambia: nada.
MuestraImporte PROC
    push eax
    push ebx
    push edx
    push esi
    push edi
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
    mov edx, OFFSET bufImp
    call WriteString
    pop edi
    pop esi
    pop edx
    pop ebx
    pop eax
    ret
MuestraImporte ENDP

; ValidaCodigo: revisa el formato ABC-123, o sea 3 letras mayusculas, un guion y 3 digitos.
; Entra: EDX con el texto y EAX con su longitud. Sale: EAX en 1 si esta bien y en 0 si no. Cambia: EAX.
ValidaCodigo PROC
    push esi
    push ecx
    cmp eax, 7
    jne vc_mal                    ; tiene que medir 7
    mov esi, edx                  ; ESI recorre el texto
    mov ecx, 3                    ; reviso 3 letras
vc_letras:
    mov al, [esi]
    cmp al, 'A'
    jb  vc_mal                    ; si es menor que A no es mayuscula
    cmp al, 'Z'
    ja  vc_mal                    ; si es mayor que Z tampoco
    inc esi
    loop vc_letras
    cmp BYTE PTR [esi], '-'       ; ahora va el guion
    jne vc_mal
    inc esi
    mov ecx, 3                    ; reviso 3 digitos
vc_digitos:
    mov al, [esi]
    cmp al, '0'
    jb  vc_mal
    cmp al, '9'
    ja  vc_mal
    inc esi
    loop vc_digitos
    mov eax, 1
    pop ecx
    pop esi
    ret
vc_mal:
    mov eax, 0
    pop ecx
    pop esi
    ret
ValidaCodigo ENDP

; ParseEntero: convierte un texto a numero.
; Recorro con ESI y voy haciendo lo que llevo por 10 mas el digito.
; Rechazo vacio y lo que no sea digito, y reviso que no se desborde con CF.
; Entra: ESI con el texto y ECX con su longitud.
; Sale: EAX con el numero, CF en 0 si salio bien y en 1 si hubo error. Cambia: EAX y banderas.
ParseEntero PROC
    push ebx
    push edx
    push esi
    push ecx
    cmp ecx, 0
    je  pe_mal                    ; si esta vacio lo rechazo
    mov eax, 0                    ; empiezo en 0
pe_ciclo:
    movzx ebx, BYTE PTR [esi]     ; agarro el caracter
    cmp bl, '0'
    jb  pe_mal                    ; si no es digito lo rechazo
    cmp bl, '9'
    ja  pe_mal                    ; si no es digito lo rechazo
    sub ebx, '0'                  ; lo vuelvo numero
    mul diez                      ; multiplico lo que llevo por 10
    jc  pe_mal                    ; si no cabe en 32 bits se prende CF
    add eax, ebx                  ; le sumo el digito
    jc  pe_mal                    ; reviso CF otra vez
    inc esi
    loop pe_ciclo
    pop ecx
    pop esi
    pop edx
    pop ebx
    clc                           ; CF en 0 significa que salio bien
    ret
pe_mal:
    pop ecx
    pop esi
    pop edx
    pop ebx
    stc                           ; CF en 1 significa que hubo error
    ret
ParseEntero ENDP

; ParsePrecio: convierte un precio como 185.50 a centavos.
; Acepta pesos solos, o pesos con un punto y 1 o 2 decimales.
; Rechaza simbolos, comas, 185., .50, un tercer decimal, 0 y mas de 9999.99.
; Entra: ESI con el texto y ECX con su longitud.
; Sale: EAX con los centavos, CF en 1 si hubo error. Cambia: EAX y banderas.
ParsePrecio PROC
    push ebx
    push edx
    push esi
    push ecx
    push edi
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
    cmp bl, '0'
    jb  pp_mal                    ; si es simbolo o coma lo rechazo
    cmp bl, '9'
    ja  pp_mal
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
    cmp ecx, 1
    jb  pp_mal                    ; tiene que haber minimo un decimal
    cmp ecx, 2
    ja  pp_mal                    ; mas de 2 decimales no se acepta
    mov ebx, 100
    mul ebx                       ; pesos por 100
    mov edi, eax                  ; guardo los centavos de los pesos
    movzx eax, BYTE PTR [esi]     ; primer decimal
    cmp al, '0'
    jb  pp_mal
    cmp al, '9'
    ja  pp_mal
    sub eax, '0'
    mov ebx, 10
    mul ebx                       ; la decena de centavos
    cmp ecx, 2
    jne pp_suma                   ; solo hay un decimal
    movzx ebx, BYTE PTR [esi + 1] ; segundo decimal
    cmp bl, '0'
    jb  pp_mal
    cmp bl, '9'
    ja  pp_mal
    sub ebx, '0'
    add eax, ebx
pp_suma:
    add eax, edi                  ; sumo los centavos de los pesos
pp_rango:
    cmp eax, 1
    jb  pp_mal                    ; 0.00 no se acepta
    cmp eax, MAX_PRECIO
    ja  pp_mal                    ; mas de 9999.99 no se acepta
    pop edi
    pop ecx
    pop esi
    pop edx
    pop ebx
    clc
    ret
pp_mal:
    pop edi
    pop ecx
    pop esi
    pop edx
    pop ebx
    stc
    ret
ParsePrecio ENDP

; PideCodigo: pide un codigo y lo valida, si sirve queda en tmpCod.
; Entra: nada. Sale: EAX en 1 si sirvio y en 0 si no. Cambia: solo EAX.
; La ia me ayudo hacer esto
PideCodigo PROC
    push edx
    push esi
    push edi
    push ecx
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
    jmp pc_fin
pc_mal:
    mov edx, OFFSET msgCodMal
    call WriteString
    mov eax, 0
pc_fin:
    pop ecx
    pop edi
    pop esi
    pop edx
    ret
PideCodigo ENDP

; PideCantidad: pide una cantidad entera mayor que 0.
; Entra: nada. Sale: EAX con la cantidad, CF en 1 si se rechazo. Cambia: EAX y banderas.
; La ia me ayudo hacer esto
PideCantidad PROC
    push edx
    push esi
    push ecx
    mov edx, OFFSET txtPideCant
    call LeeTexto
    mov ecx, eax
    mov esi, OFFSET bufEntrada
    call ParseEntero              ; CF en 1 si hubo error
    jc  pq_mal
    cmp eax, 0
    je  pq_mal                    ; tiene que ser mayor que 0
    pop ecx
    pop esi
    pop edx
    clc
    ret
pq_mal:
    mov edx, OFFSET msgCantMal
    call WriteString
    pop ecx
    pop esi
    pop edx
    stc
    ret
PideCantidad ENDP

; LocalizaProducto: busca un codigo en la tabla recorriendo con ESI de 42 en 42 bytes.
; Entra: EDX con el codigo. Sale: EAX en 1 y ESI en el producto si lo encontro, EAX en 0 si no.
; Cambia: EAX y ESI.
LocalizaProducto PROC
    push ebx
    push ecx
    mov esi, OFFSET inventario    ; ESI empieza en el primer producto
    mov ecx, numProd              ; reviso tantos como productos haya
    cmp ecx, 0
    je  lp_no                     ; no hay productos
lp_registro:
    mov ebx, 0                    ; EBX es la posicion de la letra
lp_caracter:
    mov al, [esi + ebx]           ; letra del producto guardado
    cmp al, [edx + ebx]           ; contra la del codigo buscado
    jne lp_siguiente              ; si es distinta paso al siguiente producto
    inc ebx
    cmp ebx, 7
    jb  lp_caracter
    mov eax, 1                    ; las 7 letras son iguales, lo encontre
    pop ecx
    pop ebx
    ret
lp_siguiente:
    add esi, REG_SIZE             ; siguiente producto, 42 bytes mas adelante
    loop lp_registro
lp_no:
    mov eax, 0
    pop ecx
    pop ebx
    ret
LocalizaProducto ENDP

; AltaProducto: opcion 1, registra un producto.
; Todo se captura primero en variables temporales y solo si todo esta bien se guarda en la tabla.
; Asi, si algo se rechaza, el catalogo no cambia.
; Cambia: EAX, EBX, ECX, EDX, ESI y EDI.
AltaProducto PROC
    cmp numProd, MAX_PROD
    jb  ap_hay_lugar
    mov edx, OFFSET msgLleno      ; ya hay 10 productos
    call WriteString
    ret
ap_hay_lugar:
    call PideCodigo               ; pido y valido el codigo
    cmp eax, 0
    je  ap_fin
    mov edx, OFFSET tmpCod        ; reviso que no este repetido
    call LocalizaProducto
    cmp eax, 1
    jne ap_nombre
    mov edx, OFFSET msgDup        ; codigo repetido
    call WriteString
    jmp ap_fin

ap_nombre:
    mov edx, OFFSET txtPideNom
    call LeeTexto                 ; EAX trae cuantas letras tiene el nombre
    cmp eax, 1
    jb  ap_nom_mal                ; si esta vacio lo rechazo
    cmp eax, 25
    ja  ap_nom_mal                ; mas de 25 letras no vale
    mov edi, OFFSET tmpNom
    mov ecx, 26
    call LlenaCero                ; limpio tmpNom
    mov ecx, eax                  ; copio solo las letras del nombre
    mov esi, OFFSET bufEntrada
    mov edi, OFFSET tmpNom
    call CopiaBytes

    mov edx, OFFSET txtPidePre
    call LeeTexto
    mov ecx, eax
    mov esi, OFFSET bufEntrada
    call ParsePrecio              ; CF en 1 si el precio esta mal
    jc  ap_pre_mal
    mov tmpPre, eax

    mov edx, OFFSET txtPideExi
    call LeeTexto
    mov ecx, eax
    mov esi, OFFSET bufEntrada
    call ParseEntero              ; CF en 1 si la existencia esta mal
    jc  ap_exi_mal
    cmp eax, MAX_STOCK
    ja  ap_exi_mal                ; mas de 100 no vale
    mov tmpExi, eax

    ; todo es valido: ahora si lo escribo en la tabla
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
    mov edx, OFFSET msgAlta
    call WriteString
    jmp ap_fin

ap_nom_mal:
    mov edx, OFFSET msgNomMal
    call WriteString
    jmp ap_fin
ap_pre_mal:
    mov edx, OFFSET msgPreMal
    call WriteString
    jmp ap_fin
ap_exi_mal:
    mov edx, OFFSET msgExiMal
    call WriteString
ap_fin:
    ret
AltaProducto ENDP

; MuestraProducto: muestra una linea con codigo, nombre, precio y existencia.
; Entra: ESI con el producto. Sale: nada. Cambia: nada.
; La ia me ayudo hacer esto
MuestraProducto PROC
    push eax
    push edx
    mov edx, esi                  ; el codigo esta al inicio del producto
    call WriteString
    mov edx, OFFSET txtSep
    call WriteString
    mov edx, esi
    add edx, OFF_NOM              ; el nombre esta 8 bytes despues
    call WriteString
    mov edx, OFFSET txtSep
    call WriteString
    mov eax, [esi + OFF_PRE]      ; el precio esta 34 bytes despues
    call MuestraImporte
    mov edx, OFFSET txtSepExi
    call WriteString
    mov eax, [esi + OFF_EXI]      ; la existencia esta 38 bytes despues
    call MuestraNumero
    mov edx, OFFSET txtCrlf
    call WriteString
    pop edx
    pop eax
    ret
MuestraProducto ENDP

; MuestraInventario: opcion 2, muestra todos los productos recorriendo con ESI.
; Entra: nada. Sale: la lista en pantalla. Cambia: nada.
MuestraInventario PROC
    push esi
    push ecx
    push edx
    cmp numProd, 0
    jne mi_hay
    mov edx, OFFSET msgInvVacio
    call WriteString
    jmp mi_fin
mi_hay:
    mov edx, OFFSET txtEncInv
    call WriteString
    mov esi, OFFSET inventario    ; ESI empieza en el primer producto
    mov ecx, numProd              ; una vuelta por producto
mi_ciclo:
    call MuestraProducto
    add esi, REG_SIZE             ; siguiente producto
    loop mi_ciclo
mi_fin:
    pop edx
    pop ecx
    pop esi
    ret
MuestraInventario ENDP

; BuscarProducto: opcion 3, busca un producto por codigo y lo muestra.
; Entra: nada. Sale: el producto en pantalla. Cambia: EAX, EDX y ESI.
BuscarProducto PROC
    call PideCodigo               ; pido el codigo
    cmp eax, 0
    je  bp_fin
    mov edx, OFFSET tmpCod
    call LocalizaProducto         ; ESI queda en el producto
    cmp eax, 0
    je  bp_no
    mov edx, OFFSET txtEncInv
    call WriteString
    call MuestraProducto          ; ESI ya apunta al producto
    ret
bp_no:
    mov edx, OFFSET msgNoExiste
    call WriteString
bp_fin:
    ret
BuscarProducto ENDP

; RecibirMercancia: opcion 4, suma unidades a un producto sin pasar de 100.
; Primero calculo y reviso, y solo si cabe lo guardo.
; Cambia: EAX, EBX, EDX y ESI.
RecibirMercancia PROC
    call PideCodigo
    cmp eax, 0
    je  rm_fin
    mov edx, OFFSET tmpCod
    call LocalizaProducto         ; ESI apunta al producto
    cmp eax, 0
    je  rm_no
    mov ptrProd, esi              ; guardo el producto porque se vuelve a leer
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
    mov edx, OFFSET msgRecibida
    call WriteString
    mov eax, ebx
    call MuestraNumero
    mov edx, OFFSET txtCrlf
    call WriteString
    ret
rm_no:
    mov edx, OFFSET msgNoExiste
    call WriteString
    ret
rm_desb:
    mov edx, OFFSET msgDesb
    call WriteString
    ret
rm_excede:
    mov edx, OFFSET msgExcede
    call WriteString
rm_fin:
    ret
RecibirMercancia ENDP

; Vender: opcion 5, hace una venta. Aqui va la regla extra, el descuento por cantidad.
; 1 pido el codigo y la cantidad.
; 2 reviso que haya existencias.
; 3 importe base igual a precio por cantidad.
; 4 si son 5 o mas unidades descuento del 10 por ciento, el DIV quita los centavos sobrantes.
; 5 reviso que los ingresos no se desborden.
; 6 hasta el final actualizo existencia e ingresos, asi no queda nada a medias si se rechaza.
; Cambia: EAX, EBX, EDX y ESI.
Vender PROC
    call PideCodigo
    cmp eax, 0
    je  v_fin
    mov edx, OFFSET tmpCod
    call LocalizaProducto         ; ESI apunta al producto
    cmp eax, 0
    je  v_no
    mov ptrProd, esi
    call PideCantidad             ; CF en 1 si se rechazo
    jc  v_fin
    mov cantidad, eax
    mov esi, ptrProd
    mov ebx, [esi + OFF_EXI]      ; EBX es la existencia actual
    cmp eax, ebx
    ja  v_sin_exist               ; quiere mas de lo que hay

    ; importe base = precio * cantidad
    mov eax, [esi + OFF_PRE]
    mul cantidad                  ; precio por cantidad
    jc  v_desb                    ; no cabe
    mov baseImp, eax

    ; regla del negocio: descuento por cantidad
    mov descImp, 0                ; empiezo sin descuento
    cmp cantidad, DESC_MIN
    jb  v_sin_desc                ; con menos de 5 unidades no hay descuento
    mov ebx, DESC_PORC
    mul ebx                       ; base por 10
    jc  v_desb
    mov ebx, 100
    mov edx, 0
    div ebx                       ; base por 10 entre 100, el DIV quita los centavos sobrantes
    mov descImp, eax
v_sin_desc:
    mov eax, baseImp
    sub eax, descImp              ; importe final
    mov finalImp, eax

    ; ingresos de la sesion: reviso que no se desborden
    mov ebx, ingresos
    add ebx, eax
    jc  v_desb

    ; venta aceptada: ahora si actualizo todo
    mov ingresos, ebx
    mov esi, ptrProd
    mov eax, [esi + OFF_EXI]
    sub eax, cantidad             ; resto las unidades vendidas
    mov [esi + OFF_EXI], eax
    mov cambios, 1

    mov edx, OFFSET msgVentaOk
    call WriteString
    mov edx, OFFSET txtBase
    call WriteString
    mov eax, baseImp
    call MuestraImporte
    mov edx, OFFSET txtCrlf
    call WriteString
    cmp descImp, 0
    je  v_msg_sin_desc
    mov edx, OFFSET txtDesc       ; si hubo descuento lo muestro
    call WriteString
    mov eax, descImp
    call MuestraImporte
    mov edx, OFFSET txtCrlf
    call WriteString
    jmp v_final
v_msg_sin_desc:
    mov edx, OFFSET txtSinDesc
    call WriteString
v_final:
    mov edx, OFFSET txtFinal
    call WriteString
    mov eax, finalImp
    call MuestraImporte
    mov edx, OFFSET txtCrlf
    call WriteString
    mov edx, OFFSET txtRestan
    call WriteString
    mov esi, ptrProd
    mov eax, [esi + OFF_EXI]
    call MuestraNumero
    mov edx, OFFSET txtCrlf
    call WriteString
    ret

v_no:
    mov edx, OFFSET msgNoExiste
    call WriteString
    ret
v_sin_exist:
    mov edx, OFFSET msgSinExist
    call WriteString
    mov eax, ebx                  ; EBX es la existencia actual
    call MuestraNumero
    mov edx, OFFSET txtCrlf
    call WriteString
    ret
v_desb:
    mov edx, OFFSET msgDesb
    call WriteString
v_fin:
    ret
Vender ENDP

; Resumen: opcion 6, muestra unidades disponibles, valor del inventario e ingresos de la sesion.
; Entra: nada. Sale: el resumen en pantalla. Cambia: nada.
Resumen PROC
    push eax
    push ebx
    push ecx
    push edx
    push esi
    push edi
    mov ebx, 0                    ; EBX cuenta las unidades
    mov edi, 0                    ; EDI suma el valor
    mov esi, OFFSET inventario
    mov ecx, numProd
    cmp ecx, 0
    je  rs_mostrar                ; sin productos todo vale 0
rs_ciclo:
    mov eax, [esi + OFF_EXI]
    add ebx, eax                  ; sumo las unidades
    mul DWORD PTR [esi + OFF_PRE] ; existencia por precio
    jc  rs_desb
    add edi, eax                  ; sumo al valor
    jc  rs_desb
    add esi, REG_SIZE
    loop rs_ciclo
rs_mostrar:
    mov edx, OFFSET txtResUni
    call WriteString
    mov eax, ebx
    call MuestraNumero
    mov edx, OFFSET txtCrlf
    call WriteString
    mov edx, OFFSET txtResVal
    call WriteString
    mov eax, edi
    call MuestraImporte
    mov edx, OFFSET txtCrlf
    call WriteString
    mov edx, OFFSET txtResIng
    call WriteString
    mov eax, ingresos
    call MuestraImporte
    mov edx, OFFSET txtCrlf
    call WriteString
    jmp rs_fin
rs_desb:
    mov edx, OFFSET msgDesb
    call WriteString
rs_fin:
    pop edi
    pop esi
    pop edx
    pop ecx
    pop ebx
    pop eax
    ret
Resumen ENDP

; Formato de inventario.dat:
; bytes 0 a 3 la marca INV1
; bytes 4 a 7 cuantos productos trae
; despues los registros de 42 bytes, iguales a los de la tabla
; el tamano debe ser 8 mas productos por 42
; La ia me ayudo hacer esto con la marca y la revision del tamano exacto

; GuardarArchivo: opcion 7, guarda el catalogo en inventario.dat.
; Armo la imagen del archivo en archBuf, creo el archivo, escribo todo y lo cierro.
; Despues reviso que se hayan escrito todos los bytes que pedi.
; Cambia: EAX, EBX, ECX, EDX, ESI y EDI.
GuardarArchivo PROC
    mov DWORD PTR [archBuf], MAGICO  ; pongo la marca INV1. La ia me ayudo hacer esto
    mov eax, numProd
    mov DWORD PTR [archBuf + 4], eax  ; pongo cuantos productos hay
    mov ebx, REG_SIZE
    mul ebx                       ; posicion del producto nuevo
    mov ecx, eax                  ; ECX es cuantos bytes copiar
    add eax, 8
    mov totalBytes, eax           ; total a escribir
    mov esi, OFFSET inventario
    mov edi, OFFSET archBuf + 8
    call CopiaBytes               ; copio la tabla al buffer del archivo

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
    mov edx, OFFSET msgGuardado
    call WriteString
    mov eax, escritos
    call MuestraNumero
    mov edx, OFFSET txtCrlf
    call WriteString
    ret
gu_err_crear:
    mov edx, OFFSET msgErrCrear
    call WriteString
    ret
gu_err_escr:
    mov edx, OFFSET msgErrEscr
    call WriteString
    ret
GuardarArchivo ENDP

; ValidaRegistro: revisa que un producto leido del archivo sea valido.
; Codigo ABC-123, nombre de 1 a 25 letras, precio de 1 a 999999 y existencia de 0 a 100.
; Entra: ESI con el producto. Sale: EAX en 1 si esta bien y en 0 si no. Cambia: EAX.
ValidaRegistro PROC
    push ebx
    push edx
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
    cmp eax, 1
    jb  vr_mal                    ; precio 0 no vale
    cmp eax, MAX_PRECIO
    ja  vr_mal                    ; precio de mas de 9999.99
    mov eax, [esi + OFF_EXI]
    cmp eax, MAX_STOCK
    ja  vr_mal                    ; existencia de mas de 100
    mov eax, 1
    pop edx
    pop ebx
    ret
vr_mal:
    mov eax, 0
    pop edx
    pop ebx
    ret
ValidaRegistro ENDP

; CodigoRepetidoAntes: revisa si el codigo ya salio en un producto anterior del archivo.
; Entra: ESI con el producto. Sale: EAX en 1 si esta repetido y en 0 si no. Cambia: EAX.
; La ia me ayudo hacer esto
CodigoRepetidoAntes PROC
    push ebx
    push edi
    mov edi, OFFSET archBuf + 8   ; EDI empieza en el primer producto del archivo
cr_registro:
    cmp edi, esi
    jae cr_no                     ; llegue al producto actual, no hubo repetidos
    mov ebx, 0
cr_caracter:
    mov al, [edi + ebx]
    cmp al, [esi + ebx]
    jne cr_siguiente
    inc ebx
    cmp ebx, 7
    jb  cr_caracter
    mov eax, 1                    ; las 7 letras son iguales, esta repetido
    pop edi
    pop ebx
    ret
cr_siguiente:
    add edi, REG_SIZE
    jmp cr_registro
cr_no:
    mov eax, 0
    pop edi
    pop ebx
    ret
CodigoRepetidoAntes ENDP

; CargarArchivo: opcion 8, carga el catalogo de inventario.dat.
; No cambio nada hasta comprobar que todo el archivo es valido.
; Si no existe o esta danado muestro el error y el catalogo se queda como estaba.
; Cambia: EAX, EBX, ECX, EDX, ESI y EDI.
CargarArchivo PROC
    mov edx, OFFSET nomArchivo
    call OpenInputFile            ; EAX trae el handle
    cmp eax, INVALID_HANDLE_VALUE
    je  ca_ausente                ; no existe o no se pudo abrir
    mov manejador, eax

    mov eax, manejador            ; EAX trae el handle
    mov edx, OFFSET archBuf       ; EDX es donde se guarda lo leido
    mov ecx, ARCH_MAX + 1         ; pido un byte de mas para saber si el archivo es muy grande. La ia me ayudo hacer esto
    call ReadFromFile             ; EAX regresa con los bytes leidos
    jc  ca_err_lectura
    mov leidos, eax
    mov eax, manejador
    call CloseFile

    mov ebx, leidos
    mov BYTE PTR archBuf[ebx], 0  ; pongo el 00h despues del ultimo byte leido

    cmp ebx, 8
    jb  ca_invalido               ; no trae ni el encabezado
    cmp DWORD PTR [archBuf], MAGICO
    jne ca_invalido               ; no es mi archivo
    mov ecx, DWORD PTR [archBuf + 4]  ; ECX es cuantos productos dice que trae
    cmp ecx, MAX_PROD
    ja  ca_invalido               ; mas de 10 no se puede
    mov cargaN, ecx
    mov eax, ecx
    mov edx, REG_SIZE
    mul edx                       ; productos por 42
    add eax, 8                    ; mas el encabezado es el tamano esperado
    cmp eax, leidos
    jne ca_invalido               ; el tamano no coincide, archivo danado

    cmp ecx, 0
    je  ca_aplicar                ; archivo vacio, no hay que revisar
    mov esi, OFFSET archBuf + 8   ; ESI recorre los productos del archivo
ca_revisa:
    call ValidaRegistro           ; reviso el producto
    cmp eax, 0
    je  ca_invalido
    call CodigoRepetidoAntes      ; reviso que no este repetido
    cmp eax, 1
    je  ca_invalido
    add esi, REG_SIZE             ; siguiente producto
    loop ca_revisa                ; ECX es cuantos faltan

; todo es valido: ahora si reemplazo el catalogo
ca_aplicar:
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
    mov edx, OFFSET msgCargado
    call WriteString
    mov eax, numProd
    call MuestraNumero
    mov edx, OFFSET txtCrlf
    call WriteString
    ret

ca_ausente:
    mov edx, OFFSET msgNoArch
    call WriteString
    ret
ca_err_lectura:
    mov eax, manejador            ; aunque fallo cierro el archivo
    call CloseFile
    mov edx, OFFSET msgErrLect
    call WriteString
    ret
ca_invalido:
    mov edx, OFFSET msgArchMal
    call WriteString
    ret
CargarArchivo ENDP

; PruebaRegistros: opcion 9, prueba que los procedimientos no cambien EBX, ECX, ESI y EDI
; y que la pila quede igual que al entrar.
; La ia me ayudo hacer esto
PruebaRegistros PROC
    mov espPrueba, esp            ; guardo ESP al entrar
    push ebx
    push ecx
    push esi
    push edi
    mov ebx, 11111111h
    mov ecx, 22222222h
    mov esi, 33333333h
    mov edi, 44444444h

    mov eax, 18550
    call MuestraImporte           ; debe salir $185.50 MXN
    mov edx, OFFSET txtCrlf
    call WriteString
    mov eax, 77
    call MuestraNumero
    mov edx, OFFSET txtCrlf
    call WriteString
    mov edx, OFFSET codPrueba
    mov eax, 7
    call ValidaCodigo

    cmp ebx, 11111111h
    jne pr_mal
    cmp ecx, 22222222h
    jne pr_mal
    cmp esi, 33333333h
    jne pr_mal
    cmp edi, 44444444h
    jne pr_mal
    mov edx, OFFSET msgRegOk
    call WriteString
    jmp pr_pila
pr_mal:
    mov edx, OFFSET msgRegMal
    call WriteString
pr_pila:
    pop edi
    pop esi
    pop ecx
    pop ebx
    cmp esp, espPrueba            ; ESP debe ser igual que al entrar
    jne pr_pila_mal
    mov edx, OFFSET msgPilaOk
    call WriteString
    ret
pr_pila_mal:
    mov edx, OFFSET msgPilaMal
    call WriteString
    ret
PruebaRegistros ENDP

END main
