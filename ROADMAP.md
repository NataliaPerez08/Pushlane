# Roadmap

El roadmap prioriza un flujo vertical funcional antes de agregar componentes.
Marca una fase como terminada solo cuando cumple sus criterios de aceptacion.

## Estado actual (2026-09-15)

Verificado contra el cluster Proxmox y las tres VMs del lab. Solo se marcan
casillas con evidencia verificable.

| Componente | Estado |
| --- | --- |
| VMs `pushlane-git/ci/app` (vmid 204/202/203) | Corriendo; SSH y guest agent activos |
| Gitea (`pushlane-git:3000`) | Instancia instalada sin asistente; org `homelab`, repos privados con contenido, `main` protegido, usuarios `devops`/`developer` en equipo `developers`, release `v0.1.0`; respaldo y restauracion verificados |
| Jenkins (`pushlane-ci:8080`) | Asistente completado; sin plugins, credenciales, nodos ni jobs |
| Agente JNLP (`pushlane-ci`) | Contenedor arriba pero sin conectar: usa `http://localhost:8080` |
| Technitium (`pushlane-git:53/5380`) | Corriendo; zona `lab.local` con 3 registros de host + 4 de servicio; gestion via API |
| Resolucion `*.lab.local` | Configurada (split DNS); resuelve desde las tres VMs |
| Registry y demo-api (`pushlane-app`) | Rol `app` aplicado (compose instalado); contenedores sin desplegar |
| OpenTofu (control en el ECS) | Estado y tfvars migrados; `tofu plan` sin cambios |

### Bloqueadores conocidos

1. Jenkins quedo en estado basico: sin plugins (Git, Pipeline, Gitea, SSH
   Agent), sin credencial `pushlane-app-ssh`, sin nodo `pushlane-agent` y con
   `numExecutors=2` en el controller (Fase 4).
2. El agente JNLP no puede conectar: `JENKINS_URL=http://localhost:8080`
   dentro del contenedor. Definir `jenkins_agent_url` en el inventario y
   registrar primero el nodo en Jenkins; al recrearlo heredara el DNS del
   daemon y resolvera `*.lab.local`.
3. El registry (:5000) y demo-api (:8000) siguen sin contenedores en
   `pushlane-app`: falta arrancar el compose del registry (o el primer
   pipeline) usando el `.env.example` del rol `app`.
4. Nota: el inventario de ejemplo usa 192.168.10.21-23 / vmid 201-203 y el
   lab real usa 10.0.0.21-23 / vmid 202-204; el `terraform.tfvars` y el
   `.tfstate` reales (gitignored) viven ahora en el ECS, nodo de control
   de Ansible y OpenTofu.

Progreso por fase: Fase 0 (4/4), Fase 1 (4/4), Fase 2 (4/4), Fase 3 (4/4),
Fases 4-11 (0).

Los hallazgos de auditoria y su remediacion se registran en
`docs/remediaciones.md`.

### Siguiente: Fase 4 (Jenkins como codigo)

1. Endurecer el controller: `numExecutors=0`, credencial de admin via
   vault y URL publica (`jenkins.lab.local:8080`) para que el agente JNLP
   conecte (hoy apunta a `localhost:8080`, bloqueador 2).
2. Plugins por CLI (`install-plugin.sh` o JCasC): Git, Pipeline, Gitea,
   SSH Agent; credenciales `pushlane-app-ssh` y de Gitea.
3. Nodo agente `pushlane-agent` (etiqueta `docker`) y job multibranch
   apuntando a `homelab/demo-api`.
4. Ejecutar Checkout, Lint y Test desde el `Jenkinsfile`; una PR en
   Gitea debe reflejar el estado del pipeline.

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

- [ ] Completar el asistente inicial y limitar ejecuciones en el controller.
- [ ] Registrar credenciales de Gitea, Registry y SSH.
- [ ] Crear un agente Linux dedicado o efimero.
- [ ] Ejecutar Checkout, Lint y Test desde el `Jenkinsfile`.

**Terminado cuando:** una PR recibe el estado del pipeline.

## Fase 5 — CI automatizada

- [ ] Configurar webhook Gitea -> Jenkins.
- [ ] Eliminar la necesidad de usar `Build Now`.
- [ ] Agregar escaneo de dependencias e imagen.
- [ ] Archivar resultados de pruebas.

**Terminado cuando:** cada push dispara CI y bloquea merges con fallos.

## Fase 6 — Build, Registry y CD

- [ ] Construir una imagen versionada por commit.
- [ ] Publicarla en el registry privado.
- [ ] Desplegarla en `pushlane-app` mediante SSH.
- [ ] Ejecutar `/health` y hacer rollback si falla.

**Terminado cuando:** un merge a `main` llega automaticamente al ambiente dev.

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

