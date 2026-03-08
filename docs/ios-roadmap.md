# PetLog iOS — Roadmap & Arquitectura

> Plan maestro para la app nativa iOS de PetLog.
> El mismo Supabase backend que usa la web. Un usuario, todos sus datos, en ambas plataformas.

---

## Estado actual

| Plataforma | Estado |
|---|---|
| Web (Astro + Supabase + Vercel) | Funcional — MVP completo |
| iOS (React Native / Expo) | Por construir |
| Backend API | Supabase (compartido) |
| Auth | Supabase Auth — email + Google OAuth |

---

## Stack iOS elegido: Expo + React Native

### Por qué Expo (y no Swift nativo ni Flutter)

| Criterio | Expo/RN | Swift nativo | Flutter |
|---|---|---|---|
| Reusar lógica de negocio (vitality score, badges, utils) | SI — mismo TS | No | No |
| Reusar tipos Supabase | SI — mismo `supabase.ts` | No | No |
| Un solo equipo / desarrollador | SI | No | Parcial |
| Velocidad de desarrollo | Alta | Baja | Media |
| Acceso a APIs nativas (cámara, notificaciones push) | SI via Expo SDK | Total | SI |
| App Store compliance | SI — Expo EAS Build | SI | SI |
| Actualizaciones OTA (sin App Store review) | SI — Expo Updates | No | No |
| Calidad UI "Apple-proof" | SI con cuidado | Total | Parcial |

**Decisión: Expo (managed workflow) + EAS Build + EAS Update.**

La app web y la app iOS comparten:
- El mismo proyecto Supabase (misma DB, mismo Auth, mismo Storage)
- Los tipos TypeScript de `src/types/supabase.ts`
- La lógica de `vitality-score.ts`, `breed-data.ts`, `utils.ts`, `badges.ts`
- Las constantes de `constants.ts`

---

## Arquitectura del repositorio

```
petlog/                          ← repositorio actual (web)
petlog-mobile/                   ← NUEVO repositorio iOS
  ├── app/                       ← Expo Router (file-based routing)
  │   ├── (auth)/
  │   │   ├── login.tsx
  │   │   ├── register.tsx
  │   │   └── forgot-password.tsx
  │   ├── (app)/
  │   │   ├── _layout.tsx        ← Tab bar principal
  │   │   ├── index.tsx          ← Dashboard (Home tab)
  │   │   ├── salud/
  │   │   │   ├── index.tsx      ← Vitality Score
  │   │   │   ├── vacunas.tsx
  │   │   │   ├── peso.tsx
  │   │   │   └── historial.tsx
  │   │   ├── alimentacion.tsx
  │   │   ├── viajes.tsx
  │   │   ├── notificaciones.tsx
  │   │   └── perfil.tsx
  │   └── _layout.tsx            ← Root layout (auth guard)
  ├── components/
  │   ├── ui/                    ← Design system atoms
  │   │   ├── Card.tsx
  │   │   ├── Button.tsx
  │   │   ├── Badge.tsx
  │   │   ├── ScoreCircle.tsx
  │   │   └── PillSelector.tsx
  │   ├── pet/
  │   │   ├── PetHeroCard.tsx
  │   │   ├── VitalityWidget.tsx
  │   │   └── FoodProgressBar.tsx
  │   └── shared/
  │       ├── LoadingScreen.tsx
  │       └── EmptyState.tsx
  ├── lib/                       ← Lógica compartida (symlink o copia de web)
  │   ├── supabase.ts            ← Cliente Supabase para RN
  │   ├── vitality-score.ts      ← MISMO archivo que la web
  │   ├── breed-data.ts          ← MISMO archivo que la web
  │   ├── badges.ts              ← MISMO archivo que la web
  │   └── utils.ts               ← MISMO archivo que la web
  ├── hooks/
  │   ├── useAuth.ts
  │   ├── usePet.ts
  │   ├── useVitality.ts
  │   └── useNotifications.ts
  ├── store/
  │   └── petStore.ts            ← Zustand (estado global liviano)
  ├── types/
  │   └── supabase.ts            ← MISMO archivo que la web
  ├── constants/
  │   └── theme.ts               ← Colores, tipografía, espaciados
  ├── assets/
  │   ├── badges/                ← Mismas imágenes de badges
  │   └── icons/
  ├── app.json                   ← Config Expo
  ├── eas.json                   ← Config EAS Build/Submit
  └── package.json
```

---

## Design system iOS

Colores (igual que la web, adaptados a RN):

```typescript
export const Colors = {
  accent: '#F97316',
  accentDark: '#EA580C',
  accentLight: '#FFF7ED',
  ink: '#0F1117',
  muted: '#6B7280',
  canvas: '#F7F8FA',
  card: '#FFFFFF',
  cardBorder: '#EAECF0',
  sidebar: '#13161C',
  // Health semantic colors
  good: '#22C55E',
  warn: '#F59E0B',
  bad: '#EF4444',
};

export const Spacing = { xs: 4, sm: 8, md: 16, lg: 24, xl: 32, xxl: 48 };
export const Radius = { sm: 8, md: 12, lg: 16, xl: 20, full: 999 };
```

Tipografía: **SF Pro** (sistema iOS, sin importar nada).

Navegación: Tab bar con 5 tabs: Inicio, Salud, Comida, Viajes, Perfil.

---

## Requisitos Apple App Store (checklist obligatorio)

### Técnicos
- [ ] Privacy Manifest (`PrivacyInfo.xcprivacy`) — requerido desde mayo 2024
- [ ] App Tracking Transparency (ATT) — si se usa analytics
- [ ] App Privacy Nutrition Label en App Store Connect
- [ ] No uso de APIs privadas
- [ ] Soporte iOS 16+ mínimo
- [ ] Universal (iPhone + iPad)
- [ ] Dark Mode support
- [ ] Dynamic Type / Accessibility labels
- [ ] Localización: español (es) como principal, inglés (en) como fallback

### Privacidad y datos
- [ ] Privacy Policy URL pública (ej: petlog.app/privacy)
- [ ] Terms of Service URL pública (ej: petlog.app/terms)
- [ ] GDPR / datos del usuario: solo datos de mascotas, no datos sensibles de personas
- [ ] Fotos de mascotas: uso claramente declarado en Privacy Nutrition Label
- [ ] Cámara: solo para fotos de mascotas (NSCameraUsageDescription)
- [ ] Fotos: para seleccionar foto de mascota (NSPhotoLibraryUsageDescription)
- [ ] Notificaciones: push opcional para recordatorios (NSUserNotificationsUsage)

### Pagos y premium
- [ ] Si hay features de pago: OBLIGATORIO usar In-App Purchase (no Stripe directo)
- [ ] Apple se lleva 15-30% de subscripciones
- [ ] Freemium base + IAP para premium = cumple guidelines
- [ ] RevenueCat para gestionar IAP de forma profesional

### Categoría App Store
- **Categoría primaria**: Health & Fitness
- **Categoría secundaria**: Lifestyle
- Esto maximiza descubrimiento orgánico en App Store

---

## Antes de empezar a codear: Fundamentos a resolver

### 1. Cuenta Apple Developer Program
- Costo: $99 USD/año
- Registrar en: developer.apple.com
- Necesario para: TestFlight, App Store, Push Notifications

### 2. App Store Connect
- Crear el app record: "PetLog"
- Bundle ID: `com.petlog.app`
- SKU: `petlog-ios-v1`

### 3. Privacy Policy y Terms of Service (OBLIGATORIOS para App Store)
- Crear páginas en la web: `/privacy` y `/terms`
- Contenido mínimo requerido por Apple

### 4. Supabase — cambios de backend necesarios

```sql
-- Tabla de push tokens para notificaciones push nativas
CREATE TABLE push_tokens (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  token TEXT NOT NULL,
  platform TEXT NOT NULL DEFAULT 'ios', -- 'ios' | 'android'
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, token)
);

-- RLS
ALTER TABLE push_tokens ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users manage own tokens" ON push_tokens
  USING (user_id = auth.uid())
  WITH CHECK (user_id = auth.uid());

-- Tabla de referidos (también necesaria para web)
CREATE TABLE referral_codes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  code TEXT NOT NULL UNIQUE,
  uses_count INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE referrals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  referrer_id UUID NOT NULL REFERENCES auth.users(id),
  referred_id UUID NOT NULL REFERENCES auth.users(id) UNIQUE,
  code TEXT NOT NULL,
  status TEXT DEFAULT 'pending', -- 'pending' | 'completed' | 'rewarded'
  reward_granted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tabla de subscripciones / premium status
CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
  plan TEXT NOT NULL DEFAULT 'free', -- 'free' | 'premium'
  source TEXT, -- 'referral' | 'iap' | 'promo'
  premium_until TIMESTAMPTZ,
  trial_ends_at TIMESTAMPTZ,
  iap_product_id TEXT, -- RevenueCat product ID
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS
ALTER TABLE user_subscriptions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own subscription" ON user_subscriptions
  FOR SELECT USING (user_id = auth.uid());
```

### 5. Google OAuth — configurar para mobile
- En Google Cloud Console, agregar:
  - iOS Bundle ID: `com.petlog.app`
  - URL Scheme: `com.petlog.app` (para deep link de callback)
- Supabase ya soporta esto, solo hay que agregar el Bundle ID

### 6. Supabase Storage buckets existentes
- Verificar que el bucket `pet-photos` tenga políticas correctas
- Agregar bucket `pet-docs` para documentos de viaje

---

## Roadmap por fases

---

### FASE 0 — Fundamentos (hacer ANTES de codear)
**Objetivo: Todo lo que Apple y Supabase necesitan listo.**

- [ ] 0.1 — Registrar Apple Developer Program ($99)
- [ ] 0.2 — Crear app en App Store Connect (Bundle ID: com.petlog.app)
- [ ] 0.3 — Crear página `/privacy` en la web (requerida por Apple)
- [ ] 0.4 — Crear página `/terms` en la web (requerida por Apple)
- [ ] 0.5 — Ejecutar SQL de nuevas tablas en Supabase (push_tokens, referrals, user_subscriptions)
- [ ] 0.6 — Configurar Google OAuth para iOS (agregar Bundle ID en Google Cloud Console)
- [ ] 0.7 — Crear cuenta en Expo (expo.dev) y configurar EAS
- [ ] 0.8 — Decidir nombre final del app para App Store y crear los assets del ícono

---

### FASE 1 — Scaffold y autenticación
**Objetivo: App funciona, el usuario puede loguearse con la misma cuenta de la web.**

- [ ] 1.1 — Inicializar proyecto Expo con TypeScript + Expo Router
- [ ] 1.2 — Configurar cliente Supabase para React Native (`@supabase/supabase-js` + AsyncStorage)
- [ ] 1.3 — Auth guard (root `_layout.tsx`) — si no hay sesión → pantalla login
- [ ] 1.4 — Pantalla Login: email/password + Google OAuth (misma cuenta web)
- [ ] 1.5 — Pantalla Register: email/password (con validación)
- [ ] 1.6 — Deep link handler para OAuth callback (`com.petlog.app://auth/callback`)
- [ ] 1.7 — Forgot password flow
- [ ] 1.8 — Onboarding básico (nombre de mascota — si no tiene mascotas)
- [ ] 1.9 — Design system base: Colors, Typography, Spacing, Button, Card, LoadingScreen
- [ ] 1.10 — Tab bar con 5 tabs (icons SF Symbols)

---

### FASE 2 — Dashboard y Vitality Score
**Objetivo: La pantalla principal con toda la info de la mascota.**

- [ ] 2.1 — PetHeroCard (foto, nombre, raza, edad, peso)
- [ ] 2.2 — Vitality Score circle + barras de pilares (reusar lógica de `vitality-score.ts`)
- [ ] 2.3 — Widget de comida (progreso de la bolsa, días restantes)
- [ ] 2.4 — Cards de recordatorios (antipulgas, desparasitante)
- [ ] 2.5 — Pull-to-refresh
- [ ] 2.6 — Fun fact del día (reusar `breed-data.ts`)
- [ ] 2.7 — Selector de mascota activa (si tiene varias)
- [ ] 2.8 — Skeleton loading states

---

### FASE 3 — Salud (vacunas, peso, historial vet)
**Objetivo: Todo el módulo de salud funcional.**

- [ ] 3.1 — Pantalla Salud con el score completo (5 pilares, flags)
- [ ] 3.2 — Lista de vacunas con badges (reusar imágenes de `/public/badges/`)
- [ ] 3.3 — Agregar vacuna (bottom sheet form)
- [ ] 3.4 — Gráfica de peso (react-native-svg o Victory Native)
- [ ] 3.5 — Agregar registro de peso
- [ ] 3.6 — Lista de visitas al veterinario
- [ ] 3.7 — Agregar visita veterinaria
- [ ] 3.8 — Historial de groomings

---

### FASE 4 — Alimentación
**Objetivo: Control de dieta e inventario.**

- [ ] 4.1 — Card de comida activa con barra de progreso
- [ ] 4.2 — Agregar/editar comida (soporte BARF, mixto, kibble)
- [ ] 4.3 — Calculadora de porción diaria
- [ ] 4.4 — Historial de comidas

---

### FASE 5 — Notificaciones push nativas
**Objetivo: La app avisa cuando hay algo importante.**

- [ ] 5.1 — Configurar Expo Notifications + APNs (Apple Push Notification Service)
- [ ] 5.2 — Guardar push token en tabla `push_tokens` de Supabase
- [ ] 5.3 — Supabase Edge Function para enviar notificaciones push
- [ ] 5.4 — Triggers automáticos: antipulgas/desparasitante próximo (3 días antes)
- [ ] 5.5 — Trigger: comida por acabarse (≤5 días)
- [ ] 5.6 — Notificación de cumpleaños de la mascota
- [ ] 5.7 — Centro de notificaciones in-app (igual que la web)

---

### FASE 6 — Viajes y pasaporte
**Objetivo: Módulo de viajes completo.**

- [ ] 6.1 — Lista de vuelos registrados
- [ ] 6.2 — Agregar vuelo con checklist de documentos
- [ ] 6.3 — Vista "Pasaporte" en PDF-style (compartible)
- [ ] 6.4 — Share pasaporte como imagen (Share Sheet de iOS)

---

### FASE 7 — Perfil, ajustes y referidos
**Objetivo: Configuración de cuenta y sistema de referidos.**

- [ ] 7.1 — Pantalla de perfil con foto de mascota editable
- [ ] 7.2 — Selector de tema de color (6 colores)
- [ ] 7.3 — Código de referido personal con botón "Compartir"
- [ ] 7.4 — Estadísticas de referidos (cuántos amigos traje, cuánto premium gané)
- [ ] 7.5 — Logout

---

### FASE 8 — Premium e In-App Purchase (IAP)
**Objetivo: Monetización que cumple con Apple.**

- [ ] 8.1 — Integrar RevenueCat SDK
- [ ] 8.2 — Crear productos en App Store Connect:
  - `petlog_premium_monthly` — $2.99/mes
  - `petlog_premium_yearly` — $19.99/año
- [ ] 8.3 — Paywall screen (diseño "Apple-proof")
- [ ] 8.4 — Gates de features premium (máx 2 mascotas en free, etc.)
- [ ] 8.5 — Restore purchases
- [ ] 8.6 — Webhook RevenueCat → Supabase (actualizar `user_subscriptions`)

---

### FASE 9 — Pulido y App Store submission
**Objetivo: Pasar review de Apple a la primera.**

- [ ] 9.1 — Privacy Manifest (`PrivacyInfo.xcprivacy`)
- [ ] 9.2 — App icon en todos los tamaños (1024x1024 base, Expo genera el resto)
- [ ] 9.3 — Launch Screen (Splash screen)
- [ ] 9.4 — Screenshots para App Store (6.7" iPhone 16 Pro Max, 6.5" iPhone 14 Plus, iPad)
- [ ] 9.5 — App Store description en español + inglés
- [ ] 9.6 — Keywords research y optimización ASO
- [ ] 9.7 — TestFlight beta (amigos + familia)
- [ ] 9.8 — Responder review de Apple
- [ ] 9.9 — Launch en App Store

---

## Librerías clave del proyecto iOS

```json
{
  "expo": "~52.x",
  "expo-router": "~4.x",
  "expo-notifications": "para APNs",
  "expo-image-picker": "para fotos de mascotas",
  "expo-sharing": "para compartir pasaporte",
  "expo-updates": "para OTA updates sin App Store review",
  "@supabase/supabase-js": "mismo que la web",
  "@react-native-async-storage/async-storage": "para sesión Supabase en RN",
  "zustand": "estado global liviano",
  "react-native-reanimated": "animaciones fluidas 60fps",
  "react-native-gesture-handler": "gestos nativos",
  "react-native-svg": "para gráficas y score circle",
  "victory-native": "para gráfica de peso",
  "react-native-purchases": "RevenueCat para IAP"
}
```

---

## Estructura de datos compartida Web + iOS

```
Supabase (backend único)
├── auth.users           ← misma cuenta, funciona en web y en app
├── pets                 ← se ven en ambas plataformas en tiempo real
├── vaccines             ← idem
├── vet_visits           ← idem
├── weight_records       ← idem
├── groomings            ← idem
├── foods                ← idem
├── flights              ← idem
├── adventures           ← idem
├── preventive_treatments← idem
├── notifications        ← compartidas (generadas en web, leídas en app y vice versa)
├── push_tokens          ← solo iOS/Android
├── referral_codes       ← compartidas
├── referrals            ← compartidas
└── user_subscriptions   ← compartidas (premium en web = premium en app)
```

---

## Qué hacer primero (esta semana)

**Antes de escribir una sola línea de Swift o React Native:**

1. **Crear páginas `/privacy` y `/terms` en la web** — Apple las revisa antes de aprobar la app
2. **Ejecutar el SQL** de las nuevas tablas en Supabase (push_tokens, referrals, user_subscriptions)
3. **Registrar Apple Developer Program** si no está hecho
4. **Crear el App Record** en App Store Connect con Bundle ID `com.petlog.app`

Solo con eso en orden, el scaffold de la app puede empezar sin bloqueos.

---

## Preguntas a responder antes de fase 1

- [ ] ¿El nombre en App Store será "PetLog" exacto? (verificar disponibilidad)
- [ ] ¿Primero solo iPhone o también iPad desde el inicio?
- [ ] ¿El premium de la app web también se gestiona con RevenueCat, o queda como pago directo (Stripe)?
- [ ] ¿Habrá Android también, o solo iOS por ahora?

---

*Última actualización: Marzo 2026*
