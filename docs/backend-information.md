

# MineGuard Platform — Backend Integration Contract

**Versión del documento:** 2.4
**Alcance:** Contrato oficial de integración del backend de MineGuard Platform, post-migración a arquitectura RESTful, post-remediación de aislamiento multi-tenant, post-alineación terminológica DDD (Driving Sessions) con exportación de documentos (PDF/Excel), post-pulido de semántica HTTP estricta (PATCH real, paginación obligatoria, retornos exactos, y códigos de estado correctos), post-mejoras finales de calidad (respuestas estructuradas, proyecciones singulares exactas, y prevención de creación de conductores por la vía genérica de sign-up), post-implementación del ciclo de vida completo de la Driving Session (check-out, concurrencia de conductores, y máquina de estados del vehículo), y **post-incorporación del ciclo de vida de Devices/Sensores** (aprovisionamiento del device unificado MineGuard 1:1 con el vehículo, secuencia de `deviceId` por empresa, reasignación y retiro, soft-delete de conductores y vehículos, `reportId` en el histórico analítico, y afinado del pipeline de telemetría edge — umbral de proximidad y persistencia de muestras).
**Audiencia:** Equipos de Frontend (Web), Mobile (Flutter), y Hardware/Firmware (Edge/IoT).
**Base URL:** `https://<host>/api/v1` (todas las rutas de este documento se listan relativas a este prefijo, salvo que se indique lo contrario).
**Base de datos:** este documento asume un despliegue con base de datos limpia — no existen rutas heredadas ni consideraciones de compatibilidad hacia atrás.

---

## Índice

1. [Diccionario de Endpoints RESTful (por Bounded Context)](#1-diccionario-de-endpoints-restful-por-bounded-context)
   - 1.1 [IAM & Sessions](#11-iam--sessions)
   - 1.2 [Assets Core](#12-assets-core)
   - 1.3 [Monitoring](#13-monitoring)
   - 1.4 [Companies & Analytics](#14-companies--analytics)
   - 1.5 [Devices & Sensors (Provisioning)](#15-devices--sensors-provisioning)
   - 1.6 [Platform (Cross-Tenant)](#16-platform-cross-tenant)
2. [Arquitectura, Seguridad y Estándares](#2-arquitectura-seguridad-y-estándares)
3. [Manifiesto de Integración Edge / Embedded (IoT)](#3-manifiesto-de-integración-edge--embedded-iot)

---

## 1. Diccionario de Endpoints RESTful (por Bounded Context)

### 1.1 IAM & Sessions

Gestión de identidad, sesiones y directorio de supervisores.

#### `POST /sessions`
- **Descripción y Reglas de Negocio:** Autentica a un usuario web (Supervisor o Admin) por `username`/`password` y emite un JWT firmado sin expiración server-side (la revocación se maneja vía cambio de contraseña). Las credenciales inválidas devuelven `401` sin distinguir si falló el usuario o la contraseña (mitigación de enumeración de usuarios).
- **I/O:**
  - **Body (`SignInResource`):** `username` (string), `password` (string).
  - **Retorna:** `200 OK` con `AuthenticatedUserResource` (`id`, `username`, `token`, `role`, `requiresPasswordChange`, `subscriptionPlan`). `subscriptionPlan` (string) es el plan descriptivo de la empresa vinculada al usuario (`STARTER`/`STANDARD`/`ENTERPRISE`); es `STANDARD` por defecto para empresas sin plan asignado. `401` si las credenciales son inválidas.

#### `POST /mobile-sessions`
- **Descripción y Reglas de Negocio:** Autentica a un operador de campo por `workerId` (formato `CDT-{companyId}-{seq}`, generado al crear el Driver) en lugar de email. Resuelve adicionalmente el `driverId` numérico (cruce IAM → Assets) para que la app móvil pueda hacer check-in inmediato en una Driving Session sin una segunda petición.
- **I/O:**
  - **Body (`MobileSignInResource`):** `workerId` (string), `password` (string).
  - **Retorna:** `200 OK` con `MobileAuthenticatedUserResource` (`workerId`, `fullName`, `role`, `token`, `driverId` — `null` para usuarios no-conductor). `401` credenciales inválidas. `403` cuenta deshabilitada o suscripción de la empresa inactiva.

#### `POST /users`
- **Descripción y Reglas de Negocio:** Registro de un usuario (`sign-up`). El rol depende del campo `roles` del body. **Rechazo activo de "usuarios fantasma":** si `roles` contiene `DRIVER` (o `ROLE_DRIVER`), la petición se rechaza con `400` antes de tocar el servicio de aplicación — las cuentas de conductor **deben** crearse vía `POST /drivers`, que además aprovisiona el agregado de dominio `Driver` (no solo la identidad IAM) requerido para check-in de Driving Sessions y vinculación de telemetría. No emite JWT — el cliente debe autenticarse después vía `POST /sessions`.
- **I/O:**
  - **Body (`SignUpResource`):** `username`, `password`, `email`, `fullName` (strings), `roles` (lista de strings, opcional).
  - **Retorna:** `201 Created` con `UserResource` (`id`, `username`). `400` si `roles` incluye `DRIVER`/`ROLE_DRIVER`. `409` si el email ya está registrado.

#### `POST /password-resets`
- **Descripción y Reglas de Negocio:** Solicita el restablecimiento de contraseña por email. Siempre responde `200 OK` exista o no el email, para prevenir enumeración de cuentas.
- **I/O:**
  - **Body (`ForgotPasswordRequest`):** `email` (string, requerido, formato email).
  - **Retorna:** `200 OK` (mensaje genérico, idéntico en ambos casos).

#### `PATCH /users/me/password`
- **Descripción y Reglas de Negocio:** Cambio de contraseña del usuario autenticado. PATCH (no PUT) porque solo se reemplaza el campo `password`; el poseer un JWT válido se considera prueba de identidad suficiente (no se exige la contraseña actual). Limpia el flag `requiresPasswordChange`.
- **I/O:**
  - **Header:** `Authorization: Bearer <token>` (requerido).
  - **Body (`ChangePasswordResource`):** `newPassword` (string, requerido, mínimo 8 caracteres).
  - **Retorna:** `200 OK` con `UserResource`. `401` si el JWT es inválido/expirado.

#### `GET /supervisors`
- **Descripción y Reglas de Negocio:** Lista los supervisores (`role=SUPERVISOR`) de la empresa autenticada. Filtrado estrictamente por `companyId` del JWT.
- **I/O:**
  - **Retorna:** `200 OK` con `List<SupervisorResource>` (`id`, `fullName`, `corporateId`, `email`, `accessStatus`).

#### `POST /supervisors`
- **Descripción y Reglas de Negocio:** Crea una cuenta de supervisor bajo la empresa autenticada (`companyId` resuelto exclusivamente desde el JWT, nunca desde el body). Genera username y contraseña temporal server-side y envía las credenciales por correo. `requiresPasswordChange=true` en la primera respuesta de login. **El esquema no acepta `username`/`password` en absoluto** — aceptarlos y descartarlos silenciosamente violaría el principio fail-fast; el DTO está anotado `@JsonIgnoreProperties(ignoreUnknown = false)`, así que enviar cualquier campo no reconocido (incluidos `username`/`password`) es rechazado con `400`.
- **I/O:**
  - **Body (`CreateSupervisorResource`):** `fullName` (requerido), `corporateId` (requerido), `email` (opcional, formato email). Ningún otro campo es aceptado.
  - **Retorna:** `201 Created` con `SupervisorResource`. `409` si `corporateId` ya existe. `400` si el body incluye una propiedad no reconocida.

#### `PATCH /supervisors/{supervisorId}`
- **Descripción y Reglas de Negocio:** Actualización parcial del perfil del supervisor: cualquier subconjunto de campos editables puede enviarse; los omitidos conservan su valor (semántica PATCH real — antes se exponía como `PUT` con esa misma semántica, lo cual violaba el estándar REST). Ownership (`companyId` del supervisor vía su `User` vinculado) se valida antes de mutar. Los cambios de contraseña **no** se manejan aquí (usar `PATCH /users/me/password`).
- **I/O:**
  - **Path:** `{supervisorId}` (Long, requerido).
  - **Body (`UpdateSupervisorResource`, todos opcionales):** `fullName`, `corporateId`, `email`, `username`, `password`, `accessStatus`.
  - **Retorna:** `200 OK` con `SupervisorResource`. `404` si no existe o no pertenece al tenant.

---

### 1.2 Assets Core

Gestión de la flota (vehículos), directorio de conductores, y **Driving Sessions** (turnos activos). En un contexto minero, un operador no hace un "viaje" — abre una **sesión de conducción**. Esta terminología reemplaza por completo el término "Trip" en la capa de API; el modelo de persistencia subyacente no cambió.

#### `GET /drivers`
- **Descripción y Reglas de Negocio:** Lista los conductores de la empresa autenticada. Soporta modificadores de query ortogonales: `sort=-riskScore` reordena por score de riesgo descendente (derivado de `PerformanceMetric`); `limit=N` acota el tamaño del resultado. **Ordenar nunca muta la proyección:** con o sin `sort`, el `DriverResource` devuelto siempre trae todos sus campos poblados de la misma forma — `sort=-riskScore` únicamente cambia el orden (y, combinado con `limit`, la cantidad) de los elementos, nunca su forma. **Los conductores desactivados (`shiftStatus=INACTIVE`, ver `DELETE /drivers/{driverId}`) se excluyen por defecto**; pasar `includeInactive=true` los incluye para auditoría.
- **I/O:**
  - **Query:** `view` (string, opcional, `directory`), `sort` (string, opcional, `-riskScore`), `limit` (int, opcional), `includeInactive` (bool, opcional, default `false`).
  - **Retorna:** `200 OK` con `List<DriverResource>` completo (`id`, `fullName`, `operatorId`, `license`, `specialty`, `shiftStatus`, `lastAccess`, `riskScore`) en ambos casos.

#### `GET /drivers/{driverId}`
- **Descripción y Reglas de Negocio:** Perfil completo de un conductor. Debe pertenecer a la empresa autenticada; ownership se valida en la capa de query service.
- **I/O:**
  - **Path:** `{driverId}` (Long).
  - **Retorna:** `200 OK` con `DriverResource`. `404` si no existe o no pertenece al tenant.

#### `POST /drivers`
- **Descripción y Reglas de Negocio:** Registra un conductor bajo la empresa autenticada (`companyId` resuelto exclusivamente desde el JWT). Crea internamente un `User` con `role=DRIVER` y genera el `workerId` (formato `CDT-{companyId}-{seq}`) y una contraseña temporal, ambos server-side. **El esquema no acepta `username`/`password` en absoluto** — el DTO está anotado `@JsonIgnoreProperties(ignoreUnknown = false)`, así que cualquier campo no reconocido (incluidos `username`/`password`) es rechazado con `400`.
- **I/O:**
  - **Body (`CreateDriverResource`):** `fullName` (requerido), `licenseNumber` (requerido), `email` (opcional, formato email), `workShift` (opcional). Ningún otro campo es aceptado.
  - **Retorna:** `201 Created` con `DriverResource`. `400` si el body incluye una propiedad no reconocida.

#### `PATCH /drivers/{driverId}`
- **Descripción y Reglas de Negocio:** Actualización parcial del perfil del conductor (antes expuesta incorrectamente como `PUT` pese a ya tener semántica de partial-update). Ownership (`companyId`) validado antes de mutar. Cada campo es **independientemente opcional** — omitirlo conserva su valor actual.
- **I/O:**
  - **Path:** `{driverId}` (Long).
  - **Body (`UpdateDriverResource`, todos opcionales):** `username`, `password` [mín. 6], `email`, `fullName`, `licenseNumber`, `workShift`.
  - **Retorna:** `200 OK` con `DriverResource`. `404` si no existe o no pertenece al tenant.

#### `DELETE /drivers/{driverId}`
- **Descripción y Reglas de Negocio:** **Desactivación (soft-delete) del conductor** — no es un borrado físico. El conductor se marca `shiftStatus=INACTIVE`, preservando íntegramente su histórico de reportes y Driving Sessions. A partir de ahí queda excluido del directorio por defecto (recuperable en `GET /drivers?includeInactive=true`). Ownership (`companyId` del JWT) validado antes de mutar. Requiere rol `ADMINISTRATOR` o `SUPERVISOR`.
- **I/O:**
  - **Path:** `{driverId}` (Long).
  - **Retorna:** `204 No Content` (cuerpo vacío). `404` si no existe o no pertenece al tenant. `403` si el rol no es Administrador/Supervisor.

#### `GET /vehicles`
- **Descripción y Reglas de Negocio:** Lista los vehículos de la flota de la empresa autenticada. `view=inventory` devuelve el payload administrativo enriquecido; omitir `view` devuelve el payload compacto de selección móvil. Cada vehículo incluye el `deviceId` del device MineGuard vinculado (o `null` si no tiene device; un device en estado `retired` no cuenta como vinculado) — alimenta el filtro de inventario "sin device" y el chip de device por fila. **Los vehículos archivados (dados de baja, ver `DELETE /vehicles/{vehicleId}`) se excluyen por defecto**; pasar `includeArchived=true` los incluye para auditoría.
- **I/O:**
  - **Query:** `view` (string, opcional, `inventory`), `includeArchived` (bool, opcional, default `false`).
  - **Retorna:** `200 OK` con `List<VehicleResource>` (`id`, `code`, `model`, `category`, `status`, `assignedDriverName`, `shiftLabel`, `deviceId`).

#### `POST /vehicles`
- **Descripción y Reglas de Negocio:** Registra un vehículo en la flota. Queda disponible inmediatamente para check-in vía `POST /vehicles/{vehicleId}/driving-sessions`. `status` por defecto es `OPERATIONAL` si se omite.
- **I/O:**
  - **Body (`CreateVehicleResource`):** `code`, `model`, `category` (requeridos); `status`, `assignedDriverName`, `shiftLabel` (opcionales).
  - **Retorna:** `201 Created` con `VehicleResource`.

#### `PATCH /vehicles/{vehicleId}`
- **Descripción y Reglas de Negocio:** Actualización parcial del registro del vehículo (antes expuesta incorrectamente como `PUT`, y `Vehicle.updateInformation` sobrescribía `code`/`model`/`category` incondicionalmente incluso si el cliente los omitía — corregido: ahora todo campo omitido conserva su valor actual). Ownership validado antes de mutar.
- **I/O:**
  - **Path:** `{vehicleId}` (Long).
  - **Body (`UpdateVehicleResource`, todos opcionales):** `code`, `model`, `category`, `status`, `assignedDriverName`, `shiftLabel`.
  - **Retorna:** `200 OK` con `VehicleResource`. `404` si no existe o no pertenece al tenant.

#### `DELETE /vehicles/{vehicleId}`
- **Descripción y Reglas de Negocio:** **Baja/archivado (soft-delete) del vehículo** — no es un borrado físico. El vehículo se marca como archivado, preservando su histórico de incidentes/telemetría/sesiones. A partir de ahí queda excluido del inventario por defecto (recuperable en `GET /vehicles?includeArchived=true`). **Regla de integridad:** se rechaza con `409 Conflict` mientras el vehículo **aún tenga un device activo vinculado** — el device debe moverse a otro vehículo (`PATCH /sensors/{id}`) o retirarse primero. Ownership validado antes de mutar. Requiere rol `ADMINISTRATOR` o `SUPERVISOR`.
- **I/O:**
  - **Path:** `{vehicleId}` (Long).
  - **Retorna:** `204 No Content` (cuerpo vacío). `404` si no existe o no pertenece al tenant. `409` si el vehículo todavía tiene un device activo vinculado. `403` si el rol no es Administrador/Supervisor.

#### `POST /vehicles/{vehicleId}/driving-sessions`
- **Descripción y Reglas de Negocio:** Check-in de un conductor en un vehículo — abre una **Driving Session** con estado `IN_PROGRESS`. Reglas de negocio validadas, en orden: (1) el vehículo y el conductor deben existir y pertenecer a la empresa autenticada (`companyId` tomado del JWT, nunca del cliente) — si no, `404`; (2) **el vehículo debe estar en estado `OPERATIONAL`** — un vehículo en `MAINTENANCE` u otro estado no operativo no puede iniciar sesión, conflicto de estado (`409`); (3) **el conductor no debe tener ya otra Driving Session en curso** — un operador no puede conducir dos vehículos a la vez, conflicto de estado (`409`); (4) **el vehículo no debe tener ya otra Driving Session en curso** — hacer check-in dos veces sobre el mismo vehículo es un conflicto de estado (`409`), no un error de validación. Esta sesión es el recurso padre de las Alertas y CardiacReadings generadas durante el turno.
- **I/O:**
  - **Path:** `{vehicleId}` (Long).
  - **Body (`CreateDrivingSessionResource`):** `driverId` (Long, requerido).
  - **Retorna:** `201 Created` con `DrivingSessionResource` (`id`, `driverId`, `vehicleId`, `startTime`, `endTime`, `status`). `404` si el vehículo o el conductor no existen o no son del tenant. `409` si el vehículo no está `OPERATIONAL`, si el conductor ya tiene una Driving Session activa, o si el vehículo ya tiene una Driving Session activa.

#### `PATCH /driving-sessions/{sessionId}`
- **Descripción y Reglas de Negocio:** Cierre (check-out) o cancelación de una Driving Session. Es un recurso independiente de `POST /vehicles/{vehicleId}/driving-sessions` — se direcciona directamente por el ID de la sesión, sin pasar por el vehículo. Enviar `{"status": "COMPLETED"}` (check-out normal) o `{"status": "CANCELLED"}` cierra la sesión: el servidor estampa `endTime` con la hora actual del servidor y cambia el `status`. Reglas de negocio validadas: (1) la sesión debe pertenecer a la empresa autenticada — si no, `404`; (2) la sesión debe estar actualmente `IN_PROGRESS` — cerrar una sesión ya cerrada es un conflicto de estado (`409` "Driving session is already closed"), no un error de validación. Al cerrarse, la sesión queda disponible para el cálculo de `PerformanceMetric` de ese turno (cálculo aún no implementado — punto de extensión documentado en el código).
- **I/O:**
  - **Path:** `{sessionId}` (Long).
  - **Body (`UpdateDrivingSessionResource`):** `status` (string, opcional: `COMPLETED`, `CANCELLED`).
  - **Retorna:** `200 OK` con `DrivingSessionResource` actualizado. `404` si la sesión no existe o no pertenece al tenant. `409` si la sesión ya está cerrada. `400` si `status` tiene un valor no reconocido.

---

### 1.3 Monitoring

Alertas de seguridad, biometría en tránsito, posición en vivo, y auditoría operacional.

#### `GET /alerts`
- **Descripción y Reglas de Negocio:** Lista las alertas de la empresa autenticada, enriquecidas con nombre del conductor, código de vehículo y descripción del incidente. `view=operational` devuelve el payload completo (todos los estados); omitir `view` devuelve solo alertas no resueltas. `sort=-occurredAt` ordena de más reciente a más antigua; `limit=N` acota el resultado.
- **I/O:**
  - **Query:** `view` (string, opcional, `operational`), `sort` (string, opcional, `-occurredAt`), `limit` (int, opcional).
  - **Retorna:** `200 OK` con `List<AlertResource>` (view completo) o `List<MobileAlertResource>` (default).

#### `GET /alerts/{alertId}`
- **Descripción y Reglas de Negocio:** Detalle completo de una alerta. Ownership validado vía comparación de `companyId`.
- **I/O:**
  - **Path:** `{alertId}` (Long).
  - **Retorna:** `200 OK` con `AlertResource`. `404` si no existe o no pertenece al tenant.

#### `GET /alerts/{alertId}/history`
- **Descripción y Reglas de Negocio:** Traza de auditoría ordenada de las acciones tomadas sobre la alerta (revisión, escalado, resolución). Valida primero que la alerta pertenezca al tenant.
- **I/O:**
  - **Path:** `{alertId}` (Long).
  - **Retorna:** `200 OK` con `List<AlertHistoryResource>` (`action`, `performedBy`, `timestamp`). `404` si la alerta no existe o no pertenece al tenant.

#### `PATCH /alerts/{alertId}`
- **Descripción y Reglas de Negocio:** Actualización parcial de una alerta: cualquier subconjunto de campos editables puede enviarse; los omitidos conservan su valor. Para resolver/descartar una alerta, el cliente envía `{"status": "resolved"}` o `{"status": "false_alarm"}` directamente — no existe un endpoint de "acción" separado. Un cambio de `status` genera automáticamente una entrada de auditoría. Ownership validado antes de mutar.
- **I/O:**
  - **Path:** `{alertId}` (Long).
  - **Body (`UpdateAlertResource`, todos opcionales):** `code`, `type`, `priority`, `status`, `occurredAt`, `title` (máx. 160), `description` (máx. 2000), `vehicleClassKey`, `vehicleCode`, `driverName`, `resolutionNotes` (máx. 2000).
  - **Retorna:** `200 OK` con `AlertResource`. `404` si no existe o no pertenece al tenant.

#### `GET /driving-sessions/{sessionId}/cardiac-readings`
- **Descripción y Reglas de Negocio:** Última lectura de frecuencia cardíaca del smart-band asociado al vehículo de la Driving Session. Cadena de resolución: `DrivingSession → Vehicle → Sensor → SensorReading (heart_rate) → CardiacReading`. Clasificación de estado: `normal` (< 110 bpm), `warning` (110–139), `critical` (≥ 140). Valida que la sesión pertenezca al tenant antes de responder. **Retorna el objeto directamente, no un arreglo** — una Driving Session tiene exactamente un conductor activo, así que el recurso es un singleton; antes devolvía `List<CardiacReadingResource>` de 0 o 1 elemento, lo cual obligaba al cliente a desempaquetar un arreglo para un valor que nunca fue plural.
- **I/O:**
  - **Path:** `{sessionId}` (Long).
  - **Retorna:** `200 OK` con `CardiacReadingResource` (`id`, `driverName`, `vehicleCode`, `heartRate`, `status`). `404` si la sesión no existe, no pertenece al tenant, o aún no tiene lecturas de sensor.

#### `GET /vehicles/positions`
- **Descripción y Reglas de Negocio:** Snapshot GPS más reciente de cada vehículo de la empresa autenticada. `LiveMapVehicle` no tiene `companyId` propio — el aislamiento se aplica cruzando el `code` del vehículo contra el registro de vehículos del tenant.
- **I/O:**
  - **Retorna:** `200 OK` con `List<LiveMapVehicleResource>` (`id`, `code`, `vehicleType`, `latitude`, `longitude`, `status`, `driverName`). Vehículos sin reporte GPS reciente pueden estar ausentes.

#### `GET /audit-logs`
- **Descripción y Reglas de Negocio:** Traza de auditoría inmutable de eventos de seguridad y operación (creación de conductores, resolución de alertas, cambios administrativos), ordenada por fecha descendente, filtrada estrictamente por `companyId` (inyectado automáticamente al escribir cada evento). Cada entrada usa **claves i18n** (no texto plano) — ver §2. **Soporta exportación binaria** vía el query param `format`:
  - Omitir `format`: JSON, envoltura `{ entries: [...] }`.
  - `format=pdf`: descarga un archivo `.pdf` (`Content-Type: application/pdf`, `Content-Disposition: attachment`) con el historial completo, para archivo/cumplimiento.
  - `format=xls`: descarga un archivo `.xlsx` real (`Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`), una fila por entrada, generado con Apache POI — para filtrado/pivoteo offline.
- **I/O:**
  - **Query:** `format` (string, opcional: `pdf`, `xls`).
  - **Retorna:** `200 OK` — JSON, binario PDF, o binario XLSX según `format`.

---

### 1.4 Companies & Analytics

Registro de empresas (tenants) y todas las proyecciones analíticas computadas de solo lectura, agrupadas bajo la raíz de agregación `Company`.

#### `POST /companies`
- **Descripción y Reglas de Negocio:** Registro de un nuevo tenant (alta de empresa minera). En una sola operación atómica: (1) crea el registro `Company`; (2) crea el usuario administrador (`role=ADMIN`); (3) genera una contraseña temporal y la envía por correo; (4) genera una **API key de telemetría única para la empresa** (ver §3); (5) activa la suscripción. No requiere JWT — es el punto de entrada para clientes nuevos. **Respuesta estructurada:** ya no retorna un mensaje de texto plano — retorna un objeto JSON (`CompanyRegistrationResponse`) con los identificadores generados, para que el cliente los consuma programáticamente en vez de parsear texto libre.
- **I/O:**
  - **Body (`CompanyRegistrationRequest`):** `companyName`, `adminFullName`, `adminEmail` (todos requeridos, `adminEmail` con formato válido); `subscriptionPlan` (string, **opcional**, valores: `STARTER`, `STANDARD`, `ENTERPRISE`). Si se omite, se asigna `STANDARD`. Es un dato puramente descriptivo — no impone límites de nodos ni de usuarios.
  - **Retorna:** `201 Created` con `CompanyRegistrationResponse`:
    ```json
    {
      "companyId": 42,
      "apiKey": "3f9a1c2b7e4d4a6e9b1c8f2a0d5e6b7c",
      "adminUsername": "admin-42-01",
      "message": "Company registered successfully. Credentials sent to admin@mine.com"
    }
    ```
    `409` si ya existe una empresa/email igual.

#### `GET /companies/{companyId}/kpis`
- **Descripción y Reglas de Negocio:** Contadores consolidados de flota, catálogo y seguridad para una empresa: conductores/vehículos por estado, supervisores, salud de sensores, alertas críticas y eventos de fatiga. El `{companyId}` de la ruta debe coincidir exactamente con el tenant del JWT — pedir el de otra empresa retorna `404`, nunca datos ajenos.
- **I/O:**
  - **Path:** `{companyId}` (Long, debe coincidir con el JWT).
  - **Retorna:** `200 OK` con `CompanyKpisResource` (`companyId`, `driversTotal`, `driversInactive`, `vehiclesTotal`, `vehiclesOperational`, `vehiclesMaintenance`, `vehiclesAlert`, `vehiclesOperationalPercent`, `supervisorsTotal`, `supervisorsLocked`, `activeSensors`, `totalSensors`, `criticalAlerts`, `fatigueEvents`). **Salud de sensores:** `activeSensors` cuenta solo los devices en estado `active`; `totalSensors` cuenta los devices en servicio **excluyendo los `retired`** — un device retirado reserva su `deviceId` para siempre pero no cuenta como hardware de flota, así que el toolbar refleja la flota real en servicio. `404` si `{companyId}` no coincide con el tenant autenticado.

#### `GET /companies/{companyId}/metrics/alerts-trend`
- **Descripción y Reglas de Negocio:** Serie temporal de conteo de alertas/incidentes por bucket horario para la empresa dada, usada para identificar patrones (picos de fatiga a fin de turno, incidentes de proximidad en zonas de alto tráfico). Ownership de `{companyId}` validado.
- **I/O:**
  - **Path:** `{companyId}` (Long, debe coincidir con el JWT).
  - **Retorna:** `200 OK` con `List<DashboardTrendResource>` (`id`, `hour`, `alerts`, `incidents`). `404` si `{companyId}` no coincide con el tenant.

#### `GET /companies/{companyId}/metrics/fatigue`
- **Descripción y Reglas de Negocio:** Distribución de eventos de fatiga por conductor para la empresa dada (fuente: alertas `fatigue_risk` y `high_heart_rate` vinculadas a sus Driving Sessions), clasificados en bandas de severidad. Ownership de `{companyId}` validado.
- **I/O:**
  - **Path:** `{companyId}` (Long, debe coincidir con el JWT).
  - **Retorna:** `200 OK` con `List<AnalyticsFatigueBarResource>` (`id`, `driverId`, `driverName`, `fatigueEvents`, `width`). `404` si `{companyId}` no coincide con el tenant.

#### `GET /companies/{companyId}/metrics/incidents`
- **Descripción y Reglas de Negocio:** Desglose de incidentes por tipo (`proximity_collision`, `restricted_zone_entry`, `high_heart_rate`, `fatigue_risk`, `connection_lost`) para la empresa dada, con conteo y porcentaje sobre el total. Ownership de `{companyId}` validado.
- **I/O:**
  - **Path:** `{companyId}` (Long, debe coincidir con el JWT).
  - **Retorna:** `200 OK` con `List<AnalyticsIncidentDistributionResource>` (`id`, `label`, `count`, `percent`, `className`). `404` si `{companyId}` no coincide con el tenant.

#### `GET /companies/{companyId}/insights`
- **Descripción y Reglas de Negocio:** Observaciones en lenguaje natural, pre-computadas por el motor de proyección analítica sobre el histórico de la empresa dada (no en tiempo real; se refresca tras cada corrida batch). Ownership de `{companyId}` validado.
- **I/O:**
  - **Path:** `{companyId}` (Long, debe coincidir con el JWT).
  - **Retorna:** `200 OK` con `List<AnalyticsInsightResource>` (`id`, `title`, `description`, `className`). `404` si `{companyId}` no coincide con el tenant.

#### `GET /companies/{companyId}/history`
- **Descripción y Reglas de Negocio:** Histórico analítico de la empresa dada, un registro por Driving Session/incidente evaluado: conductor, vehículo, duración de sesión, conteo de alertas, score de fatiga y clasificación de riesgo. A diferencia del resto de endpoints de esta sección, el ownership de `{companyId}` se valida **dentro del propio `AnalyticsHistoryRowQueryService`** (contra `SecurityContextFacade`), no solo en el controlador — doble verificación. **Paginación obligatoria:** esta colección crece sin límite a lo largo de la vida del tenant, así que no existe una variante sin paginar — omitir `page`/`size` usa el default `page=0&size=20`, no "traer todo" (evita un `OutOfMemoryError` construyendo o renderizando una respuesta ilimitada).
- **I/O:**
  - **Path:** `{companyId}` (Long, debe coincidir con el JWT). **Query:** `page` (int, opcional, default `0`), `size` (int, opcional, default `20`) — p. ej. `?page=0&size=20`.
  - **Retorna:** `200 OK` con una página Spring Data (`Page<AnalyticsHistoryRowResource>`): `content` (el arreglo de registros: `id`, `driverId`, `reportId`, `date`, `time`, `criticality`, `criticalityLabel`, `incidentType`, `involved`, `location`), más los metadatos estándar de paginación (`totalElements`, `totalPages`, `number`, `size`, `first`, `last`, etc.). **`reportId` es el ID del reporte generado a partir del incidente de esa fila** (resuelto vía `Report.incidentId → Incident`, tenant-scoped); permite al cliente enlazar directamente cada fila del histórico con `GET /drivers/{driverId}/reports/{reportId}` para abrir/exportar el detalle. Es `null` cuando el incidente aún no tiene reporte asociado. `404` si `{companyId}` no coincide con el tenant.

#### `GET /companies/{companyId}/notices`
- **Descripción y Reglas de Negocio:** Notificaciones administrativas de la empresa dada (cambios de suscripción, alertas de facturación, eventos de registro). Requiere rol ADMIN. Ownership de `{companyId}` validado.
- **I/O:**
  - **Path:** `{companyId}` (Long, debe coincidir con el JWT).
  - **Retorna:** `200 OK` con envoltura `{ notices: [...] }` (`AdminNoticeResource`: `id`, `level`, `i18nKey`, `i18nParams`, `actionKey`). `404` si `{companyId}` no coincide con el tenant.

#### `POST /companies/{companyId}/notices/{noticeId}/dispatches`
- **Descripción y Reglas de Negocio:** Reenvía una notificación al destinatario original de la empresa dada. Modelada como creación de un sub-recurso `dispatch` (sustantivo); el despacho queda registrado en el audit log. Ownership de `{companyId}` validado.
- **I/O:**
  - **Path:** `{companyId}`, `{noticeId}` (Long).
  - **Retorna:** `200 OK` (cuerpo vacío). `404` si la notificación/empresa no existe o `{companyId}` no coincide con el tenant.

#### `GET /drivers/{driverId}/scores`
- **Descripción y Reglas de Negocio:** Resumen de desempeño de un conductor específico: safety score (0–100, derivado del risk score promedio), conteo de alertas de fatiga, duración promedio de sesión, horas totales conducidas. Computado exclusivamente sobre los `PerformanceMetric` cuyo `driverId` coincide con el path variable.
- **I/O:**
  - **Path:** `{driverId}` (Long).
  - **Retorna:** `200 OK` con `PerformanceStatsResource` (`safetyScore`, `safetyScoreDelta`, `fatigueAlerts`, `drivingHours`, `drivingHoursLimit`).

#### `GET /drivers/{driverId}/metrics`
- **Descripción y Reglas de Negocio:** Listado de registros `PerformanceMetric` crudos (uno por Driving Session evaluada) del conductor especificado.
- **I/O:**
  - **Path:** `{driverId}` (Long).
  - **Retorna:** `200 OK` con `List<PerformanceMetricResource>` (`id`, `driverId`, `tripId`, `vehicleId`, `fatigueEvents`, `alertsCount`, `averageHeartRate`, `riskScore`, `calculatedAt`).

#### `GET /drivers/{driverId}/reports/{reportId}`
- **Descripción y Reglas de Negocio:** Detalle de un reporte de incidente/desempeño que pertenece a un conductor específico. La cadena de propiedad se resuelve y valida como `Report → Alert → DrivingSession → Driver`: si el `reportId` no corresponde a una alerta generada durante una sesión de ese `driverId` (o no pertenece a la empresa autenticada), retorna `404`. **Soporta exportación binaria** vía el query param `format`:
  - Omitir `format`: JSON completo, con Incident/Alert/PerformanceMetric anidados.
  - `format=pdf`: descarga un archivo `.pdf` (`Content-Type: application/pdf`, `Content-Disposition: attachment`).
  - `format=xls`: descarga un archivo `.xlsx` real (`Content-Type: application/vnd.openxmlformats-officedocument.spreadsheetml.sheet`), generado con Apache POI.
- **I/O:**
  - **Path:** `{driverId}`, `{reportId}` (Long). **Query:** `format` (string, opcional: `pdf`, `xls`).
  - **Retorna:** `200 OK` — JSON, binario PDF, o binario XLSX. `404` si el reporte no existe, no pertenece a ese conductor, o no pertenece al tenant. `400` si `format` tiene un valor no soportado.

#### `GET /reports`
- **Descripción y Reglas de Negocio:** Lista los reportes de incidentes/desempeño de la empresa autenticada (resumen: ID, tipo, fecha, descripción corta). Para el detalle completo o la exportación PDF/Excel de un reporte puntual, usar `GET /drivers/{driverId}/reports/{reportId}`.
- **I/O:**
  - **Retorna:** `200 OK` con `List<ReportResource>` (`id`, `incidentId`, `alertId`, `userId`, `metricId`, `reportType`, `createdAt`, `description`).

---

### 1.5 Devices & Sensors (Provisioning)

Aprovisionamiento y ciclo de vida del **device MineGuard** montado en cada vehículo. Un device es una **unidad edge unificada** que ya integra todos los sensores físicos (GPS, ritmo cardíaco, proximidad ultrasónica, colisión); por eso se modela como un único `Sensor` **1:1 con el vehículo** — no existe registro por-sensor individual. Este es el registro que el pipeline de telemetría (§3) resuelve en ingesta: `POST /api/v1/telemetry` busca el sensor por `(device_id, companyId)` para descubrir a qué vehículo pertenece la lectura. Hasta que un device esté registrado aquí, la telemetría de ese `device_id` se rechaza con `404`.

**Secuencia de `deviceId` por empresa:** cada empresa lleva su propio contador monotónico de `deviceId` que arranca en 1 (empresa A: 1,2,3…; empresa B: 1,2,3…, sin colisión entre tenants). El id se sirve bajo un lock de escritura pesimista que serializa a supervisores concurrentes — dos altas en paralelo nunca reciben el mismo id. **El contador nunca decrece: un `deviceId` retirado queda reservado para siempre y jamás se recicla** (un `link`/registro que hace rollback simplemente deja un hueco en la secuencia, lo cual es aceptable). El `deviceId` se serializa como string aunque internamente sea un entero.

**Ciclo de vida (`status`):** `active` (en servicio, cuenta para KPIs) → `inactive` (deshabilitado temporalmente) → `retired` (**estado terminal**: reserva el `deviceId` de forma permanente y saca al device de los KPIs `activeSensors`/`totalSensors`).

#### `POST /vehicles/{vehicleId}/sensor`
- **Descripción y Reglas de Negocio:** **Vincula el device único a un vehículo** — es el flujo de un solo paso que usa el panel web del supervisor justo después de crear el vehículo. **El body va vacío a propósito:** el servidor asigna el siguiente `deviceId` secuencial de la empresa, fija `sensorType` en `"MineGuard Device"` y el `status` inicial en `"active"`. El vehículo debe pertenecer al tenant del JWT. Un vehículo que ya tiene un device es rechazado (`409`). Requiere rol `ADMINISTRATOR` o `SUPERVISOR`.
- **I/O:**
  - **Path:** `{vehicleId}` (Long).
  - **Body:** vacío (ningún campo es aceptado ni requerido).
  - **Retorna:** `201 Created` con `SensorResource` (`id`, `vehicleId`, `sensorType`, `deviceId`, `status`, `companyId`). `404` si el vehículo no existe o no pertenece al tenant. `409` si el vehículo ya tiene un device vinculado. `403` si el rol no es Administrador/Supervisor.

#### `GET /vehicles/{vehicleId}/sensor`
- **Descripción y Reglas de Negocio:** Devuelve el device actualmente montado en el vehículo. Alimenta el filtro de inventario "sin device". Requiere rol `ADMINISTRATOR` o `SUPERVISOR`.
- **I/O:**
  - **Path:** `{vehicleId}` (Long).
  - **Retorna:** `200 OK` con `SensorResource`. `404` cuando el vehículo no tiene device (o no pertenece al tenant). `403` si el rol no es Administrador/Supervisor.

#### `GET /sensors`
- **Descripción y Reglas de Negocio:** Lista todos los sensores/devices de la empresa autenticada (aislado por tenant). Colección de solo lectura para auditoría, **restringida a rol `ADMINISTRATOR`**.
- **I/O:**
  - **Retorna:** `200 OK` con `List<SensorResource>`. `403` si el rol no es Administrador.

#### `POST /sensors`
- **Descripción y Reglas de Negocio:** Registro explícito de un sensor y su montaje en uno de los vehículos de la empresa (variante administrativa de la vinculación 1:1, con `deviceId` provisto por el cliente). El `deviceId` es el identificador que el device físico envía como `device_id` en sus payloads de telemetría — **debe ser único dentro de la empresa**. La empresa dueña es siempre el tenant del JWT y **no puede enviarse en el body** — el DTO está anotado `@JsonIgnoreProperties(ignoreUnknown = false)`, así que cualquier campo no reconocido (incluido `companyId`) se rechaza con `400`.
- **I/O:**
  - **Body (`CreateSensorResource`):** `vehicleId` (Long, requerido), `deviceId` (string, requerido), `sensorType` (string, opcional — default `"MineGuard Device"`), `status` (string, opcional — default `"active"`). Ningún otro campo es aceptado.
  - **Retorna:** `201 Created` con `SensorResource`. `400` si el body es inválido o incluye una propiedad no reconocida. `404` si el vehículo no existe o no pertenece al tenant. `409` si ya existe un sensor con ese `deviceId` en la empresa. `403` si el JWT falta o es inválido.

#### `PATCH /sensors/{id}`
- **Descripción y Reglas de Negocio:** **Actualización parcial de un device: reasignarlo y/o cambiar su estado.** Enviar `vehicleId` lo **mueve a otro vehículo** conservando su `deviceId` (el entero que indexa la unidad embebida); el vehículo destino debe pertenecer al tenant y **no debe tener ya un device** (`409`). Enviar `status` (`active` | `inactive` | `retired`) cambia su estado de ciclo de vida; `retired` reserva el id de forma permanente y saca al device de los KPIs de sensores. Ambos campos pueden ir juntos; los omitidos se conservan (semántica PATCH real). Requiere rol `ADMINISTRATOR` o `SUPERVISOR`.
- **I/O:**
  - **Path:** `{id}` (Long — id numérico del device/sensor).
  - **Body (`UpdateSensorResource`, ambos opcionales):** `vehicleId` (Long), `status` (string: `active`, `inactive`, `retired`).
  - **Retorna:** `200 OK` con `SensorResource`. `400` si el `status` tiene un valor inválido. `404` si el device o el vehículo destino no existen en este tenant. `409` si el vehículo destino ya tiene un device. `403` si el rol no es Administrador/Supervisor.

---

### 1.6 Platform (Cross-Tenant)

#### `GET /platform/metrics`
- **Descripción y Reglas de Negocio:** Único endpoint intencionalmente **cross-tenant** de todo el contrato — no aísla por empresa. Expone contadores globales de plataforma (empresas registradas, suscripciones activas, usuarios totales, alertas globales) y requiere rol `ADMIN`/`GLOBAL_ADMIN`. No confundir con `GET /companies/{companyId}/kpis`, que sí está aislado por tenant. **Retorna el objeto directamente, no una lista** — existe exactamente un resumen de plataforma, así que envolverlo en un arreglo de un solo elemento era una proyección incorrecta que obligaba al cliente a desempaquetarlo innecesariamente.
- **I/O:**
  - **Retorna:** `200 OK` con `AdminSummaryResource` (`id`, `activeSensors`, `totalSensors`, `lockedAccounts`, `registeredAssets`).

---

## 2. Arquitectura, Seguridad y Estándares

### Seguridad Multi-Tenant

**Ningún endpoint de creación o edición acepta `companyId` (o `idCompany`) en el payload del cliente.** El comportamiento actual, sin excepción, es:

1. El JWT emitido en `POST /sessions` / `POST /mobile-sessions` porta el `companyId` del usuario autenticado.
2. Cada `CommandService` de creación resuelve el tenant exclusivamente vía `SecurityContextFacade.currentCompanyId()`.
3. Cada `CommandService` de actualización (`PUT`/`PATCH`) valida, antes de mutar, que la entidad objetivo pertenezca al `companyId` del JWT — de lo contrario responde `404` (nunca `403`, para no confirmar la existencia del recurso a otro tenant).
4. Cada `QueryService` de lectura filtra la consulta por `companyId` del JWT antes de tocar la base de datos.
5. Todo endpoint que expone explícitamente `{companyId}` en el path (bajo `/companies/{companyId}/...`) valida adicionalmente que ese valor coincida con el tenant del JWT — solicitar el `{companyId}` de otra empresa siempre retorna `404`, nunca datos ajenos.

**Implicación para Frontend/Mobile:** los formularios de creación/edición no deben enviar ningún campo de empresa. El backend lo resuelve de forma transparente y segura a partir del token `Authorization: Bearer <token>`.

### Formatos de Fecha

- Todos los campos de tipo fecha/hora se serializan en formato estándar ISO-8601 (ej. `2026-07-04T14:32:10Z`).

### Máquina de Estados del Vehículo

El campo `status` de `Vehicle` (`VehicleStatus`) determina si un vehículo puede iniciar una Driving Session. Estados posibles:

| Estado | Significado | ¿Permite check-in? |
|---|---|---|
| `OPERATIONAL` | Vehículo disponible y en condiciones de operar. | Sí — único estado que permite `POST /vehicles/{vehicleId}/driving-sessions`. |
| `IN_TRANSIT` | Vehículo actualmente en movimiento/operación. | No — `409 Conflict`. |
| `MAINTENANCE` | Vehículo en mantenimiento programado o correctivo. | No — `409 Conflict`. |
| `ALERT` | Vehículo con una alerta crítica activa (proximidad, colisión). | No — `409 Conflict`. |
| `INACTIVE` | Vehículo dado de baja temporalmente (fuera de servicio). | No — `409 Conflict`. |
| `RESTRICTED_ROUTE` | Vehículo limitado a rutas restringidas. | No — `409 Conflict`. |

**Regla de negocio:** `POST /vehicles/{vehicleId}/driving-sessions` rechaza el check-in con `409 Conflict` ("Vehicle is not available for operation") si el vehículo no está en `OPERATIONAL`, sin importar cuál de los otros cinco estados tenga.

### Soft-Delete (Desactivación / Archivado)

La plataforma **nunca borra físicamente** un recurso operativo con histórico asociado. `DELETE` sobre un conductor o un vehículo es un soft-delete que preserva reportes, incidentes, telemetría y Driving Sessions para auditoría y cumplimiento:

| Recurso | Endpoint | Marca aplicada | Visibilidad tras el borrado |
|---|---|---|---|
| Conductor | `DELETE /drivers/{driverId}` | `shiftStatus = INACTIVE` | Excluido de `GET /drivers` por defecto; visible con `?includeInactive=true`. |
| Vehículo | `DELETE /vehicles/{vehicleId}` | `archived = true` | Excluido de `GET /vehicles` por defecto; visible con `?includeArchived=true`. |
| Device / Sensor | `PATCH /sensors/{id}` con `status=retired` | `status = retired` | Reserva el `deviceId` para siempre; excluido de los KPIs `activeSensors`/`totalSensors`. |

Ambos `DELETE` requieren rol `ADMINISTRATOR` o `SUPERVISOR` y retornan `204 No Content`. Archivar un vehículo con un device activo aún vinculado se rechaza con `409` — primero hay que mover el device (`PATCH /sensors/{id}` con `vehicleId`) o retirarlo (`status=retired`).

### Exportación de Documentos (Content Negotiation)

El query param `format` es la convención estándar de la plataforma para descargar una representación binaria de un recurso, en lugar de rutas separadas por tipo de archivo (p. ej. no existe `/reports/{id}/pdf`). Aplica hoy a `GET /audit-logs` y `GET /drivers/{driverId}/reports/{reportId}`:

| `format` | Content-Type devuelto | Generado con |
|---|---|---|
| *(omitido)* | `application/json` | — |
| `pdf` | `application/pdf` | Generación de texto plano encapsulado, sin librería externa |
| `xls` | `application/vnd.openxmlformats-officedocument.spreadsheetml.sheet` | Apache POI (`poi-ooxml`) — `.xlsx` real, no un CSV disfrazado |

Ambas respuestas binarias incluyen `Content-Disposition: attachment; filename=...` para forzar la descarga en el navegador.

### i18n (Internacionalización)

- El "sobre" de toda respuesta de error (`ErrorResource`: `code`, `message`, `details`) se resuelve vía `ResourceBundle` (`messages.properties` / `messages_es.properties`) según el header `Accept-Language` / locale de la petición.
- El `AuditLogEntry` y el `AdminNotice` **nunca** devuelven texto renderizado en un idioma fijo — devuelven **claves i18n** (`titleKey`, `descriptionKey`, `actorKey`, `i18nKey`) más un mapa de parámetros estructurados. La traducción a texto visible es responsabilidad del cliente.
- **Deuda técnica documentada:** el contenido de las razones de error de negocio (p. ej. "Corporate id already exists") viaja hoy hardcodeado en inglés dentro de `details`; y los correos transaccionales (credenciales, reseteo de contraseña) están 100% hardcodeados en español. Ninguno de los dos bloquea la integración actual.

### Swagger / OpenAPI

- El contrato vivo está disponible en `/swagger-ui.html` (UI interactiva) y `/v3/api-docs` (JSON OpenAPI crudo), habilitado vía `springdoc-openapi-starter-webmvc-ui`.
- Todos los controladores activos están documentados con `@Tag` y cada operación con `@Operation`/`@ApiResponses`/`@Parameter` (incluyendo los valores aceptados de `format` donde aplica).
- **Resuelto:** `POST /api/v1/telemetry` declara su propio esquema de seguridad (`@SecurityRequirement(name = "ApiKey")`, tipo `apiKey`/header `X-API-Key`), que sobrescribe el requisito global `bearerAuth` solo para ese endpoint. Swagger UI ahora muestra el candado correcto (API key) en telemetría, no el de JWT.
- **Deuda técnica documentada (pendiente):** el resto de endpoints públicos sin JWT (`POST /companies`, `POST /sessions`, `POST /sessions/mobile`... es decir `POST /mobile-sessions`, `POST /users`, `POST /password-resets`) todavía heredan el requisito global `bearerAuth` y muestran el candado JWT en Swagger UI aunque no lo exijan. El comportamiento real de autenticación es el descrito en este documento, no el que sugiere el ícono de Swagger UI en esos casos puntuales.

---

## 3. Manifiesto de Integración Edge / Embedded (IoT)

> **Prioridad máxima — lectura obligatoria para el equipo de firmware.** Esta sección documenta el único contrato de red que el hardware (sensores de proximidad, smart-bands, GPS embebido) debe implementar.

### Endpoint de Ingesta

```
POST /api/v1/telemetry
```

Único endpoint de ingesta de telemetría de la plataforma.

### Autenticación M2M — `X-API-Key`

- **NO usar JWT.** Este endpoint no acepta `Authorization: Bearer <token>` bajo ninguna circunstancia. La autenticación es exclusivamente vía el header:
  ```
  X-API-Key: <clave>
  ```
- **La clave es única por empresa (tenant), no global.** Cada empresa recibe su propia API key en el momento de darse de alta (`POST /companies`), incluida en el mensaje de respuesta de ese endpoint. **No existe ni existirá una clave compartida entre distintos clientes de MineGuard.**
- Cada dispositivo (sensor/smart-band) debe configurarse con la API key de la empresa dueña de la mina donde está desplegado. Si un dispositivo se reasigna físicamente a otra empresa, su configuración de `X-API-Key` debe actualizarse.
- **Consecuencia de diseño importante:** el backend resuelve el `companyId` a partir de la `X-API-Key`, y busca el sensor por la combinación `(company_id, device_id)`. Esto significa que **dos empresas distintas pueden usar el mismo `device_id` de fábrica sin colisionar entre sí** — el aislamiento lo da la API key, no el `device_id` por sí solo.

### Payload

Content-Type: `application/json`. Todos los campos usan `snake_case` estricto:

```json
{
  "device_id": "smart-band-001",
  "bpm": 78.0,
  "distance_cm": 35,
  "collision": false,
  "lat": -16.409,
  "lng": -71.537,
  "timestamp": "2026-07-04T14:32:10Z"
}
```

| Campo | Tipo | Obligatorio | Descripción |
|---|---|---|---|
| `device_id` | string | Sí | Identificador único del sensor/dispositivo edge, dado de alta previamente contra la empresa. |
| `bpm` | number | No (0 = ausente) | Frecuencia cardíaca en latidos por minuto. `0` indica "sin lectura en este ciclo". |
| `distance_cm` | integer, nullable | No | Distancia de proximidad detectada, en centímetros. `null` si el sensor de proximidad no reportó en este ciclo. |
| `collision` | boolean | No (default `false`) | `true` cuando el sensor detecta un evento de impacto. |
| `lat`, `lng` | number, nullable | No | Coordenadas GPS. Enviar ambas o ninguna. |
| `timestamp` | string (ISO-8601), nullable | No | Momento de la lectura. Si se omite, el servidor usa su propia hora de recepción. |

### Reglas de Negocio Detonadas por el Backend

Al recibir un payload válido, el backend ejecuta, en orden, las siguientes acciones — todas dentro de una única transacción de ingesta:

1. **Resolución de sensor (scoped por empresa):** busca el sensor/device por `device_id` **dentro del tenant de la API key** (registrado previamente vía §1.5), obteniendo el `vehicleId` al que está montado y la **Driving Session activa** (si existe un check-in en curso para ese vehículo). Si el `device_id` no existe para esa empresa → `404`.
2. **Persistencia de ritmo cardíaco (`cardiac`):** si `bpm > 0`, se persiste como `SensorReading` de tipo `heart_rate`, disponible luego en `GET /driving-sessions/{sessionId}/cardiac-readings`.
3. **Actualización de posición en vivo (`location`):** si `lat` y `lng` están presentes, actualiza el marcador GPS del vehículo, reflejado en `GET /vehicles/positions`.
4. **Persistencia de muestras de proximidad/colisión (`proximity` / `collision`):** si `distance_cm` está presente, se persiste como `SensorReading` de tipo `distance_cm` (acción `proximity`); si `collision == true`, se persiste como `SensorReading` de tipo `collision` (acción `collision`). Esta persistencia ocurre **siempre que el campo venga en el payload**, independientemente de si se cruza o no el umbral de alerta.
5. **Alerta crítica automática de proximidad/colisión (`alert`):** si `collision == true` **O** `distance_cm ≤ 20` (umbral de seguridad, en centímetros), se genera automáticamente una `Alert` de severidad `CRITICAL` (visible en `GET /alerts`). **La alerta se genera exista o no una Driving Session activa:** si hay una sesión en curso, la alerta queda vinculada a ella; si no la hay, la alerta se genera igualmente sin vínculo de sesión (su descripción indica "without active trip"). *(Cambio de comportamiento respecto de versiones previas del contrato, donde la alerta requería una sesión activa y el umbral era 40 cm.)*

El campo `processed` de la respuesta confirma exactamente cuáles de estas acciones se ejecutaron en cada llamada (`cardiac`, `location`, `proximity`, `collision`, `alert`, en cualquier combinación).

### Respuesta

**`processed` es un arreglo JSON de strings, no un string separado por comas** — así el firmware C/C++ lo recorre directamente (`["cardiac", "location"]`) sin tener que hacer `strtok`/`split` sobre un string plano.

```json
{
  "device_id": "smart-band-001",
  "processed": ["cardiac", "location", "alert"],
  "alert_raised": true,
  "message": "Telemetry ingested: 3 action(s) executed"
}
```

### HTTP Status — Significado para el Firmware

| Status | Significado | Acción esperada del dispositivo |
|---|---|---|
| **201 Created** | Telemetría procesada correctamente. El campo `processed` (arreglo JSON) indica qué acciones se ejecutaron (`cardiac`, `location`, `proximity`, `collision`, `alert`, en cualquier combinación). | Continuar el ciclo normal de envío. No reintentar. |
| **401 Unauthorized** | El header `X-API-Key` falta o no coincide con ninguna empresa registrada. | **Detener el envío y alertar a operaciones** — clave mal configurada o revocada; reintentar sin corregirla no tendrá efecto. |
| **404 Not Found** | El `device_id` enviado no está registrado bajo la empresa dueña de la `X-API-Key` usada. | El dispositivo no ha sido dado de alta (o fue dado de alta bajo la empresa equivocada). Requiere aprovisionamiento manual — no reintentar sin intervención. |
| **400 Bad Request** | El payload JSON es inválido o no cumple el contrato de campos. | Corregir el payload en firmware. |
