REHALIZADO 
----------------------------------------------
Acabar PDF
Comprobar que todo lo del PDF funciona
Hacer que los scripts los ejecute el GitHub
GitHub compruebe si estan ejecutando o si se han ejecutado
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


NO	PASO 5 - Automatizar VMs con Vagrant

NO --------- PASO 5A - Instalar en el PC (PowerShell como administrador)

NO --------- PASO 5B - Crear Vagrantfile en la raíz del repositorio

NO --------- PASO 5C -  Crear vagrant/provision_debian.sh

NO --------- PASO 5D -  Crear vagrant/provision_pfsense.sh


NO	PASO 6 - Activar CI/CD (instalar self-hosted runner)

NO --------- PASO 6A - Obtener token en GitHub

NO --------- PASO 6B - Ejecutar en el servidor Debian (servidor Odoo)

NO --------- PASO 6C -  Verifcar que el runner está conectado

NO --------- PASO 6D -  Probar el pipeline completo


NO	PASO 7 - Backups automáticos de PostgreSQL

NO --------- PASO 7A - Crear scripts/mantenimiento/backup_postgres.sh

NO --------- PASO 7B - Instalar el cron en el servidor


