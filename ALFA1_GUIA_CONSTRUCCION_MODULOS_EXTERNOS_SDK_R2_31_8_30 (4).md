# ALFA-1 — Guía completa para construir módulos externos SDK

**Fase:** R2.31.8.30  
**Área:** SDK de módulos externos  
**Objetivo:** definir con precisión cómo debe construirse un módulo para que ALFA-1 pueda entenderlo, validarlo, cargarlo, auditarlo y permitir su uso por frente operativo.

---

## 1. Principio general

Un módulo externo de ALFA-1 no debe modificar el núcleo del bot. El módulo solo agrega capacidades mediante un contrato controlado por SDK.

Principio rector:

```text
Los módulos agregan capacidades.
ALFA-1 conserva seguridad, permisos, auditoría, logs, referencias y ejecución.
```

Un módulo correcto debe cumplir cinco capas:

```text
1. Estructura de carpetas correcta.
2. Manifest module.json válido.
3. Entrypoint Python con register(ctx).
4. Permisos SDK seguros.
5. Política de acceso por comando/frente cuando aplique.
```

---

## 2. Estructura obligatoria

Cada módulo vive dentro de:

```text
external_modules/<nombre_modulo>/
```

Ejemplo:

```text
external_modules/stripe_security_audit/
├── module.json
└── samaritan_module/
    ├── __init__.py
    └── config/
        └── blocked_domains.json
```

Reglas:

```text
- module.json es obligatorio.
- samaritan_module/__init__.py es obligatorio.
- __init__.py debe llamarse exactamente así.
- No usar __init.py.
- No subir __pycache__.
- No subir .pyc.
- No subir .env, DB, SQLite, backups ni secretos.
```

---

## 3. Manifest module.json

ALFA-1 valida el módulo desde `module.json` antes de importar Python.

### 3.1 Manifest recomendado

```json
{
  "name": "stripe_security_audit",
  "version": "1.0.0",
  "summary": "Analizador defensivo de dominios y URLs sospechosas de Stripe",
  "entrypoint": "samaritan_module:register",
  "target": "alfa1",
  "permissions": [
    "telegram.commands",
    "module.logger",
    "module.manifest",
    "module.metadata",
    "alfa.audit.write"
  ],
  "commands": [
    {
      "name": "stripeaudit",
      "description": "Analiza dominios o URLs sospechosas de Stripe en modo defensivo"
    }
  ],
  "callbacks": [],
  "access": {
    "commands": {
      "stripeaudit": {
        "mode": "private_group_general",
        "allow_superadmin_anywhere": true,
        "deny_message": "Este comando solo esta disponible para superadmin o dentro del grupo privado."
      }
    }
  }
}
```

### 3.2 Campos obligatorios

| Campo | Obligatorio | Descripción |
|---|---:|---|
| `name` | Sí | Nombre interno estable del módulo |
| `version` | Recomendado | Versión semántica |
| `summary` | Recomendado | Texto corto para paneles |
| `entrypoint` | Sí | Debe apuntar a la función `register` |
| `target` | Sí | Debe indicar destino del ecosistema: `alfa1`, `sombra` o `alfa1+sombra` |
| `permissions` | Sí | Scopes SDK seguros solicitados |
| `commands` | Si registra comandos | Declaración de comandos del módulo |
| `callbacks` | Si registra callbacks | Declaración de callbacks del módulo |
| `access` | Opcional R2.31.8.30 | Política de acceso por comando |

### 3.3 `entrypoint`

Correcto:

```json
"entrypoint": "samaritan_module:register"
```

`entrypoint` indica el paquete Python y la función que ALFA-1 debe ejecutar al cargar el módulo.

### 3.4 `target`

Correcto para ALFA-1:

```json
"target": "alfa1"
```

Valores válidos:

```text
alfa1
sombra
alfa1+sombra
```

Incorrecto:

```json
"target": "samaritan_module"
```

`target` no es el paquete Python. El paquete Python va en `entrypoint`.

---

## 4. Entrypoint Python

Archivo obligatorio:

```text
external_modules/<modulo>/samaritan_module/__init__.py
```

Debe definir:

```python
def register(ctx):
    ...
```

Ejemplo:

```python
from telegram import Update
from telegram.ext import ContextTypes


async def stripeaudit_handler(update: Update, context: ContextTypes.DEFAULT_TYPE):
    message = update.effective_message
    if not message:
        return

    target = " ".join(context.args or []).strip()
    if not target:
        await message.reply_text("Uso: /stripeaudit <dominio|url>")
        return

    await message.reply_text(f"Analisis defensivo solicitado para: {target}")


def register(ctx):
    ctx.require_permission("telegram.commands")
    ctx.register_command("stripeaudit", stripeaudit_handler)
    ctx.logger.info("stripe_security_audit registrado correctamente")
    return ctx.describe()
```

---

## 5. Contrato `ctx`

El SDK entrega un contexto controlado al módulo.

El contexto expone:

```text
ctx.application
ctx.app
ctx.module_name
ctx.manifest
ctx.permissions
ctx.security
ctx.services
ctx.logger
ctx.commands
ctx.callbacks
ctx.register_command(...)
ctx.add_command(...)
ctx.register_callback(...)
ctx.add_callback(...)
ctx.require_permission(...)
ctx.describe()
ctx.audit
```

Regla:

```text
El módulo no debe salir del contrato ctx para tocar partes internas de ALFA-1.
```

---

## 6. Permisos SDK seguros

Permisos seguros actuales:

```text
telegram.commands
telegram.callbacks
module.logger
module.manifest
module.metadata
alfa.audit.write
```

Para un módulo con comandos:

```json
"permissions": [
  "telegram.commands",
  "module.logger",
  "module.manifest",
  "module.metadata",
  "alfa.audit.write"
]
```

Para un módulo con callbacks:

```json
"permissions": [
  "telegram.commands",
  "telegram.callbacks",
  "module.logger",
  "module.manifest",
  "module.metadata",
  "alfa.audit.write"
]
```

---

## 7. Permisos prohibidos

ALFA-1 bloquea permisos peligrosos:

```text
db.*
database.*
env.*
secrets.*
core.*
references.*
shell.*
system.*
```

El módulo no debe:

```text
- Leer .env directamente.
- Leer tokens.
- Tocar core.py.
- Ejecutar shell.
- Conectarse directo a DB.
- Modificar referencias.
- Registrar callbacks genéricos sin prefijo.
- Crear permisos implícitos.
```

---

## 8. Nombres de comandos

Regla segura:

```text
solo minusculas, numeros y guion bajo
sin slash en module.json
sin espacios
sin acentos
sin puntos
sin dos puntos
sin guion medio
```

Correcto:

```text
stripeaudit
stripe_audit
stripecheck
stripe_domain_check
```

Incorrecto:

```text
/stripeaudit
stripe-audit
stripe audit
StripeAudit
stripe.audit
stripe:audit
```

El nombre debe coincidir en dos lugares:

### 8.1 En module.json

```json
"commands": [
  {
    "name": "stripeaudit",
    "description": "Analiza dominios o URLs sospechosas de Stripe"
  }
]
```

### 8.2 En register(ctx)

```python
ctx.register_command("stripeaudit", stripeaudit_handler)
```

Si cambias el nombre del comando en un solo lugar, ALFA-1 puede detectar inconsistencias o cargar el módulo sin el comando esperado.

---

## 9. Política de acceso por comando R2.31.8.30

La fase R2.31.8.30 agrega soporte SDK para declarar acceso por comando desde `module.json`.

Objetivo:

```text
Permitir que un módulo sea usado por usuarios generales dentro del grupo privado,
conservando acceso de superadmin en cualquier frente.
```

### 9.1 Forma recomendada

```json
"access": {
  "commands": {
    "stripeaudit": {
      "mode": "private_group_general",
      "allow_superadmin_anywhere": true,
      "deny_message": "Este comando solo esta disponible para superadmin o dentro del grupo privado."
    }
  }
}
```

### 9.2 Modos soportados

```text
unrestricted
public
any
superadmin_only
private_group_general
private_group_only
admin_group_only
disabled
```

### 9.3 Descripción de modos

| Modo | Descripción |
|---|---|
| `unrestricted` | El SDK no aplica restricción adicional |
| `public` | Alias de uso sin restricción SDK |
| `any` | Alias de uso sin restricción SDK |
| `superadmin_only` | Solo superadmin |
| `private_group_general` | Cualquier usuario dentro del grupo privado, superadmin en cualquier frente si se permite |
| `private_group_only` | Alias operativo para grupo privado |
| `admin_group_only` | Solo dentro del grupo admin configurado |
| `disabled` | Bloquea el comando |

---

## 10. Variables Railway para acceso por frente

Para módulos externos:

```env
ALFA_MODULES_RUNTIME_ENABLED=1
ALFA_MODULES_PATH=external_modules
ALFA_MODULES_ALLOWED=external_modules/example_echo_module,example_echo_module,external_modules/stripe_security_audit,stripe_security_audit
```

Para grupo privado:

```env
ALFA_PRIVATE_GROUP_CHAT_ID=-100xxxxxxxxxx
```

Variables alternativas soportadas por SDK R2.31.8.30:

```env
ALFA_PRIVATE_GROUP_CHAT_ID=-100xxxxxxxxxx
ALFA_PRIVATE_GROUP_IDS=-100xxxxxxxxxx,-100yyyyyyyyyy
PRIVATE_GROUP_CHAT_ID=-100xxxxxxxxxx
PRIVATE_GROUP_IDS=-100xxxxxxxxxx
ALFA_MODULES_PRIVATE_GROUP_IDS=-100xxxxxxxxxx
```

Para grupo admin:

```env
ADMIN_GROUP_CHAT_ID=-100xxxxxxxxxx
ALFA_ADMIN_GROUP_CHAT_ID=-100xxxxxxxxxx
ALFA_ADMIN_GROUP_IDS=-100xxxxxxxxxx
```

Para superadmin:

```env
SUPER_ADMIN_ID=123456789
SUPER_ADMIN_IDS=123456789,987654321
ALFA_SUPERADMIN_IDS=123456789
ALFA_SUPER_ADMINS=123456789
```

---

## 11. Auditoría desde módulos

Si el módulo necesita registrar eventos:

```python
ctx.audit.record(
    module=ctx.module_name,
    action="stripe_domain_checked",
    actor_id=update.effective_user.id if update.effective_user else None,
    metadata={
        "target": target,
        "result": result,
    },
)
```

Alternativa explícita:

```python
ctx.services.require("audit").record(
    module=ctx.module_name,
    action="stripe_domain_checked",
    actor_id=actor_id,
    metadata={"target": target},
)
```

Regla:

```text
El módulo audita mediante ctx.services.audit; nunca mediante DB directa.
```

---

## 12. Validaciones antes de subir

```bash
cd ~/samaritano-alfa1-init-estadomayor

python -m json.tool external_modules/stripe_security_audit/module.json >/dev/null
python -m json.tool external_modules/stripe_security_audit/samaritan_module/config/blocked_domains.json >/dev/null
python -m py_compile external_modules/stripe_security_audit/samaritan_module/__init__.py
python tools/smoke_test.py
```

Si R2.31.8.30 esta aplicado:

```bash
python tools/verify_alfa1_r2_31_8_30_module_command_access_sdk.py
python tools/audit_alfa1_r2_31_8_30_module_command_access_sdk.py
```

---

## 13. Flujo Git/Termux obligatorio

```bash
cd ~/samaritano-alfa1-init-estadomayor

git checkout main
git pull --ff-only origin main
git switch -c hotfix/alfa1-nombre-de-la-fase
```

Agregar solo archivos necesarios:

```bash
git add \
  external_modules/stripe_security_audit/module.json \
  external_modules/stripe_security_audit/samaritan_module/__init__.py \
  external_modules/stripe_security_audit/samaritan_module/config/blocked_domains.json
```

Commit:

```bash
git status --short
git diff --cached --stat
git commit -m "fix: descripcion clara del cambio"
git push -u origin hotfix/alfa1-nombre-de-la-fase
```

Merge:

```bash
git checkout main
git pull --ff-only origin main
git merge --no-ff hotfix/alfa1-nombre-de-la-fase -m "merge: descripcion clara del cambio"
git push origin main
```

Después:

```text
Railway → Redeploy manual
Telegram → /modulespanel → Detectados → /moduleload external_modules/<modulo>
```

---

## 14. Checklist final

```text
[ ] Carpeta en external_modules/<modulo>
[ ] module.json existe
[ ] module.json tiene name
[ ] module.json tiene version
[ ] module.json tiene summary
[ ] module.json tiene entrypoint
[ ] entrypoint = samaritan_module:register
[ ] module.json tiene target
[ ] target = alfa1
[ ] permissions usa solo scopes seguros
[ ] commands declara los comandos reales
[ ] access declara politica si el comando no es solo superadmin
[ ] samaritan_module/__init__.py existe
[ ] __init__.py define def register(ctx)
[ ] register(ctx) usa ctx.register_command(...)
[ ] nombres de comandos coinciden entre manifest y Python
[ ] no toca .env
[ ] no toca core.py
[ ] no toca referencias
[ ] no toca DB directa
[ ] no usa shell
[ ] json.tool pasa
[ ] py_compile pasa
[ ] smoke_test pasa
[ ] verify/audit de fase pasa
[ ] git push a main
[ ] Railway redeploy
[ ] /modulespanel muestra valid=True
[ ] /moduleload carga con Loader: sdk_contract
```
