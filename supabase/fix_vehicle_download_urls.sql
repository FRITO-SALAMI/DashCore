-- Corrige las rutas del catálogo para que coincidan exactamente con Storage.
BEGIN;

UPDATE public.vehicles
SET model_url = 'https://pvcfwpziojocogfctgbw.supabase.co/storage/v1/object/public/vehicles/model_url/Kiaoptima2012.glb'
WHERE id = 'optima_2012';

UPDATE public.vehicles
SET model_url = 'https://pvcfwpziojocogfctgbw.supabase.co/storage/v1/object/public/vehicles/model_url/Kia_Optima_15.glb'
WHERE id = 'kia_optima_15';

COMMIT;
