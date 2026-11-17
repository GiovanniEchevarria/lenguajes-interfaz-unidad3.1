# Instrucciones de compilación y ejecución

## Qué contiene

- `unidad3/Proyecto_Ventas_Inventario_U3.asm`: versión de la Unidad 3 (la entrega actual).
- `unidad2/Proyecto_Ventas_Inventario_U2.asm`: versión original, para comparar.
- `inventario.dat`: inventario de prueba con 3 productos.

## Compilar con Visual Studio

Usa el proyecto de Visual Studio con MASM e Irvine32 que ya tienes (el mismo de las prácticas y de la Unidad 2).

1. Abre el proyecto y agrega `unidad3/Proyecto_Ventas_Inventario_U3.asm` (clic derecho en el proyecto → *Add → Existing Item*).
2. **Solo puede haber un archivo `.asm` con `main` en el proyecto.** Quita del proyecto (*Remove*) cualquier otro, incluido el de la Unidad 2. Para probar la versión anterior, quita el de la Unidad 3 y agrega el de la Unidad 2.
3. Compila con **Ctrl+Shift+B** y ejecuta con **Ctrl+F5**.

Requisitos del proyecto (los mismos de las prácticas): *Build Customizations → masm* activado; carpeta de `Irvine32.inc` en las rutas de include de MASM; `irvine32.lib` y `kernel32.lib` en las dependencias del linker; subsistema *Console*; plataforma **x86 (Win32)**.

## Dónde debe estar `inventario.dat`

El programa busca `inventario.dat` en la carpeta de trabajo. Al ejecutar desde Visual Studio con Ctrl+F5 normalmente es la carpeta del proyecto (donde está el `.vcxproj`). Si ejecutas el `.exe` directamente, ponlo junto al `.exe`. El archivo se carga con la opción 8 del menú.

## Subir a GitHub

1. Copia los archivos de este repositorio dentro de la carpeta de tu proyecto de Visual Studio (junto a tu `.sln` y `.vcxproj`) para que el repositorio tenga el proyecto completo.
2. Crea un repositorio **público** en github.com.
3. Sube todo (en la web: *Add file → Upload files*, o con `git add`, `git commit` y `git push`). El archivo `.gitignore` evita subir las carpetas generadas por Visual Studio.
4. Abre el enlace en una ventana de incógnito para confirmar que se ve sin iniciar sesión.

## Menú del programa

| Opción | Qué hace |
|---|---|
| 1 | Registrar producto |
| 2 | Mostrar inventario |
| 3 | Buscar por código |
| 4 | Recibir mercancía |
| 5 | Vender (con descuento por cantidad) |
| 6 | Resumen |
| 7 | Guardar catálogo en archivo |
| 8 | Cargar catálogo desde archivo |
| 9 | Prueba de conservación de registros y pila |
| 0 | Salir (avisa si hay cambios sin guardar) |
