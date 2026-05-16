# CI/CD Workflows

Esta carpeta contiene los flujos de trabajo (workflows) de GitHub Actions que automatizan las pruebas, la validación y el despliegue del proyecto `TFG-ASIRB`.

---

## 1. Validación Continua (`ci.yml`)

El pipeline de CI (**CI Validator**) se ejecuta automáticamente con cada `push` o `Pull Request` a la rama `main`. 

### Propósito
Asegurar que ningún código defectuoso o con mala sintaxis se integre en el repositorio principal.

### Pasos (Jobs)
- **YAML Linting:** Verifica que la sintaxis de todos los archivos `.yml` y `.yaml` (especialmente `docker-compose.yml`) sea válida mediante `yamllint`.
- **Validación Estructural de Docker:** Usa `docker compose config -q` para confirmar que el entorno Docker sea lógicamente correcto.
- **ShellCheck:** Analiza todos los scripts Bash/Shell (`scripts/` y `vagrant/`) buscando malas prácticas, errores lógicos o vulnerabilidades comunes (uso de comillas, variables no declaradas, etc.).
- **Markdown Linting:** Verifica el formato y la estructura de la documentación en archivos `.md` para garantizar uniformidad.

---

## 2. Despliegue Automatizado (`deploy.yml`)

El pipeline de CD (**Deployment Workflow**) es el encargado de interactuar con la infraestructura en tiempo real. 

### Infraestructura (Self-Hosted Runners)
El despliegue no usa los servidores públicos de GitHub. En su lugar, el pipeline envía los trabajos a los **Self-Hosted Runners** que se instalan y configuran automáticamente mediante Vagrant (`provision_debian.sh` y `provision_postgres.sh`):

- **`odoo-runner`** (Etiquetas: `self-hosted, linux, odoo`): Reside en la VM `vm-odoo` (Debian 13). Se encarga de clonar el código actualizado, reiniciar contenedores Docker e inyectar configuraciones.
- **`db-runner`** (Etiquetas: `self-hosted, linux, db`): Reside en la VM `vm-postgres` (Debian 13). Se encarga de aplicar scripts de auditoría en la BD y asegurar que el entorno de base de datos se mantiene alineado con la aplicación.

*(Para más detalles sobre los runners, consultar [docs/GITHUB_ACTIONS_RUNNERS.md](../docs/GITHUB_ACTIONS_RUNNERS.md))*

### Propósito
Aplicar los cambios aceptados en la rama `main` directamente sobre el entorno de producción (o el entorno Vagrant que simula producción) de manera fluida y sin intervención manual.
