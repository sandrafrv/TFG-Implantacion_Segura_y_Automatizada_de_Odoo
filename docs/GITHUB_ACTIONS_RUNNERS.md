# Infraestructura de GitHub Actions (Self-Hosted Runners)

**← Volver a:** [Documentación Principal](../README.md)

Para implementar el despliegue continuo (CD) y la integración continua (CI) en un entorno local y privado (simulando una red empresarial On-Premise), este proyecto hace uso de **Self-Hosted Runners** de GitHub Actions. 

Al usar runners auto-hospedados, las máquinas virtuales `vm-odoo` y `vm-postgres` pueden recibir órdenes y código directamente desde GitHub para actualizarse automáticamente, evitando la necesidad de exponer SSH al exterior.

---

## Topología de los Runners

El proyecto despliega automáticamente dos runners a través de los scripts de Vagrant:

### 1. Odoo Runner (`odoo-runner`)
- **Ubicación:** `vm-odoo` (Debian 13, IP `192.168.30.10`, VLAN 30 DMZ)
- **Instalación:** `vagrant/provision_debian.sh`
- **Etiquetas GitHub:** `self-hosted`, `linux`, `odoo`
- **Rol:** 
 Recibir actualizaciones del repositorio.
 Reconstruir o reiniciar el stack Docker (`odoo-web` y `nginx-proxy`).
 Ejecutar tests de conectividad y despliegue sobre el entorno web.

### 2. Database Runner (`db-runner`)
- **Ubicación:** `vm-postgres` (Debian 13, IP `192.168.40.10`, VLAN 40 Administración)
- **Instalación:** `vagrant/provision_postgres.sh`
- **Etiquetas GitHub:** `self-hosted`, `linux`, `db`
- **Rol:** 
 Aplicar cambios estructurales a la base de datos (triggers, vistas, nuevos esquemas).
 Mantener scripts de auditoría SQL sincronizados con el repositorio.

---

## Seguridad y Enrutamiento (Egress Control)

Los runners necesitan comunicarse **hacia fuera** (hacia los servidores de GitHub) para comprobar si hay trabajos pendientes. Sin embargo, por seguridad, las VMs no deben estar expuestas de forma directa.

Por ello, el aprovisionamiento modifica el enrutamiento de ambas máquinas para eliminar la interfaz NAT directa de Vagrant y forzar que la puerta de enlace predeterminada sea **pfSense**.

- `vm-odoo` se enruta a través de `192.168.30.1` (pfSense VLAN 30).
- `vm-postgres` se enruta a través de `192.168.40.1` (pfSense VLAN 40).

pfSense aplica reglas de inspección Egress (reglas de salida) para permitir las conexiones HTTPs (puerto 443) hacia los dominios requeridos por GitHub Actions, bloqueando el resto.

---

## Variables Necesarias

Para que Vagrant pueda registrar los runners en GitHub automáticamente al hacer `vagrant up`, es necesario configurar las siguientes variables de entorno en el host antes del despliegue:

- `GH_PAT`: Un Personal Access Token (PAT) de GitHub con alcance (scope) al repositorio para clonar código privado.
- `GH_RUNNER_TOKEN`: Un Registration Token temporal (dura 1 hora) generado desde los ajustes de Actions del repositorio en GitHub. Se inyecta a través del `Vagrantfile`.

Estos tokens aseguran que los runners quedan enlazados a tu cuenta y repositorio de forma segura sin exponer credenciales persistentes en el disco.
