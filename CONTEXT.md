# AltaLux App SaaS (altalux.io) — Contexto del Proyecto
> Última actualización: 2026-08-10

## ¿Qué es esto?
Este repo es la **plataforma SaaS** — el producto que cualquier negocio de
detailing puede usar, distinto de AltaLux Mobile Detail (que es un negocio
real, con su propio repo `altalux-app`, dominio `altaluxdetail.com`, y su
propio proyecto de Supabase, sin relación con este). Este repo es un fork de
`altalux-app` en el commit `dfe2ffd` (2026-08-09), con el código
genericizado y una infraestructura 100% propia de acá en adelante.

**No comparte nada en producción con `altalux-app`:** ni base de datos, ni
Edge Functions, ni Resend, ni dominio. Un fix genérico útil para ambos se
porta a mano — no hay sincronización automática entre los dos repos.

## Stack
- Frontend: HTML/CSS/JS vanilla (idéntico patrón a `altalux-app`)
- Base de datos: Supabase project `bgbjrmkgjhjnvyffpxiu` (Postgres + Auth +
  Edge Functions), propio, sin relación con el de AltaLux Mobile Detail
  (`xmhsehfdmiqbwhpqjgon`)
- Pagos: Square — **bloqueado a propósito**, ver sección Pagos abajo
- Emails: Resend — **sin conectar todavía**, `RESEND_API_KEY` no está seteado
  (el usuario no tenía la cuenta lista al momento del deploy). `send-email`
  desplegada pero fallará en runtime hasta que se configure.
- Hosting: Hostinger, mismo hosting que ya servía `altalux.io` antes de esta
  separación (ver "Historia" abajo) — solo se reemplazó el contenido.

## Diseño y plan originales
- Spec: `docs/superpowers/specs/2026-08-09-saas-clone-separation-design.md`
  (vive en el repo `altalux-app`, no en este)
- Plan de implementación (con todas las amendments de lo que se encontró
  durante la ejecución real): `docs/superpowers/plans/2026-08-09-saas-clone-separation.md`
  (también en `altalux-app`)
- Ledger de progreso tarea-por-tarea: `altalux-app/.superpowers/sdd/progress.md`

## Historia — por qué existe este repo
`altalux.io` ya existía antes de este repo (ver
`/mnt/c/Users/ledua/OneDrive/Escritorio/AltaLux App SaaS/CONTEXT.md`, sesión
del 2026-08-08): el wizard de onboarding, el panel Super Admin y
`manage-tenant` se habían construido directo en `altalux-app`, compartiendo
el Supabase real de producción de AltaLux — documentado explícitamente ahí
como "separación organizacional únicamente, no de infraestructura". Este
repo es esa separación de infraestructura real, hecha el 2026-08-09/10.

## Credenciales
- **Super Admin** (`platform/index.html`): `altaluxtech@gmail.com` —
  identidad propia de la plataforma, **distinta** de
  `blisscleanmobilega@gmail.com` (que era el Super Admin del setup viejo
  compartido, sigue existiendo en el Supabase de AltaLux, ya no se usa acá).
  Password entregada al usuario en el chat de la sesión que hizo el deploy,
  no vive en ningún archivo de este repo.
- **Tenant demo** (`business_id = 'demo'`, sembrado permanente para
  pruebas/demos): owner `leduardo7777@gmail.com`. Password entregada al
  usuario en el chat, no vive en ningún archivo.
- **Secrets de Supabase** (`.secrets/supabase.env`, gitignored, solo existe
  en el filesystem donde se hizo el deploy): `PROJECT_REF`, `DB_PASSWORD`,
  `ANON_KEY`, `SERVICE_ROLE_KEY`. Si se pierde ese archivo, `ANON_KEY` se
  puede re-obtener con `supabase projects api-keys --project-ref
  bgbjrmkgjhjnvyffpxiu`, pero `DB_PASSWORD` no es recuperable — solo
  reseteable.

## Pagos — bloqueados a propósito
`SQUARE_ACCESS_TOKEN` está seteado a un valor dummy
(`unused-guard-blocks-all-charges`), nunca el token real de AltaLux. **Este
es el único mecanismo real que evita un cobro real** — los checks de
`business_id === 'altalux'` en el código (cliente y servidor) NO son
confiables por sí solos: `shared/config.js`'s `detectBusinessId()` acepta
cualquier `?b=` de la URL sin validar contra tenants reales, así que
visitar `?b=altalux` hace que el cliente arme una request con
`businessId: 'altalux'` que el guard del servidor deja pasar — verificado en
vivo durante el testing (Task 10, paso 4): con `businessId='altalux'` el
guard efectivamente no bloquea, pero la llamada real a Square falla (500)
porque el token es dummy. **Nunca poner un token real de Square acá** hasta
que exista Square OAuth por-tenant de verdad (fuera de alcance, fase
futura).

## Gaps conocidos / pendientes
- `RESEND_API_KEY` sin configurar — `send-email` fallará en runtime hasta
  que se setee. **Ojo:** esto es independiente del bug de las 4 emails de
  plataforma (`tenant_pending`/`tenant_approved`/`tenant_rejected`/
  `internal_new_signup`) que se encontró y arregló en la revisión final —
  esas ahora usan una identidad propia de plataforma (`PLATFORM_SETTINGS`
  en `send-email/index.ts`) en vez de depender de una fila `business_id =
  'altalux'` que ya no existe (y no debe existir) en este proyecto. Setear
  `RESEND_API_KEY` solo no alcanza — igual hace falta verificar
  `altalux.io` como dominio en Resend antes de que `noreply@altalux.io`
  (el remitente hardcodeado de `PLATFORM_SETTINGS`) pueda mandar algo real.
- Logo neutral: `pay/index.html`, el modal de invoice de `admin/index.html`,
  y el visor de invoice siguen usando `brand/altalux-logo-color.png` como
  imagen — no existe todavía un asset neutral. El texto/contacto alrededor
  sí se limpió (ver Fixes recientes).
- Nombre de marca de la plataforma sin decidir — los `<title>` de
  `platform/index.html`, `onboarding/index.html`, `technician/index.html`,
  `admin/index.html` siguen diciendo "AltaLux App"/"AltaLux Admin"/etc.
  porque nada en el proyecto estableció un nombre nuevo todavía.
- Password por defecto de empleado nuevo (`admin/index.html`, cuando el
  owner no pone una) sigue siendo `'altalux2026'` — no cambiado, necesita
  una decisión de producto (¿password random forzando reset? ¿flujo de
  invitación?).
- 2 tenants de prueba viejos (`test-detailing-co`, `resume-test-detailing`)
  y el Super Admin viejo (`blisscleanmobilega@gmail.com` /
  `TempSuperAdmin2026!`) siguen en el Supabase de AltaLux Mobile Detail
  (`xmhsehfdmiqbwhpqjgon`) — datos huérfanos del setup compartido anterior,
  ya no alcanzables vía `altalux.io` (que ahora sirve este repo), pero
  todavía viven ahí. Limpieza pendiente, fuera de alcance de este repo.

## Fixes recientes
- **2026-08-10 (revisión final del clon):** una revisión final de todo el
  trabajo (después de que cada tarea individual ya había pasado su propia
  revisión) encontró 2 problemas reales que ninguna revisión por-tarea
  podía ver por sí sola:
  - **Crítico:** las 4 emails de onboarding de plataforma
    (`tenant_pending`/`tenant_approved`/`tenant_rejected`/
    `internal_new_signup`) dependían de una fila `business_id = 'altalux'`
    en `business_settings` que la migración de purga (2026-08-10, más
    arriba) borra a propósito — el diseño original (heredado del setup
    compartido viejo) nunca contempló que esa fila pudiera no existir.
    `manage-tenant` no revisaba el resultado del fetch a `send-email`, así
    que el fallo quedaba invisible — ni Task 10 (que sí verificó los 4
    pasos de datos de `approve_tenant`) lo detectó, porque el 5to paso (el
    email) no es parte de esa verificación. Arreglado: `send-email/index.ts`
    ahora usa `PLATFORM_SETTINGS`, una identidad de plataforma fija que no
    depende de ninguna fila de tenant.
  - **Crítico:** `internal_new_signup` (notificación de "nuevo negocio se
    registró") mandaba al inbox real de AltaLux Mobile Detail
    (`altaluxdetail@gmail.com`) — corregido a `altaluxtech@gmail.com` (la
    identidad de Super Admin de esta plataforma).
  - Limpiadas fugas adicionales de la misma clase que Tasks 5/6 no habían
    tocado: fallback de `name`/dirección en `generate-receipt-pdf` y
    `send-email`, wordmark + teléfono real de AltaLux en
    `booking/success.html` y en el mensaje de error de pago de
    `booking/index.html`, email de contacto en `terms.html`/`privacy.html`
    (nunca estuvieron en el alcance de ninguna tarea — no eran parte del
    deploy de AltaLux, así que ninguna auditoría los había mirado), y el
    catálogo de fallback (`FALLBACK_SERVICES`/`FALLBACK_ADDONS` en
    `shared/config.js`) seguía etiquetado `business_id: 'altalux'` en vez
    de `'demo'`.
- **2026-08-10 (deploy inicial):** clon completo de `altalux-app` (commit
  `dfe2ffd`) a infraestructura 100% propia — repo, Supabase, Edge
  Functions, Hostinger (mismo hosting que ya servía `altalux.io`, contenido
  reemplazado). En el camino:
  - Reconstruida la migración base de 8 tablas core (`bookings`,
    `customers`, `jobs`, `payments`, `invoices`, `vehicles`, `job_addons`,
    `job_vehicles`) que nunca existieron como migración en `altalux-app`
    (creadas directo en el SQL Editor antes de que ese repo adoptara
    migraciones) — sin esto, `supabase db push` contra un proyecto nuevo
    fallaba de entrada.
  - Encontrado y arreglado un bug de grants: un reset de schema durante el
    testing destruyó los `ALTER DEFAULT PRIVILEGES` de Supabase, dejando
    `anon`/`authenticated`/`service_role` sin acceso a nada — RLS perfecto
    pero inalcanzable. Corregido, documentado en el plan para no repetirlo.
  - Encontradas y limpiadas varias fugas reales de datos de AltaLux hacia
    otros tenants (contacto/dirección en invoices, footers estáticos del
    booking widget y de `pay/index.html`, 2 empleados reales con
    email/teléfono reales que se habían colado en el clon).
  - 6 archivos HTML (`booking`, `admin`, `technician`, `pay`, `onboarding`,
    más `platform` ya en el alcance original) tenían su propia copia
    hardcodeada de la conexión a Supabase, apuntando todavía al proyecto
    viejo — corregido en los 6.
  - Verificado end-to-end con navegador real: wizard de onboarding
    completo, aprobación como Super Admin, flujo admin (cliente + job),
    guard de pagos, asignación y login de técnico, cero cruce de datos
    entre los dos Supabase. Ver
    `altalux-app/.superpowers/sdd/progress.md` para el detalle completo
    tarea-por-tarea.

## Estructura de Carpetas
Idéntica a `altalux-app` (ver ese repo para la estructura completa) — este
repo es un fork directo, sin reorganización de archivos.
