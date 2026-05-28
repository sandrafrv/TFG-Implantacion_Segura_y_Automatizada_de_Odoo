# LDAP — Mejora Futura

> [!WARNING]
> **LDAP no está activo en el despliegue actual.**
> OpenLDAP fue descartado del stack Docker principal por complejidad operativa y para reducir la superficie de ataque. Esta carpeta conserva el material de referencia para una posible reactivación futura.

---

## Por qué se descartó

OpenLDAP requiere mantener un directorio de usuarios, un fichero LDIF de bootstrap, un usuario `readonly` para Odoo y configuración PAM en cada cliente. Los puntos de fallo adicionales son:

- Si LDAP cae, los usuarios no pueden entrar a Odoo aunque el ERP esté perfectamente operativo.
- La sincronización entre cuentas LDAP y las de Odoo requiere mantenimiento continuo.
- Aumenta la superficie de ataque con un servicio adicional expuesto en la red.
- El modelo de autenticación nativa de Odoo es suficiente para el alcance del TFG.

---

## Contenido de esta carpeta

| Archivo | Descripción |
|:--------|:------------|
| `estructura.ldif` | Árbol de directorio completo con OUs y usuarios de ejemplo para TechSolutions S.L., listo para importar en un contenedor `osixia/openldap:1.5.0` |
| `README.md` | Este archivo |

### Scripts relacionados (en `scripts/ldap/`)

| Script | Descripción |
|:-------|:------------|
| `ldap_politica_acceso.sh` | Aplica ACLs de mínimo privilegio en el directorio LDAP |
| `ldap_crear_usuarios.sh` | Crea usuarios interactivamente en OpenLDAP |
| `configurar_cliente_ldap.sh` | Instala y configura SSSD + PAM + NSS en un cliente Debian |

---

## Arquitectura LDAP prevista

```
dc=tfg,dc=com
├── ou=usuarios         ← Cuentas personales de empleados
│   ├── uid=jdoe
│   └── uid=mbrown
├── ou=grupos           ← Grupos departamentales
│   ├── cn=becarios     (VLAN 10)
│   ├── cn=ventas       (VLAN 10)
│   ├── cn=rrhh         (VLAN 10)
│   ├── cn=almacen      (VLAN 10)
│   ├── cn=tecnico      (VLAN 10 — puede cambiar contraseñas)
│   ├── cn=admin        (VLAN 40 — acceso total)
│   └── cn=dba          (VLAN 40 — solo base de datos)
└── ou=servicios        ← Cuentas técnicas
    ├── cn=readonly     (Odoo + PAM usan esta para bind)
    └── cn=api
```

---

## Cómo reactivar en el futuro

### Paso 1 — Añadir el servicio LDAP al stack Docker

En `docker/docker-compose.yml`, añadir:

```yaml
ldap:
  image: osixia/openldap:1.5.0
  container_name: openldap
  environment:
    LDAP_ORGANISATION: "TechSolutions S.L."
    LDAP_DOMAIN: "tfg.com"
    LDAP_ADMIN_PASSWORD: "${LDAP_ADMIN_PASSWORD}"
    LDAP_READONLY_USER: "true"
    LDAP_READONLY_USER_USERNAME: "readonly"
    LDAP_READONLY_USER_PASSWORD: "${LDAP_READONLY_PASSWORD}"
  volumes:
    - ldap-data:/var/lib/ldap
    - ldap-config:/etc/ldap/slapd.d
    - ./extras/ldap/estructura.ldif:/container/service/slapd/assets/config/bootstrap/ldif/custom/estructura.ldif:ro
  networks:
    odoo_net:
      ipv4_address: 172.19.0.5
    macvlan_vlan30:
      ipv4_address: 192.168.30.22
  restart: unless-stopped
```

### Paso 2 — Aplicar estructura y ACLs

```bash
# Cargar estructura LDIF
docker exec openldap ldapadd -x \
  -D "cn=admin,dc=tfg,dc=com" -w "${LDAP_ADMIN_PASSWORD}" \
  -f /container/service/slapd/assets/config/bootstrap/ldif/custom/estructura.ldif

# Aplicar ACLs
bash scripts/ldap/ldap_politica_acceso.sh

# Crear usuarios
bash scripts/ldap/ldap_crear_usuarios.sh
```

### Paso 3 — Conectar Odoo con LDAP

En Odoo: **Ajustes → Técnico → Autenticación → Servidor LDAP**

| Campo | Valor |
|:------|:------|
| Servidor LDAP | `192.168.30.22` |
| Puerto | `389` |
| DN de empresa | `dc=tfg,dc=com` |
| Usuario readonly | `cn=readonly,dc=tfg,dc=com` |
| Contraseña readonly | `${LDAP_READONLY_PASSWORD}` |
| Filtro de usuarios | `(uid=%s)` |

### Paso 4 — (Opcional) Configurar clientes VLAN 10

```bash
# Ejecutar en cada PC cliente Debian de VLAN 10
sudo bash scripts/ldap/configurar_cliente_ldap.sh
```

---

## Recursos de referencia

- [Documentación osixia/openldap](https://github.com/osixia/docker-openldap)
- [Integración Odoo-LDAP](https://www.odoo.com/documentation/17.0/applications/general/auth/ldap.html)
- Scripts relacionados: `scripts/ldap/`
- Guía extendida: `docs/guias/GUIA_COMPLETA.md` (Apéndice C — LDAP)

---

*TFG ASIR 2025/2026 — IES Cañaveral*
