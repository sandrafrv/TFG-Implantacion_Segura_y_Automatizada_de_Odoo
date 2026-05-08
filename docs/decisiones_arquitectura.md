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
