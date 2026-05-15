REHALIZADO 
----------------------------------------------
4. PASO A PASO


NO 	PASO 1 - Quitar LDAP del proyecto

SI --------- PASO 1A — docker/docker-compose.yml — eliminar el bloque completo de LDAP

SI --------- PASO 1B — .env.example — eliminar las variables de LDAP

NO ---------PASO 1C — Mover la carpeta ldap/


NO	PASO 2 - Separar PostgreSQL en VM propia (VLAN 40)

SI --------- PASO 2A - modificar docker/docker-compose.yml para que Odoo apunte a BDD externa 

SI --------- PASO 2B - Crear vagrant/provision_postgres.sh (para la VM de BDD)

NO	--------- PASO 2C -  Reglas en pfSense


NO	PASO 3 - Abrir accesos esterbos HTTPS


NO	PASO 4 - VPN para teletrabajo (OpenVPN en pfSense)

NO --------- PASO 4A - Crear la Autoridad Certi cadora

NO --------- PASO 4B - Crear el certi cado del servidor VPN

NO --------- PASO 4C -  Crear el servidor OpenVPN

NO --------- PASO 4D -  Regla de rewall para OpenVPN

NO --------- PASO 4E -  Crear un usuario VPN

NO --------- PASO 4F -  Exportar el fichero .ovpn
