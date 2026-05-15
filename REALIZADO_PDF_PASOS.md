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
