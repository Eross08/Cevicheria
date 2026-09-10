-- =========================================================
-- ESQUEMA DE BASE DE DATOS PARA RESERVAS EN SUPABASE
-- Cevichería "La Esquina de Augusto"
-- =========================================================

-- 1. Crear la tabla de reservas
CREATE TABLE IF NOT EXISTS public.reservas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    nombre TEXT NOT NULL,
    telefono TEXT NOT NULL,
    fecha DATE NOT NULL,
    hora TEXT NOT NULL,
    comensales INTEGER NOT NULL CHECK (comensales > 0),
    comentarios TEXT,
    estado TEXT DEFAULT 'pendiente' CHECK (estado IN ('pendiente', 'confirmada', 'cancelada', 'atendida'))
);

-- 2. Habilitar Seguridad por Fila (Row Level Security - RLS)
ALTER TABLE public.reservas ENABLE ROW LEVEL SECURITY;

-- 3. Crear política para permitir que los clientes anónimos puedan insertar reservas desde la web
DROP POLICY IF EXISTS "Permitir insercion publica de reservas" ON public.reservas;
CREATE POLICY "Permitir insercion publica de reservas" 
ON public.reservas 
FOR INSERT 
TO anon 
WITH CHECK (true);

-- 4. Crear política de lectura para usuarios autenticados (Panel admin/dueño)
DROP POLICY IF EXISTS "Permitir lectura para usuarios autenticados" ON public.reservas;
CREATE POLICY "Permitir lectura para usuarios autenticados" 
ON public.reservas 
FOR SELECT 
TO authenticated 
USING (true);

-- 5. Otorgar permisos de tabla a los roles anon y authenticated de Supabase
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON TABLE public.reservas TO anon, authenticated, service_role;

-- 6. (OPCIONAL) LIMPIEZA AUTOMÁTICA DE RESERVAS ANTIGUAS (Mantenimiento)
-- Habilita pg_cron para borrar automáticamente reservas de más de 6 meses (180 días)
CREATE EXTENSION IF NOT EXISTS pg_cron;

-- Programa la tarea para ejecutarse el día 1 de cada mes a las 03:00 AM UTC
SELECT cron.schedule(
    'limpiar-reservas-antiguas',
    '0 3 1 * *',
    $$DELETE FROM public.reservas WHERE fecha < CURRENT_DATE - INTERVAL '180 days'$$
);



