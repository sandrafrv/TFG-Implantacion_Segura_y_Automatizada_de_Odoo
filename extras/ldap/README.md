# LDAP — Mejora Futura

La integracion con OpenLDAP fue disenada durante el proyecto pero queda
fuera del alcance de la version actual por complejidad operativa.

## Por que se descarto

OpenLDAP requiere mantener un directorio de usuarios, un fichero LDIF de
bootstrap, un usuario `readonly` para Odoo y configuracion PAM en cada
cliente. Son varios puntos de fallo adicionales:

- Si LDAP cae, los usuarios no pueden entrar a Odoo aunque el ERP este
  perfectamente operativo.
- La sincronizacion entre las cuentas LDAP y las de Odoo requiere
  mantenimiento continuo.
- Aumenta significativamente la superficie de ataque.

## Lo que habia implementado

Los ficheros de esta carpeta contienen la estructura LDIF (`estructura.ldif`)
con los OUs y usuarios de ejemplo para la organizacion TechSolutions SL,
preparados para importarse en un contenedor `osixia/openldap:1.5.0`.

## Como retomarlo en el futuro

1. Anadir el servicio `ldap` en `docker/docker-compose.yml` apuntando al
   fichero `extras/ldap/estructura.ldif`.
2. Configurar Odoo para autenticar usuarios via LDAP:
   `Ajustes -> Tecnico -> Autenticacion -> Servidor LDAP`.
3. (Opcional) Configurar PAM + SSSD en las VMs de VLAN 10 para login
   de sistema operativo con credenciales LDAP.

Ver seccion de Proyectos Futuros de la memoria del TFG.
