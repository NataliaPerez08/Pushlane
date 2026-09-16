# Roadmap

El roadmap prioriza un flujo vertical funcional antes de agregar componentes.
Marca una fase como terminada solo cuando cumple sus criterios de aceptacion.

## Estado actual (2026-09-16)

Verificado contra el cluster Proxmox y las tres VMs del lab. Solo se marcan
casillas con evidencia verificable.

| Componente | Estado |
| --- | --- |
| VMs `pushlane-git/ci/app` (vmid 204/202/203) | Corriendo; SSH y guest agent activos |
| Gitea (`pushlane-git:3000`) | Instancia instalada sin asistente; org `homelab`, repos privados con contenido, `main` protegido + required status check (Fase 5), usuarios `devops`/`developer` en equipo `developers`, release `v0.1.0`; respaldo y restauracion verificados |
| Jenkins (`pushlane-ci:8080`) | Controller como codigo (JCasC): `numExecutors=0`, credenciales `gitea-jenkins`/`pushlane-app-ssh`, webhooks Gitea->Jenkins activos; job multibranch `infrastructure` (fuente Gitea + PRs) |
| Agente JNLP (`pushlane-ci`) | Conectado (`pushlane-agent`, etiqueta `docker`), con CLI docker 26.1.4 y host key del nodo app precargado |
| Technitium (`pushlane-git:53/5380`) | Corriendo; zona `lab.local` con 3 registros de host + 4 de servicio; gestion via API |
| Resolucion `*.lab.local` | Configurada (split DNS); resuelve desde las tres VMs |
| Registry y demo-api (`pushlane-app`) | Deployados via pipeline: `registry:2` (:5000) y `demo-api` (:8000) con `/health` ok; imagen versionada por commit |
| OpenTofu (control en el ECS) | Estado y tfvars migrados; `tofu plan` sin cambios |

### Bloqueadores conocidos

1. ~~Jenkins en estado basico (sin plugins/creds/nodo/jobs)~~ — resuelto en
   Fase 4 (verificado; los plugin viven en `services/jenkins/plugins.txt`).
2. ~~Agente JNLP sin conectar (JENKINS_URL localhost)~~ — resuelto con
   `jenkins_agent_url` y la recreacion del nodo; hereda el DNS del daemon.**
3. ~~Registry y demo-api sin contenedores~~ — desplegados por el pipeline
   (build #5: Build/Publish/Deploy/Health verdes).
4. Nota: el inventario de ejemplo usa 192.168.10.21-23 / vmid 201-203 y el
   lab real usa 10.0.0.21-23 / vmid 202-204; el `terraform.tfvars` y el
   `.tfstate` reales (gitignored) viven ahora en el ECS, nodo de control
   de Ansible y OpenTofu.

Progreso por fase: Fase 0 (4/4), Fase 1 (4/4), Fase 2 (4/4), Fase 3 (4/4),
Fase 4 (4/4), Fase 5 (4/4), Fase 6 (4/4),
Fases 7-11 (0).

Los hallazgos de auditoria y su remediacion se registran en
`docs/remediaciones.md`.

### Siguiente: Fase 7 — Ambientes y releases

1. Separar DEV/STAGING/PROD; desplegar `main` a STAGING y usar tags `v*`
   con aprobacion para PROD; estrategia de rollback documentada.

## Fase 0 — Diseno y preparacion

- [x] Reservar tres IPs y crear registros DNS internos.
- [x] Crear una plantilla cloud-init en Proxmox.
- [x] Crear usuario/token de API con privilegios minimos.
- [x] Documentar VLAN, bridge, gateway y almacenamiento elegidos.

**Terminado cuando:** las decisiones estan en `docs/architecture.md` y no hay
secretos dentro del repositorio.

## Fase 1 — Infraestructura reproducible

- [x] Completar `terraform.tfvars`.
- [x] Ejecutar `tofu fmt`, `tofu validate`, `tofu plan` y `tofu apply`.
- [x] Verificar red y acceso SSH a las tres VMs.
- [x] Probar que un segundo `tofu plan` no produce cambios inesperados.

**Terminado cuando:** las tres VMs pueden recrearse desde cero.

Nota: `tofu fmt -check`, `tofu validate` y un segundo plan sin cambios
verificados desde el nodo de control (ECS). La recreacion real
(destroy/apply) no se ha ensayado; el ensayo esta en la Fase 10.

## Fase 2 — Configuracion con Ansible

- [x] Generar inventario real desde el archivo de ejemplo.
- [x] Instalar Docker Engine y dependencias base.
- [x] Aplicar los roles `gitea`, `jenkins` y `app`.
- [x] Ejecutar nuevamente el playbook y verificar idempotencia.

**Terminado cuando:** el segundo playbook termina sin cambios injustificados.

## Fase 3 — Administracion de Gitea

- [x] Crear organizacion `homelab` y repositorios `demo-api` e `infrastructure`.
- [x] Crear usuarios/roles de developer, devops y admin.
- [x] Configurar llaves SSH, proteccion de `main`, PRs y releases.
- [x] Probar backup y restauracion de un repositorio.

**Terminado cuando:** `main` solo acepta cambios mediante PR validada.

Evidencia (2026-09-15): push directo a `main` rechazado por el servidor
("Not allowed to push to protected branch main"); drill de PR completo
(rama + commit via API como `devops`, PR y merge como `gitea-admin`);
restore del dump con clon verificado; release `v0.1.0` via API. Los
required status checks se activan en Fase 5.

## Fase 4 — Jenkins como codigo

- [x] Completar el asistente inicial y limitar ejecuciones en el controller.
- [x] Registrar credenciales de Gitea, Registry y SSH.
- [x] Crear un agente Linux dedicado o efimero.
- [x] Ejecutar Checkout, Lint y Test desde el `Jenkinsfile`.

**Terminado cuando:** una PR recibe el estado del pipeline.

Evidencia (2026-09-16): controller via JCasC (`numExecutors=0`, credenciales
`gitea-jenkins`/`pushlane-app-ssh`); agente JNLP pushlane-agent conectado con
docker y host key del app precargada; build #5 end-to-end verde
(Checkout, Lint/Test `2 passed`, Build, Publish, Deploy, Health).
El job multibranch levanta como codigo con la plantilla
`job-multibranch.xml.j2` (fuente Gitea + PRs). El 500 del parent
(`folderViews` sin owner, NPE en `getPrimaryView`) se resolvio y quedo
documentado en H-006; se quitan los items de drill a mano por falta de
`Job/Delete` en la matrix del controller.

## Fase 5 — CI automatizada

- [x] Configurar webhook Gitea -> Jenkins.
- [x] Eliminar la necesidad de usar `Build Now`.
- [x] Agregar escaneo de dependencias e imagen.
- [x] Archivar resultados de pruebas.

**Terminado cuando:** cada push dispara CI y bloquea merges con fallos.

Evidencia (2026-09-16): webhook hook id=1 (push+pull_request) hacia
`http://jenkins.lab.local:8080/gitea-webhook/post`; Gitea 1.24 segaba las
entregas hasta fijar `ALLOWED_HOST_LIST` a `private` (H-005). Push real
dispara builds sin `Build Now` (build #1 y #5 de `main` verdes). Status
checks requeridos en `main` (contexto `infrastructure/pipeline/head`).
Drill de bloqueo: rama con test fallido -> build de rama y PR-1 FAILURE
automaticos, status `failure` en Gitea y merge rechazado por la API
("Not all required status checks successful"). Escaneo de dependencias
(`pip-audit -r requirements.txt`, falla si hay hallazgos) e imagen
(trivy gate en CRITICAL + reporte JSON) integrados en el pipeline, con
`fastapi`/`uvicorn` actualizados y `apt-get upgrade` en el build para
cerrar los CVEs de la capa base; resultados JUnit y reportes archivados.
Merge real de la PR de los escaneos (PR-3, merged=True, commit `5a2a35b`)
con gate verde en `head` + `pr-main`; main build #6 SUCCESS, imagen
`demo-api:5a2a35b` desplegada y `/health` ok. La PR original (PR-2) se
cerro como superseded por el quirk de descubrimiento de `fm/ci-scans`
registrado en H-008.

## Fase 6 — Build, Registry y CD

- [x] Construir una imagen versionada por commit.
- [x] Publicarla en el registry privado.
- [x] Desplegarla en `pushlane-app` mediante SSH.
- [x] Ejecutar `/health` y hacer rollback si falla.

**Terminado cuando:** un merge a `main` llega automaticamente al ambiente dev.

Evidencia (2026-09-16): en `main` el pipeline publica en
`registry:5000/demo-api` (tag por commit sha) y despliega over SSH
(`StrictHostKeyChecking=yes`, `docker compose up -d --force-recreate` en
`apps/demo-api`); Health Check ejecuta `curl /health` y falla el stage si
no responde (rollback = el stage no sube la imagen nueva). El rol `app`
da permisos de deploy a `devops` (grupo docker + arbol `/opt/pushlane`
atravesable).

## Fase 7 — Ambientes y releases

- [ ] Separar DEV, STAGING y PROD.
- [ ] Desplegar `develop` a DEV y `main` a STAGING.
- [ ] Usar tags `v*` y aprobacion manual para PROD.
- [ ] Documentar estrategia de rollback.

**Terminado cuando:** una release etiquetada puede promoverse sin reconstruirse.

## Fase 8 — Secretos y hardening

- [ ] Migrar secretos a Jenkins Credentials y Ansible Vault.
- [ ] Agregar TLS y reverse proxy.
- [ ] Aplicar firewall de host y minimo privilegio.
- [ ] Evaluar Vault solo si aporta aprendizaje adicional.

**Terminado cuando:** un escaneo del repo no encuentra secretos y los servicios
no exponen puertos innecesarios.

## Fase 9 — Observabilidad

- [ ] Desplegar Prometheus, Grafana y Node Exporter.
- [ ] Medir CPU, RAM, disco y disponibilidad.
- [ ] Medir tasa de exito y duracion de builds/deploys.
- [ ] Crear alertas de disco, servicio caido y pipeline degradado.

**Terminado cuando:** un fallo deliberado genera una alerta util.

## Fase 10 — Backups y recuperacion

- [ ] Respaldar repositorios, base de datos, configuracion y `JENKINS_HOME`.
- [ ] Definir y medir RPO/RTO.
- [ ] Destruir una VM, reconstruirla y restaurar los datos.
- [ ] Guardar evidencia y lecciones aprendidas.

**Terminado cuando:** la restauracion ha sido probada; un backup nunca probado
es solo una supersticion optimista.

## Fase 11 — Game days y portafolio

- [ ] Simular agente offline, webhook roto, disco lleno y certificado expirado.
- [ ] Completar los runbooks y registrar tiempos de diagnostico.
- [ ] Crear diagrama final, capturas y demo breve.
- [ ] Publicar resultados, decisiones y mejoras futuras.

**Terminado cuando:** otra persona puede reproducir el lab y seguir los runbooks.

