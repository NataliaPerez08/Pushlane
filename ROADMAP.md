# Roadmap

El roadmap prioriza un flujo vertical funcional antes de agregar componentes.
Marca una fase como terminada solo cuando cumple sus criterios de aceptacion.

## Estado actual (2026-09-15)

Verificado contra el cluster Proxmox y las tres VMs del lab. Solo se marcan
casillas con evidencia verificable.

| Componente | Estado |
| --- | --- |
| VMs `pushlane-git/ci/app` (vmid 204/202/203) | Corriendo; SSH y guest agent activos |
| Gitea (`pushlane-git:3000`) | Contenedores arriba; instalador inicial sin completar |
| Jenkins (`pushlane-ci:8080`) | Asistente completado; sin plugins, credenciales, nodos ni jobs |
| Agente JNLP (`pushlane-ci`) | Contenedor arriba pero sin conectar: usa `http://localhost:8080` |
| Technitium (`pushlane-git:53/5380`) | Corriendo; zona `lab.local` con 3 registros A; gestion via API |
| Resolucion `*.lab.local` | Configurada (split DNS); resuelve desde las tres VMs |
| Registry y demo-api (`pushlane-app`) | Rol `app` aplicado (compose instalado); contenedores sin desplegar |

### Bloqueadores conocidos

1. Gitea muestra el asistente de instalacion: falta completarlo, crear la
   organizacion `homelab`, repos, proteccion de `main` y webhook (Fase 3).
2. Jenkins quedo en estado basico: sin plugins (Git, Pipeline, Gitea, SSH
   Agent), sin credencial `pushlane-app-ssh`, sin nodo `pushlane-agent` y con
   `numExecutors=2` en el controller (Fase 4).
3. El agente JNLP no puede conectar: `JENKINS_URL=http://localhost:8080`
   dentro del contenedor. Definir `jenkins_agent_url` en el inventario y
   registrar primero el nodo en Jenkins; al recrearlo heredara el DNS del
   daemon y resolvera `*.lab.local`.
4. El registry (:5000) y demo-api (:8000) siguen sin contenedores en
   `pushlane-app`: falta arrancar el compose del registry (o el primer
   pipeline) usando el `.env.example` del rol `app`.
5. El `.tfstate` y `terraform.tfvars` reales viven en otra maquina; el nodo
   ECS es ahora nodo de control de Ansible (inventario y vaults propios) pero
   no puede ejecutar `tofu plan`. Nota: el ejemplo usa 192.168.10.21-23 /
   vmid 201-203 y el lab real usa 10.0.0.21-23 / vmid 202-204.

Progreso por fase: Fase 0 (4/4), Fase 1 (3/4), Fase 2 (4/4), Fases 3-11 (0).

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
- [ ] Probar que un segundo `tofu plan` no produce cambios inesperados.

**Terminado cuando:** las tres VMs pueden recrearse desde cero.

## Fase 2 — Configuracion con Ansible

- [x] Generar inventario real desde el archivo de ejemplo.
- [x] Instalar Docker Engine y dependencias base.
- [x] Aplicar los roles `gitea`, `jenkins` y `app`.
- [x] Ejecutar nuevamente el playbook y verificar idempotencia.

**Terminado cuando:** el segundo playbook termina sin cambios injustificados.

## Fase 3 — Administracion de Gitea

- [ ] Crear organizacion `homelab` y repositorios `demo-api` e `infrastructure`.
- [ ] Crear usuarios/roles de developer, devops y admin.
- [ ] Configurar llaves SSH, proteccion de `main`, PRs y releases.
- [ ] Probar backup y restauracion de un repositorio.

**Terminado cuando:** `main` solo acepta cambios mediante PR validada.

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

