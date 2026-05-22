# Guion de Presentación TFG — Enfoque en Infraestructura como Código (IaC)

> **Duración estimada:** 15-20 minutos
> **Audiencia:** Tribunal evaluador (perfil técnico: profesores de ASIR)
> **Hilo conductor:** Cómo hemos pasado de la clásica "instalación a mano" a un entorno completamente automatizado, predecible y versionable (GitOps e IaC).

---

## 1. Introducción y Planteamiento del Problema (2 min)

*   **Saludo:** "Buenos días al tribunal. Soy Sandra Fradejas y hoy os presento mi Trabajo de Fin de Grado: *Implantación Segura y Automatizada de Odoo*."
*   **El Problema:** "Tradicionalmente, en la administración de sistemas, montar una infraestructura como esta implicaba horas de clics: instalar ISOs manualmente, configurar IPs, instalar bases de datos, configurar firewalls regla por regla... Esto genera un problema grave: el factor humano. Si el servidor se cae, replicarlo exactamente igual es casi imposible."
*   **La Solución (El hilo conductor):** "Por eso, he diseñado este proyecto basándome en una filosofía moderna de DevOps: la **Infraestructura como Código (IaC)** y la automatización total. Mi objetivo era que, con un solo comando, se levantara toda la arquitectura de red, servidores y seguridad de forma idéntica cada vez."

---

## 2. Arquitectura General y Segmentación de Red (3 min)

*   **Diseño de Red (Zero Trust):** "Antes de hablar de código, veamos qué vamos a construir. He diseñado una arquitectura de red segmentada mediante **pfSense**."
    *   **VLAN 10 (LAN):** Donde están los usuarios normales.
    *   **VLAN 30 (DMZ):** Donde reside el servidor Odoo (Docker).
    *   **VLAN 40 (Admin/BD):** La joya de la corona. Una red aislada donde reside el servidor de base de datos PostgreSQL nativo y desde donde se administra todo.
*   **Seguridad:** "Un usuario de la LAN no puede llegar a la base de datos, ni hacer SSH al servidor. Todo pasa obligatoriamente por el proxy inverso Nginx."

---

## 3. Infraestructura como Código: Vagrant y Provisioning (4 min)

*   **Vagrantfile (La receta base):** "Aquí es donde entra la IaC. Toda esta infraestructura de 3 máquinas virtuales (Firewall, Servidor Web y Base de Datos) está definida en un único archivo de texto: el `Vagrantfile`."
*   **VMware Workstation:** "Utilizando Vagrant junto a VMware, defino la CPU, RAM y los adaptadores de red (VMnet1, VMnet2, VMnet3) por código."
*   **El Provisionamiento:** "Una vez Vagrant crea la 'cáscara' de la máquina, entra en juego mi suite de scripts en Bash (`provision_debian.sh`, `provision_postgres.sh`). Estos scripts hacen el trabajo duro sin que yo toque el teclado:"
    *   Instalan Docker y dependencias.
    *   Configuran redes avanzadas como **MACVLAN**.
    *   Instalan e inicializan PostgreSQL de forma remota.
    *   *Mencionar pfSense:* "Incluso el firewall pfSense se configura por código mediante un script en Bash que inyecta un archivo XML preconfigurado, ahorrando docenas de clics en la interfaz web."

---

## 4. Contenedores y Redes Avanzadas (3 min)

*   **Docker Compose:** "La capa de aplicación corre sobre contenedores. El archivo `docker-compose.yml` define Odoo y Nginx. Al tenerlo en código, el entorno de desarrollo y el de producción son idénticos."
*   **El reto técnico (MACVLAN):** "Para que el firewall pfSense pudiera filtrar tráfico a nivel de contenedor individual, implementé redes MACVLAN. Así, Nginx tiene la IP `.20` y Odoo la `.21`, siendo IPs reales dentro de la red DMZ, no IPs ocultas en la red interna de Docker."

---

## 5. El Corazón de IaC: CI/CD y GitOps (4 min)

*   **Git como Fuente de la Verdad:** "La verdadera ventaja de la IaC es poder usar Git. Todo mi código está en GitHub."
*   **Integración Continua (CI):** "He implementado flujos de trabajo (Workflows) con GitHub Actions. Cada vez que hago un *commit* o un cambio en un script, GitHub lanza herramientas como `shellcheck` o `yamllint` para asegurar que mi código no tiene errores de sintaxis antes de llegar al servidor."
*   **Despliegue Continuo (CD) con Self-Hosted Runners:** "La magia ocurre en el Despliegue. Durante la instalación automatizada, mis scripts instalan en los servidores unos agentes llamados *Self-Hosted Runners*. Si apruebo un cambio en el código de GitHub, este agente lo detecta, descarga la nueva versión y reinicia el servicio automáticamente en el servidor local de la DMZ. **Nadie tiene que entrar por SSH a hacer un git pull**."

---

## 6. Seguridad Automatizada (2 min)

*   **Hardening como Código:** "La seguridad también está automatizada. Mis scripts activan UFW cerrando todos los puertos excepto 80, 443 y 22. Deshabilitan el login de `root` por SSH."
*   **Auditoría en Base de Datos:** "A nivel de base de datos, he programado un archivo SQL con Triggers y funciones en PL/pgSQL que se inyecta automáticamente. Esto crea un registro inmutable de auditoría cada vez que se crea, modifica o elimina un usuario en Odoo."

---

## 7. Conclusión y Demo (2 min)

*   **Resumen de los beneficios:** "En conclusión, el enfoque de Infraestructura como Código me ha permitido pasar de un despliegue frágil y manual que tardaría horas en documentarse y replicarse, a un sistema documentado por defecto en su propio código, que se levanta en menos de 10 minutos con el comando `vagrant up`."
*   **Paso a Demo:** "Si el tribunal lo desea, puedo mostrar en vivo cómo el orquestador (`erp.sh`) permite gestionar todo el entorno con menús interactivos, o cómo un cambio en GitHub se despliega solo en la máquina virtual."
*   **Despedida:** "Gracias por su atención, quedo a su disposición para cualquier pregunta."

---

### 💡 Consejos para las Diapositivas
- **Poco texto:** Usa diagramas (aprovecha tu `diagrama_red.md`).
- **Muestra código (pero limpio):** Pon una captura bonita de tu `Vagrantfile` o tu `deploy.yml`. Destaca las líneas clave.
- **Capturas del flujo de Actions:** Una captura de pantalla de los "ticks" verdes de GitHub Actions queda muy profesional.
- **Demostración grabada (Plan B):** Si la presentación es en directo y dependes de VMs pesadas, graba la pantalla ejecutando el `vagrant up` y el pipeline CI/CD en un vídeo a cámara rápida (Time-Lapse) por si el PC falla durante la defensa.
