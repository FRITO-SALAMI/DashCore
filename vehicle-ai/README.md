# IA libre para el vehículo

El servicio elimina el fondo con **U²-Net pequeño (`u2netp`)** y aplica iluminación cian y un acabado nocturno. No usa OpenAI ni APIs de pago. El modelo y sus dependencias no van en la APK.

Conserva el ángulo fotografiado. Para una vista frontal hay que proporcionar una foto frontal. No genera una nueva vista 3D ni un GLB.

## Activación

1. Desplegar este directorio como Docker Web Service en una cuenta propia. Se incluye `render.yaml` con `plan: free`. También puede ejecutarse en un servidor propio.
2. Definir `VEHICLE_AI_TOKEN` con un secreto aleatorio fuerte en ese servidor.
3. Proporcionar la URL HTTPS final del servidor para verificar destino y aprobar la publicación de `supabase/functions/stylize-vehicle`.
4. Guardar en **Supabase → Edge Functions → Secrets** `VEHICLE_AI_URL=https://TU-SERVIDOR/render` y el mismo `VEHICLE_AI_TOKEN`. Nunca ponerlos en Flutter ni enviarlos por el chat.
5. Probar primero con una imagen de ejemplo. La app comprueba el estado antes de subir fotos; si falta configuración, conserva la foto local.

No se ha activado un servidor externo: falta elegir y vincular una cuenta del propietario. El auto-review exige identificar y autorizar el destino exacto de las fotos antes de publicar el proxy.

Render ofrece Web Services gratuitos, con suspensión por inactividad y arranques lentos. Su plan gratuito sirve para pruebas; no garantiza capacidad para una app pública. No se ha contratado ningún plan ni prometido disponibilidad ilimitada.

## Privacidad y límites

- Foto PNG sin EXIF ni coordenadas; procesamiento bajo petición explícita.
- Solo Supabase conoce el token del worker; el cliente no puede elegir la URL.
- Una inferencia simultánea y máximo 10 MB por foto.
- No guarda fotos en el worker, no escribe recorridos y no registra cuerpos de peticiones.
- Resultado privado en `user-vehicles/<uid>/<vehicle_id>/artwork.png`.
- La eliminación de cuenta borra solo las carpetas del usuario.

Fuentes y licencias: [rembg (MIT)](https://github.com/danielgatis/rembg), [U²-Net (Apache-2.0)](https://github.com/xuebinqin/U-2-Net), [límites del hosting gratuito de Render](https://render.com/docs/free). Los avisos y licencias de dependencias se incluyen en sus distribuciones instaladas.
