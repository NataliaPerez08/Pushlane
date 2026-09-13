# Runbooks

Cada ejercicio debe registrar sintomas, hipotesis, comandos, hallazgo, accion,
validacion y tiempo total de recuperacion.

| Escenario | Senal inicial | Herramientas clave |
| --- | --- | --- |
| Agente Jenkins offline | Pipeline en cola | `systemctl`, logs, red, credenciales |
| Webhook roto | Push sin build | Entregas Gitea, HTTP status, logs Jenkins |
| Disco lleno | Builds/DB fallan | `df`, `du`, logs, politica de retencion |
| Certificado expirado | Error TLS | `openssl`, proxy, renovacion |
| Deploy defectuoso | Health check falla | logs, tag anterior, rollback |

## Plantilla

1. **Impacto:** que dejo de funcionar.
2. **Deteccion:** como se descubrio.
3. **Diagnostico:** evidencia en orden cronologico.
4. **Mitigacion:** accion que restauro el servicio.
5. **Causa raiz:** condicion tecnica, no culpables.
6. **Prevencion:** automatizacion, alerta o control nuevo.
7. **Metricas:** MTTD, MTTR, RPO y RTO cuando aplique.

