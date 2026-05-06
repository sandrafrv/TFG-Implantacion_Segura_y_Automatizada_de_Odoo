# Diagrama de Red: pfSense + DMZ Docker + LAN

Este documento alberga el esquema arquitectónico completo de la infraestructura desarrollada para el TFG.

*(Pendiente: Sustituir o añadir el archivo PDF final o imagen del diagrama aquí)*

## Estructura de Red

El diagrama ilustra la separación de redes mediante **pfSense**:

- **WAN (Internet)**: Tráfico entrante público, filtrado y enviado por NAT (Port 80/443) hacia la DMZ.
- **LAN Clientes (VLAN 10 - 192.168.10.0/24)**: Red de usuarios donde residen los equipos que acceden a los servicios y administran el sistema.
- **DMZ / Servidores (VLAN 30 - 192.168.30.0/24)**: Red aislada donde se encuentra el servidor Debian (`192.168.30.10`).

### Contenedores en DMZ (Servidor Debian)
Dentro del servidor Debian, el tráfico es gestionado por Docker en la subred aislada `odoo_net` (bridge):
1. **nginx-proxy**: Recibe el tráfico web externo (puertos 80/443 mapeados al host), termina el SSL y actúa como reverse proxy hacia Odoo.
2. **odoo-web**: Servidor de aplicaciones ERP. No expone puertos al host Debian, solo es accesible por Nginx en la red Docker.
3. **odoo-db**: Base de datos PostgreSQL aislada con auditoría activa. No accesible desde el host, solo desde `odoo-web`.

> **💡 Instrucción para añadir el PDF:**
> Sube el archivo `diagrama_red.pdf` a esta misma carpeta `docs/` y asegúrate de que esté referenciado en la Memoria del TFG. Si tienes el diagrama en formato imagen (PNG/JPG), puedes incrustarlo directamente aquí usando la sintaxis de Markdown: `![Diagrama de Red](./nombre_imagen.png)`
