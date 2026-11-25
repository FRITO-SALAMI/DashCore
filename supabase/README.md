# Backend DashCore 2.0

Proyecto activo: `znrxgcfdvsmqkvejyrbo`. La APK contiene únicamente URL y clave publicable; RLS impone la autorización.

Migraciones ya aplicadas al nuevo proyecto, en este orden:

1. `schema.sql` — baseline para una base vacía.
2. `privacy_local_only.sql` — elimina telemetría/eventos/coordenadas heredados.
3. `manual_vehicles.sql` — vehículos propios y bucket privado de fotos.

No volver a ejecutar el baseline sobre el proyecto activo. Los otros SQL heredados son parches históricos, no una instalación 2.0. No ejecutar scripts de localización/telemetría: esas funciones se retiraron.

Funciones publicadas: `login-by-nickname`, `delete-account`, `submit-technical-report`. `import-catalog-assets` devuelve permanentemente 410 tras completar la migración. `stylize-vehicle` sigue pendiente de destino de procesamiento verificado y autorizado.

Los siete modelos ligeros se publicaron solo después de comprobar sus objetos en Storage. El catálogo guarda su tamaño para invalidar copias antiguas sin hacer HEAD por cada auto al iniciar.

`verify_owner_isolation.sql` crea usuarios sintéticos, prueba aislamiento y cascadas, y revierte toda la transacción. No elimina cuentas existentes ni modifica recursos base de forma persistente.

Correo/contraseña habilitado; Google deshabilitado. Configurar proveedor y redirects en Authentication antes de mostrar Google en la app. El redirect de recuperación actual se encuentra en `SupabaseService.resetPasswordRedirectUrl`; verificar que sea una página propia y que esté en la lista permitida del proyecto.
