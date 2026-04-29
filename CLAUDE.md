# CLAUDE.md — Skill de Documentación Automática del TFG

Este archivo define cómo Claude debe comportarse en este repositorio.
Se carga automáticamente en cada sesión de Claude Code.

---

## Contexto del Proyecto

**Proyecto:** TFG — Implantación Segura y Automatizada de Odoo
**Autora:** Sandra Fradejas
**Descripción:** Entorno productivo completo para el ERP Odoo con enfoque en seguridad, contenerización (Docker) y buenas prácticas de administración de sistemas. Incluye pfSense como firewall, Nginx como reverse proxy, y automatización de scripts Bash.

### Estructura del Repositorio

```
TFG-Implantacion_Segura_y_Automatizada_de_Odoo/
├── docker/          # docker-compose.yml y configuración de contenedores
├── config_nginx/    # Configuración de Nginx (reverse proxy + SSL)
├── scripts/         # Scripts Bash de automatización e instalación
├── sql/             # Scripts SQL (backups, init, usuarios)
├── ISOs/            # Referencias a ISOs utilizadas
├── docs/            # Documentación técnica del proyecto
│   ├── implementation_plan.md    # Plan de implementación por fases
│   ├── task.md                   # Tareas pendientes y completadas
│   ├── github_issues.md          # Registro de issues de GitHub
│   ├── reglas_pfsense.md         # Reglas de firewall pfSense
│   └── propuestas_mejoras_extra.md # Ideas y mejoras futuras
└── CLAUDE.md        # Este archivo
```

---

## Skill: Auto-Documentación de Cambios

### Propósito

Cada vez que realices o asistas en un cambio técnico en este repositorio, debes **documentar automáticamente** lo que se hizo, por qué, y cómo afecta al sistema — sin que Sandra tenga que pedírtelo explícitamente.

---

### Cuándo Activar la Documentación

Documenta automáticamente cuando:

- Se **crea o modifica** cualquier archivo en `docker/`, `config_nginx/`, `scripts/`, `sql/`
- Se **añade una regla** de pfSense o se modifica la arquitectura de red
- Se **resuelve un issue** o se completa una tarea del `docs/task.md`
- Se **instala, actualiza o elimina** un servicio o dependencia
- Se **cambia una variable de entorno** o configuración sensible (sin revelar valores reales)
- Se **corrige un error** o problema de seguridad

---

### Qué Documentar y Dónde

#### 1. `docs/task.md` — Registro de Tareas

Actualiza este archivo marcando tareas completadas y añadiendo nuevas si procede.

**Formato de entrada completada:**
```markdown
- [x] **[YYYY-MM-DD]** Descripción breve de la tarea completada
  - _Qué se hizo:_ Explicación técnica concisa
  - _Archivos afectados:_ `ruta/al/archivo.ext`
  - _Resultado:_ Comportamiento esperado después del cambio
```

**Formato de tarea nueva detectada:**
```markdown
- [ ] **[PENDIENTE]** Descripción de la tarea detectada
  - _Motivo:_ Por qué es necesaria
  - _Prioridad:_ Alta / Media / Baja
```

---

#### 2. `docs/implementation_plan.md` — Plan de Implementación

Si el cambio afecta a una fase del plan, actualiza el estado de esa fase.

Cuando una fase se complete, añade al final de su sección:
```markdown
> ✅ **Completado [YYYY-MM-DD]:** Resumen de cómo quedó implementada esta fase.
```

---

#### 3. `docs/reglas_pfsense.md` — Reglas de Firewall

Si el cambio implica nuevas reglas o modificación de las existentes, añade una entrada en formato tabla:

```markdown
| Fecha      | Interfaz | Acción | Protocolo | Origen → Destino | Puerto | Descripción |
|------------|----------|--------|-----------|------------------|--------|-------------|
| YYYY-MM-DD | LAN/WAN  | Pass/Block | TCP/UDP | IP → IP       | XXXX   | Motivo      |
```

---

#### 4. `docs/CHANGELOG.md` — Historial de Cambios *(crear si no existe)*

Mantén un CHANGELOG siguiendo [Keep a Changelog](https://keepachangelog.com/es/1.1.0/).

**Formato:**
```markdown
## [Sin publicar]

### Añadido
- Descripción del nuevo elemento añadido

### Modificado
- Descripción de cambio en funcionalidad existente

### Corregido
- Descripción del bug o problema resuelto

### Seguridad
- Descripción de vulnerabilidad corregida o mejora de seguridad
```

Cuando se hace un commit o se cierra un issue, mueve las entradas de `[Sin publicar]` a una nueva sección con versión o fecha:
```markdown
## [v1.x — YYYY-MM-DD]
```

---

### Reglas de Escritura para la Documentación

1. **Idioma:** Siempre en español (es el TFG de Sandra).
2. **Tono:** Técnico pero claro, como si lo leyera el tutor del TFG.
3. **Nunca incluir:** contraseñas, tokens, IPs privadas reales, ni secretos. Usar `<VALOR_OCULTO>` o `<IP_INTERNA>` como placeholder.
4. **Siempre incluir:** fecha del cambio, archivo(s) afectado(s), y el motivo técnico del cambio.
5. **Máximo 3 líneas por entrada** en `task.md`. Si necesitas más detalle, crea un archivo dedicado en `docs/`.

---

### Flujo de Trabajo Estándar

Cuando Sandra te pida hacer un cambio, sigue este orden:

```
1. Analiza el cambio solicitado
2. Implementa el cambio técnico (modifica el archivo correspondiente)
3. Actualiza docs/task.md con lo que se hizo
4. Actualiza docs/CHANGELOG.md con la entrada apropiada
5. Si aplica: actualiza implementation_plan.md o reglas_pfsense.md
6. Informa a Sandra: "✅ Cambio realizado y documentado en docs/"
```

---

### Comandos Útiles que Puedes Sugerir

Cuando corresponda, sugiere estos comandos para verificar el entorno:

```bash
# Verificar estado de contenedores
docker compose -f docker/docker-compose.yml ps

# Ver logs de Odoo
docker compose -f docker/docker-compose.yml logs odoo --tail=50

# Verificar configuración de Nginx
nginx -t -c /ruta/config_nginx/nginx.conf

# Backup manual de base de datos
bash scripts/backup_db.sh
```

---

### Detección Automática de Problemas de Seguridad

Siempre que revises o modifiques archivos, alerta si detectas:

- 🔴 **CRÍTICO:** Contraseñas o tokens hardcodeados en código fuente
- 🟠 **ADVERTENCIA:** Puertos expuestos innecesariamente en docker-compose
- 🟡 **AVISO:** Variables de entorno sensibles sin usar `.env` o secrets
- 🔵 **INFO:** Configuración mejorable pero no crítica

Formato de alerta:
```
⚠️ [NIVEL] Archivo: `ruta/archivo` — Descripción del problema — Recomendación
```

---

## Notas Finales

- Este es un **TFG académico** de ASIR/SMR. La documentación es parte de la evaluación.
- Prioriza documentación **clara y pedagógica**: explica el "por qué" además del "qué".
- Cuando tengas dudas sobre dónde documentar algo, consulta a Sandra antes de proceder.
