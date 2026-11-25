# Punto Audio · Inventario y ventas · v18

Aplicación estática preparada para tu publicación existente de GitHub Pages. Conserva la marca en negro, rojo y blanco, el acceso por correo y la configuración del proyecto de Supabase. No requiere instalar dependencias ni compilar. No contiene productos ni ventas de prueba.

## Actualizar tu app existente

**Esta versión requiere actualizar Supabase antes de publicar los archivos.**

1. En tu app actual, sincroniza y descarga una copia de tus datos.
2. En el mismo proyecto de Supabase, abre **SQL Editor → New query**, pega el contenido completo de `ACTUALIZAR_SUPABASE.sql` y pulsa **Run**. Se añaden campos y una tabla; no se borran productos, ventas ni usuarios. Puede ejecutarse de nuevo sin duplicar las columnas.
3. Descomprime el paquete. En el repositorio que ya publica tu app, reemplaza `index.html`, `sw.js`, `manifest.webmanifest` y las carpetas `assets/` e `icons/`. Conserva sus nombres. Incluye `.nojekyll`. `index.html` debe quedar en la carpeta que publica Pages, no dentro de una carpeta adicional del ZIP.
4. Guarda con **Commit changes** y espera a que termine la publicación. Conserva la configuración de Pages y la dirección que ya usas.
5. Abre la app con conexión, vuelve a cargarla e inicia sesión. Pulsa el icono de sincronización o **Respaldar ahora** en ajustes. Comprueba que el total de productos coincida y aparezca un respaldo completo de esta versión.
6. Si la app instalada en Android sigue mostrando la anterior, ciérrala y vuelve a abrirla después de cargar la web con conexión. No borres los datos del navegador para actualizarla.

Para una instalación nueva, `schema.sql` contiene el esquema completo. En tu proyecto actual usa solamente `ACTUALIZAR_SUPABASE.sql`.

Si Pages aún no estuviera configurado: **Settings → Pages → Deploy from a branch**, elige la rama de publicación y la carpeta raíz. [Guía oficial de GitHub Pages](https://docs.github.com/en/pages/getting-started-with-github-pages/configuring-a-publishing-source-for-your-github-pages-site). [Base de datos y editor SQL de Supabase](https://supabase.com/docs/guides/database/overview).

## Inventario

- Presentación compacta para celular y escritorio. La cabecera decorativa se oculta en móvil para dejar espacio a los productos; se mantiene el logo.
- Pestañas inferiores fijas con iconos de inventario y carrito.
- Alta y edición mediante **+ Producto**. Los productos no llevan fotos ni avatares.
- Nombre, código, categoría, costo, precio de venta, stock y límite de aviso editables.
- Categorías existentes en un selector y opción para crear otra. Las variantes comunes, como «cargador» y «CARGADORES», se agrupan en «Cargadores».
- Búsqueda por código, nombre y categoría; filtros por categoría y stock bajo; orden por nombre, código, stock, precio o fecha de alta.
- Amarillo para stock inferior al límite y rojo para agotados. El límite inicial es 3: con 2 unidades se marca bajo; con 3 no.
- Ajustes rápidos de stock, reposición por código, eliminación con confirmación e historial por producto.
- Resumen de productos, unidades, costo del stock y ganancia estimada según precios de venta.

## Precios y ventas

La sugerencia es **costo de compra × 1,80**, redondeada a dos decimales: compra de Bs 50 → sugerido Bs 90. La pantalla muestra el importe y «Sugerido»; no muestra el porcentaje ni la fórmula. No se añade automáticamente la rebaja de Bs 15 usada en otros contextos.

Puedes guardar un precio personalizado o volver a **Usar sugerido**. En modo sugerido, cambiar el costo recalcula el precio; un precio personalizado se conserva. Las ventas admiten descuentos por debajo de la sugerencia o del costo y calculan la ganancia o pérdida real sin bloquearlas.

El carrito permite varios productos y cantidades con − y +. **El campo editable es el total por todas las unidades de esa línea**, como en tu app original. Ejemplo: 3 unidades con «100» suman Bs 100 al cobro. Al editar un total manualmente y cambiar después la cantidad, el total se conserva y aparece un recordatorio para revisarlo; **Usar sugerido** vuelve a calcularlo.

Antes de registrar se muestra el total y una revisión. Venta, reducción de stock y movimientos se guardan juntos en una transacción local. Una doble pulsación no duplica la venta. Anular devuelve las unidades y deja registro; si el producto fue eliminado, la confirmación explica que volverá al inventario con las unidades devueltas.

El total cobrado se guarda por separado del unitario: 3 unidades por Bs 100 conservan Bs 100 aunque el unitario se redondee a Bs 33,33. Las ventas antiguas conservan el detalle disponible; no es posible reconstruir centavos que ya se hubieran perdido en una copia anterior.

## Reportes y archivos

- Ventas, costo y ganancia real para hoy, últimos 7 días, mes y todo el historial. Se excluyen ventas anuladas.
- Productos más vendidos según el periodo seleccionado.
- Productos con stock, registrados hace al menos 30 días y sin ventas registradas en esos 30 días.
- Gráfico diario de 7, 14 o 30 días, incluyendo días sin ventas y pérdidas; tabla con valores exactos.
- CSV descargable de inventario, ventas del periodo y movimientos filtrados, con acentos, nombres y totales.
- Copia JSON con precios, límites, productos, ventas, anulaciones y movimientos. Restauración con validación y copia previa al reemplazar datos.

## Nube e historial

La cabecera y **Respaldo y ajustes** muestran el mismo estado. «Sincronizado» aparece después de terminar el envío y descarga, sin cambios locales pendientes. Se distingue entre respaldo completo en la nube y **último archivo generado**: descargar un JSON no confirma un respaldo en Supabase.

La app conserva los cambios en IndexedDB sin conexión y reintenta al reconectar. Muestra errores y actualizaciones pendientes de las tablas. Una edición durante una subida permanece pendiente hasta que su versión también se guarde.

Los movimientos nuevos guardan fecha, tipo, producto, cantidad y stock antes/después. Se envían a la nube y la app no tiene permiso para editarlos o borrarlos. Las ventas anteriores aparecen como antecedentes; no se inventan entradas ni niveles de stock anteriores a esta actualización.

Se conserva el acceso de la tienda original: los usuarios autenticados autorizados en ese proyecto comparten los datos de la tienda. La sincronización entre dispositivos conserva la prioridad por fecha de actualización; no reserva stock entre terminales que venden simultáneamente sin conexión. Sincroniza antes de alternar dispositivos para vender o ajustar el mismo producto.

## Archivos

| Archivo | Uso |
| --- | --- |
| `index.html` | App completa, estilos y lógica |
| `sw.js` | Caché v18 |
| `manifest.webmanifest` | Instalación de la PWA |
| `icons/` y `assets/` | Iconos, marca y cabecera |
| `ACTUALIZAR_SUPABASE.sql` | Actualización de tu base existente |
| `schema.sql` | Esquema completo para instalaciones nuevas |
| `GUION_PRESENTACION.md` | Guion breve para presentar la app |
| `.nojekyll` | Publicación estática directa |

## Validación realizada

Pasaron **29 comprobaciones de flujos** con Node, LinkeDOM e IndexedDB de prueba: migración local, categorías, precios, stock, carrito, centavos, anulaciones, auditoría, reportes, CSV, restauración y sincronización simulada, incluidos cambios durante una subida y errores parciales.

La actualización SQL se ejecutó dos veces sobre el esquema anterior en PostgreSQL aislado (PGlite): conservó los datos y se comprobaron campos nuevos, totales, permisos, validaciones y movimientos sin duplicados. También se comprobó la caché de la PWA y sus rutas bajo una subcarpeta de GitHub Pages.

No se aplicó el SQL a tu proyecto real, no se publicaron los archivos ni se escribieron datos en tu Supabase. La revisión visual en navegador y la conexión real de tu cuenta quedan pendientes; el entorno no permitió completarlas. Los archivos de prueba y sus productos no forman parte de este paquete.
