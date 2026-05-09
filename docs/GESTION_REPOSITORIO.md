# Guía de Gestión del Repositorio

Bienvenido a la guía de operaciones del repositorio `TFG-ASIRB`. Este documento sirve como manual para entender la estructura del proyecto y cómo interactuar con él, tanto a nivel de desarrollo como de administración.

## 📁 Estructura del Repositorio

El proyecto está organizado de la siguiente manera:

- **`.github/workflows/`**: Contiene el pipeline CI/CD (validación estática y despliegue automatizado).
- **`config/`**: Archivos de configuración general (ej. rotación de logs de cron).
- **`config_nginx/`**: Configuración del proxy inverso Nginx.
- **`docker/`**: Fichero `docker-compose.yml`, `.env.example` y configuraciones nativas de Odoo.
- **`docs/`**: Documentación técnica, manuales, historial de implementación e issues.
  - `archive/`: Contiene los documentos históricos de planificación por fases.
- **`ISOs/`**: Imágenes de sistema operativo (Debian, pfSense) necesarias para el TFG.
- **`ldap/`**: (Si aplica) Configuraciones específicas para el servicio OpenLDAP.
- **`scripts/`**: Automatización de operaciones, dividida en:
  - `deploy/`: Scripts para levantar el servicio y configurar el entorno.
  - `odoo/`: Configuración interna del ERP y usuarios.
  - `ldap/`: Scripts para gestionar identidades LDAP.
  - `mantenimiento/`: Backups, restauración, monitoreo y actualización.
- **`sql/`**: Triggers de auditoría y base de datos (PL/pgSQL).
- **`install.sh`**: Instalador raíz todo-en-uno.

---

## 🔄 Flujo de Trabajo (GitOps)

El despliegue está automatizado. Sigue esta metodología para hacer cambios:

1. **Modificación Local**: Edita los archivos localmente en tu ordenador (ej. cambiar un script o configuración).
2. **Commit y Push**: Haz commit de tus cambios a la rama `main` en GitHub.
3. **Validación CI**: Automáticamente, GitHub Actions validará el código (Shellcheck, YAML lint, Markdown lint).
4. **Despliegue CD**: Si el CI pasa correctamente, el **Self-Hosted Runner** en el servidor Debian descargará los cambios y aplicará la configuración en producción de manera segura.

*Nunca edites scripts o archivos de configuración directamente en el servidor de producción.*

---

## 🛠️ Uso de las Herramientas

Para administrar el ERP en el día a día, utiliza los scripts proporcionados en la carpeta `scripts/`. Todos deben ejecutarse con permisos en el servidor Debian.

### Tareas comunes:
- **Hacer un volcado de base de datos:** `sudo ./scripts/mantenimiento/backup.sh`
- **Actualizar Odoo:** `sudo ./scripts/mantenimiento/update.sh`
- **Menú interactivo:** `sudo ./scripts/deploy/erp.sh`
- **Crear un empleado masivo:** `sudo ./scripts/ldap/ldap_crear_usuarios.sh`

> Para una lista completa, revisa [scripts/README.md](../scripts/README.md).

---

## 📝 Actualización de Documentación

Mantener el proyecto sano requiere documentación al día:

1. **CHANGELOG.md**: Cada vez que agregues una funcionalidad (ej. un nuevo script o cambio de red), añade una línea al changelog bajo la versión actual.
2. **README.md**: Solo debes actualizarlo si la arquitectura cambia (ej. añadir un contenedor nuevo).
3. **github_issues.md**: Usa estas plantillas si vas a crear issues en GitHub para planificar tu trabajo.
4. **Capturas (`screenshots/`)**: Nombra siempre las imágenes con la fase a la que pertenecen (ej. `fase_C_login_ldap.png`).
