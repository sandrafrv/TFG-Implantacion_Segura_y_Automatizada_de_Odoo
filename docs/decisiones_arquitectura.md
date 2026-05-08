# Decisiones de Arquitectura

## Segmentación de red — NICs separadas vs. 802.1Q trunk

### Decisión adoptada
En el entorno de laboratorio se ha asignado una interfaz de red virtual (VMnet)
independiente a cada VLAN:

| VLAN | ID | Red | Interfaz VMware |
|------|-----|-------------------|------------------|
| Clientes | 10 | 192.168.10.0/24 | VMnet1 |
| DMZ | 30 | 192.168.30.0/24 | VMnet2 |
| Admin/DBA | 40 | 192.168.40.0/24 | VMnet3 |

### Justificación
VMware Workstation Pro no soporta etiquetado 802.1Q en sus adaptadores virtuales.
Cada VMnet actúa como una red plana aislada sin soporte de trunk nativo.
Forzar 802.1Q requeriría VMware ESXi o un switch gestionable físico, no disponible
en este laboratorio académico.

El aislamiento conseguido es funcionalmente equivalente: todo el tráfico inter-VLAN
pasa exclusivamente por pfSense, igual que en un entorno trunk real.

### Mejora futura — 802.1Q en producción
En un despliegue en producción se implementaría un trunk 802.1Q (IEEE 802.1Q)
entre pfSense y un switch gestionable, con la siguiente topología:

```
Switch gestionable → Puerto trunk → pfSense (1 sola NIC física)
  ├── em0.10  → VLAN 10 Clientes
  ├── em0.30  → VLAN 30 DMZ
  └── em0.40  → VLAN 40 Admin/DBA
```

| Aspecto | Lab actual (NICs separadas) | Producción (802.1Q trunk) |
|---|---|---|
| NICs físicas necesarias | 1 por VLAN + 1 WAN | 2 (WAN + trunk) |
| Escalabilidad | Añadir VLAN = añadir NIC | Solo nueva subinterfaz |
| Coste hardware | Mayor | Menor |
| Gestión | Física | Lógica desde switch |
| Estándar | No estándar | IEEE 802.1Q |
| Plataforma requerida | VMware Workstation | ESXi / switch gestionable |

---

## Gestión de usuarios — OpenLDAP en Docker vs. usuarios locales Odoo

### Decisión adoptada
Se integra un contenedor **OpenLDAP** (`osixia/openldap:1.5.0`) dentro del stack Docker
existente en la VLAN 30 (DMZ), junto a Odoo, PostgreSQL y Nginx.

Los usuarios de cada departamento se definen en LDAP y Odoo los autentica
a través del módulo de autenticación LDAP nativo (Ajustes → Técnico → LDAP).

### Justificación
Gestionar los usuarios únicamente dentro de Odoo presenta las siguientes limitaciones:

- Las credenciales quedan acopladas al ERP: si se migra o reinstala Odoo, se pierden o deben recrearse manualmente.
- No existe un punto centralizado de autenticación reutilizable por otros servicios futuros (VPN, wiki, monitorización).
- El principio de separación de responsabilidades recomienda que la identidad de los usuarios sea independiente de la aplicación que los consume.

Con OpenLDAP en Docker se consigue:

- **Directorio centralizado**: un único lugar donde crear, modificar o deshabilitar usuarios.
- **Reutilizable**: cualquier servicio que soporte LDAP (Nginx, Grafana, GitLab, VPN) puede autenticarse contra el mismo directorio.
- **Base para SSO**: preparado para integrar Keycloak u OAuth2 Proxy en el futuro.
- **Sin VM adicional**: al correr como contenedor Docker, no consume recursos extra significativos.

### Estructura del directorio LDAP

```
dc=empresa,dc=local
 └── ou=users
       ├── uid=ventas.usuario
       ├── uid=ventas.jefe
       ├── uid=rrhh.usuario
       ├── uid=rrhh.jefe
       ├── uid=almacen.usuario
       ├── uid=almacen.jefe
       ├── uid=conta.contable
       ├── uid=conta.jefe
       └── uid=it.admin
```

### Parámetros de integración Odoo → LDAP

| Parámetro | Valor |
|---|---|
| Servidor LDAP | `openldap` (nombre del contenedor) |
| Puerto | `389` |
| DN base | `dc=empresa,dc=local` |
| Filtro de usuario | `uid=%s,ou=users,dc=empresa,dc=local` |
| Usuario bind | `cn=admin,dc=empresa,dc=local` |
| Contraseña bind | variable de entorno `LDAP_ADMIN_PASSWORD` |

### Mejora futura — TLS sobre LDAP (LDAPS)
En producción se habilitaría LDAPS (puerto 636) con certificado TLS para cifrar
las credenciales en tránsito. En el laboratorio se omite al circular el tráfico
dentro de la red Docker interna (no expuesto fuera de la VLAN 30).

| Aspecto | Lab actual (LDAP sin TLS) | Producción (LDAPS) |
|---|---|---|
| Puerto | 389 | 636 |
| Cifrado | No (red interna Docker) | TLS/SSL |
| Certificado | No requerido | CA propia o Let's Encrypt |
| Exposición | Solo VLAN 30 interna | Controlada por firewall |
