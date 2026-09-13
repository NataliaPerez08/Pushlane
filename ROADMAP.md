# Roadmap

El roadmap prioriza un flujo vertical funcional antes de agregar componentes.
Marca una fase como terminada solo cuando cumple sus criterios de aceptacion.

## Fase 0 — Diseno y preparacion

- [ ] Reservar tres IPs y crear registros DNS internos.
- [ ] Crear una plantilla cloud-init en Proxmox.
- [ ] Crear usuario/token de API con privilegios minimos.
- [ ] Documentar VLAN, bridge, gateway y almacenamiento elegidos.

**Terminado cuando:** las decisiones estan en `docs/architecture.md` y no hay
secretos dentro del repositorio.

## Fase 1 — Infraestructura reproducible

- [ ] Completar `terraform.tfvars`.
- [ ] Ejecutar `tofu fmt`, `tofu validate`, `tofu plan` y `tofu apply`.
- [ ] Verificar red y acceso SSH a las tres VMs.
- [ ] Probar que un segundo `tofu plan` no produce cambios inesperados.

**Terminado cuando:** las tres VMs pueden recrearse desde cero.

## Fase 2 — Configuracion con Ansible

- [ ] Generar inventario real desde el archivo de ejemplo.
- [ ] Instalar Docker Engine y dependencias base.
- [ ] Aplicar los roles `gitea`, `jenkins` y `app`.
- [ ] Ejecutar nuevamente el playbook y verificar idempotencia.

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

