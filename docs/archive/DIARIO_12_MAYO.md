# Diario de Sesión — 12 Mayo 2026
## Resolución de incidencias: VMware + OpenLDAP

---

## 1. Error de arranque VMware Workstation

**Síntoma:** Al intentar iniciar las VMs aparecía el error:
> "Failed to connect pipe to virtual machine: Todas las instancias de canalización están en uso"

**Causa:** Procesos VMX anteriores seguían activos ocupando los pipes.

**Solución:** Ejecutar en PowerShell como administrador:
```powershell
Get-Process vmware* | Stop-Process -Force
Get-Process vmnetdhcp | Stop-Process -Force
```
Resultado: VMware abrió correctamente y las VMs aparecieron en estado suspendido.

---

## 2. Arranque ordenado de las VMs

Orden correcto de arranque:
1. **pfSense** (router/firewall)
2. **Debian** (servidor Odoo + Docker)
3. **Lubuntu** (cliente)

---

## 3. Contenedor OpenLDAP en estado Restarting

**Síntoma:** `sudo docker ps` mostraba `openldap` en `Restarting (1)`.

**Causa raíz detectada progresivamente:**

### 3.1 — El stack de Docker no estaba levantado
```bash
cd /opt/erp-odoo/docker
sudo docker compose up -d
```

### 3.2 — Fichero LDIF montado como read-only
**Error en logs:**
chown: changing ownership of '/container/service/slapd/assets/config/bootstrap/ldif/custom/estructura.ldif': Read-only file system

text
**Causa:** El `docker-compose.yml` montaba el fichero con `:ro`.

**Solución:** Eliminar `:ro` del volumen:
```yaml
# Antes:
- ../ldap/estructura.ldif:/container/service/.../estructura.ldif:ro
# Después:
- ../ldap/estructura.ldif:/container/service/.../estructura.ldif
```
Comando usado para editar:
```bash
sudo sed -i 's|estructura.ldif:ro|estructura.ldif|g' /opt/erp-odoo/docker/docker-compose.yml
```

### 3.3 — TLS habilitado sin certificados
**Error en logs:**
sed: can't read /container/service/slapd/assets/config/tls/tls-enable.ldif: No such file or directory

text
**Solución:** Añadir `LDAP_TLS: "false"` al `environment` del servicio en `docker-compose.yml`.

### 3.4 — Volúmenes con estado TLS previo (bloqueando LDAP_TLS=false)
**Error en logs:**
WARNING: LDAP_TLS=false but the container was previously started with LDAP_TLS=true. TLS can't be disabled once added.

text
**Solución:** Limpiar los volúmenes persistentes y reiniciar desde cero:
```bash
sudo docker stop openldap && sudo docker rm openldap
sudo rm -rf /opt/erp-odoo/ldap_data/* /opt/erp-odoo/ldap_config/*
sudo docker compose -f /opt/erp-odoo/docker/docker-compose.yml up -d
```
> ⚠️ Los datos LDAP se recrean automáticamente desde `estructura.ldif` al arrancar.

### 3.5 — Variable LDAP_READONLY_PASSWORD no definida
**Síntoma:** Warning al hacer `docker compose up`:
WARN: The "LDAP_READONLY_PASSWORD" variable is not set. Defaulting to a blank string.

text
**Solución:**
```bash
echo "LDAP_READONLY_PASSWORD=ReadOnly123" >> /opt/erp-odoo/docker/.env
```

---

## Estado final de la sesión

| Contenedor     | Estado  |
|----------------|---------|
| `odoo_erp`     | Healthy |
| `odoo-web`     | Healthy |
| `nginx-proxy`  | Healthy |
| `openldap`     | **Up** ✅ |

---

## Próximos pasos pendientes

- [ ] Verificar que LDAP responde con `ldapsearch`
- [ ] Configurar servidor LDAP en pfSense (System > User Manager > Authentication Servers)
- [ ] Probar autenticación en **Diagnostics > Authentication**
- [ ] Confirmar que pfSense muestra `member of groups: admin`