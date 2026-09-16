# Remediaciones

Registro de hallazgos de auditoria y su remediacion. Cada entrada conserva
identificador, fecha, severidad, estado y evidencia. Las auditorias se
realizan contra el cluster Proxmox y los documentos del repositorio.

| ID | Fecha | Hallazgo | Severidad | Estado |
| --- | --- | --- | --- | --- |
| H-001 | 2026-09-15 | Token de API de Proxmox con privilegios de root | Alta | Remediado |
| H-002 | 2026-09-15 | Ruta de vault incorrecta en la documentacion | Baja | Remediado |
| H-003 | 2026-09-15 | Recreacion de las VMs desde cero no ensayada | Media | Aceptado (Fase 10) |
| H-004 | 2026-09-15 | Contrasenas de usuarios de Gitea impresas en logs de apply | Media | Remediado |
| H-005 | 2026-09-16 | Gitea 1.24 segaba las entregas del webhook (ALLOWED_HOST_LIST) | Alta | Remediado |
| H-006 | 2026-09-16 | Job multibranch con 500 en el parent (folderViews sin owner) | Alta | Remediado |
| H-007 | 2026-09-16 | Debug de stores de CI con configurantes XStream no documentados | Baja | Documentado |
| H-008 | 2026-09-16 | Ruta de escaneo: una rama concreta no se descubria en el multibranch | Media | Remediado |

## H-001 - Token de API de Proxmox con privilegios de root

**Hallazgo (auditoria de Fases 0-2):** el token `root@pam!tofu`, usado por
OpenTofu (via `terraform.tfvars`, gitignored) y por el helper de qexec,
tenia `privsep=0` y sin caducidad: privilegios completos de root sobre el
cluster. La casilla de Fase 0 "usuario/token de API con privilegios
minimos" estaba marcada sin cumplir.

**Remediacion:**

- Grupo `pushlane-ops` y usuario `pushlane@pve` (sin contrasena, solo
  token).
- Token `pushlane@pve!tofu` con `privsep=1`: con separacion activada, el
  token solo recibe los permisos de las ACLs que lo nombran directamente.
- ACLs acotadas por ruta, para el grupo y el token:
  - `/vms/9000` (plantilla), `/vms/202`, `/vms/203`, `/vms/204`: rol
    `PVEVMAdmin`, ciclo de vida completo de las VMs del lab (clonado,
    cloud-init, config, encendido, snapshots y guest agent).
  - `/storage/local-lvm`: rol `PVEDatastoreUser` (auditoria y asignacion
    de espacio). Sin `Datastore.Allocate`: no puede reconfigurar ni borrar
    el datastore.
- El token no puede tocar nodos, otras VMs, usuarios, ACLs, redes ni el
  resto de los storages del cluster.
- Credenciales rotadas en `.env` y `tofu/terraform.tfvars` (gitignored) y
  token `root@pam!tofu` revocado.

**Evidencia:**

- `tofu plan` responde "No changes" con el token nuevo, antes y despues de
  revocar el de root.
- qexec verificado contra `pushlane-ci` (vmid 202) con el token nuevo.
- `pveum acl list` muestra unicamente las rutas del lab.

**Notas:**

- La copia obsoleta del `terraform.tfvars` en la vivobook contiene el
  token revocado; el nodo de control autoritativo es el ECS.
- Si el ensayo de recreacion (Fase 10) falla por falta de
  `Datastore.AllocateTemplate` al clonar, elevar `/storage/local-lvm` a
  `PVEDatastoreAdmin` (o un rol propio con ese privilegio) y registrarlo
  aqui.
- Este `pveum` no tiene `acl add`: usa `pveum acl modify` (upsert).

## H-002 - Ruta de vault incorrecta en la documentacion

**Hallazgo:** `docs/bootstrap.md` indicaba
`ansible-vault create group_vars/jenkins/vault.yml` en la seccion de
Jenkins; los vaults en `ansible/group_vars/` nunca cargan en contexto de
play. El mismo error ya se habia corregido en otras secciones y quedaba
esta referencia suelta.

**Remediacion:** ruta corregida a
`ansible-vault create inventory/group_vars/jenkins/vault.yml`.

**Evidencia:** `grep -rn "group_vars" docs/` solo devuelve la explicacion
del comportamiento y rutas correctas.

## H-003 - Recreacion de las VMs desde cero no ensayada

**Hallazgo:** el criterio de cierre de la Fase 1 ("las tres VMs pueden
recrearse desde cero") nunca se comprobo con un destroy/apply real; solo
existe evidencia de `tofu plan` sin cambios.

**Decision:** aceptado por ahora; el ensayo esta en la Fase 10 ("Destruir
una VM, reconstruirla y restaurar los datos") para no arriesgar los
servicios que ya corren.

**Evidencia:** nota agregada en la seccion Fase 1 del ROADMAP.

## H-004 - Contrasenas de usuarios de Gitea impresas en logs de apply

**Hallazgo:** las tareas "Look up the lab users in Gitea" y "Add the lab
users to the developers team" iteraban el diccionario completo
`gitea_lab_users`; el display de cada item incluia la contrasena en
texto claro. Las tareas de creacion ya usaban `no_log`, pero el bucle de
verificacion/agregacion no.

**Remediacion:** `loop_control.label` con el nombre de usuario en ambas
tareas (el label sustituye al item en el log sin esconder el estado),
purga de los logs de apply que contenian los valores y verificacion con
grep de todos los valores de `.env` contra los logs nuevos: sin
coincidencias. La tarea de creacion mantiene `no_log`.

**Evidencia:** apply de verificacion con `changed=0` y seis menciones de
"password" todas benignas (nombres de tareas y valores censurados).

**Recomendacion:** rotar las contrasenas de `devops` y `developer`
(`PATCH /api/v1/admin/users/{username}`) si los logs fugados salieron
del nodo de control; en el lab se evaluo como riesgo aceptable.

## H-005 - Gitea 1.24 segaba las entregas del webhook

**Hallazgo:** hook manual en `homelab/infrastructure` hacia
`http://jenkins.lab.local:8080/gitea-webhook/post` con entregas fallidas
(via basica 401 en la tabla `hook_task`). Gitea 1.24 aplica la opcion
`webhook.ALLOWED_HOST_LIST` a las entregas salientes y, con el valor por
defecto, denegaba `jenkins.lab.local(10.0.0.22:8080)` con
"webhook can only call allowed HTTP servers (check your webhook.ALLOWED_HOST_LIST setting), deny 'jenkins.lab.local(10.0.0.22:8080)'".

**Remediacion:** `GITEA__webhook__ALLOWED_HOST_LIST: "private"` en
`services/gitea/compose.yml` (mismo valor que el ajuste manual que
remedio las entregas; en Gitea 1.24 el valor por defecto de
`webhook.ALLOWED_HOST_LIST` es `private`, o sea, el ajuste es redundante
y seguro; se mantiene explicito). En algun momento el valor se cambio
manual a `public`; se volvio a `private` y se codifico en el compose.

**Evidencia:** tras el cambio, delivery id=3 con `is_succeed=t` y
`status:200`; push real disparo build #1 de Jenkins sin `Build Now`.

## H-006 - Job multibranch con 500 en el parent (folderViews sin owner)

**Hallazgo:** al cargar la definicion XML del job, el parent
(`/job/infrastructure/`, UI y API) devolvia 500, mientras los hijos
(`/job/infrastructure/job/main/`) funcionaban. El stack apuntaba a
`MultiBranchProjectViewHolder.getPrimaryView` con
"Cannot invoke jenkins.branch.MultiBranchProject.hasVisibleItems() because
this.owner is null": un configurante de XStream de
`jenkins.branch.MultiBranchProjectViewHolder` deja `owner` (campo final,
no escribe en el XML al guardar) en null cuando el elemento
`<folderViews/>` no lo referencia.

**Remediacion:** `<owner>` dentro de `<folderViews>` apuntando al
`WorkflowMultiBranchProject` padre (`reference="../.."`, igual que el
`<icon/>`); primer arreglo manual en el config vivo, luego codificado en
`ansible/roles/jenkins/templates/job-multibranch.xml.j2`.

**Evidencia:** tras el parche manual, parent API y UI responden 200;
re-aplicacion del rol idempotente (handlers sin cambios) y build #5
intacto.

## H-007 - Configurantes XStream en plugins de CI no documentados

**Hallazgo:** tres fallos de la Fase 4-5 por campos de plugin silenciosos
en XML: (1) un `SourcesList` en vez de `BranchSourceList` hacia que Gitea
no resolviera la configuracion de la fuente y el job perdiera los repo
tratados; (2) la matrix de seguridad con `authenticatedOverride` y sin
`Job/Delete` impedía borrar items desde UI/groovy; (3) el `owner` del
view (H-006).

**Remediacion:** uso de `BranchSourceList` en la plantilla;
eliminacion de items vía filesystem + `Jenkins.instance.reload()` (sin
necesidad de ampliar la matrix); y el `<owner>` del holder (H-006).

**Evidencia:** jobs creados desde la plantilla levantan con la fuente
Gitea, los items de drill se quitan con el filesystem+reload y el parent
responde 200.

## H-008 - Ruta de escaneo: una rama concreta no se descubria en el multibranch

**Hallazgo:** al integrar los escaneos (Fase 5) hice un merge de prueba desde
la rama `fm/ci-scans` (push via SSH + PR). El PR se abria y su build
`PR-2` corria y pasaba, pero el required status check `infrastructure/pipeline/head`
nunca se satisfacia: la indexacion del Multibranch listaba la rama en el
log (`Checking branch fm/ci-scans`) pero ahi terminaba — sin
`'pipelines/Jenkinsfile' found`, sin `Met criteria`, sin creacion del job
de rama, y sin mensaje de error. Consecuencia: Gitea rechazaba el merge
("Not all required status checks successful").

**Diagnostico (bisectado):** el contenido y el head de la rama eran
correctos (Jenkinsfile presente, `contents` API 200, builds verdes). El
fallo era exclusivo del nombre de la rama: creando ramas de control
apuntadas al mismo head (`ctest`, `fred`, `fmx`, `ci-scans`, `x/fm/zz`)
todas se descubrian y construian; solo `fm/ci-scans` no. No coincide con
prefijos (fmx ok), sufijos (ci-scans ok), slashes (x/fm/zz, cd/scan ok)
ni con contrasena de credenciales (main/PR usan las mismas). El plugin
Gitea de Jenkins maltrata ese nombre puntual (posible colision interna de
SCMHead); el log de branch-api no lo reporta como error.

**Remediacion:** renombrar la rama a `ci/scans-20260916` y migrar la PR
(cerrar PR-2 y abrir PR-3 desde el nombre sano). Con el nombre nuevo, el
job de rama se creo, construyo verde, el status `head` quedo en success y
el merge fluyo dentro del gate. La rama original se borro.

**Evidencia:** PR-3 merged=True (merge_commit `5a2a35b`), statuses
`pr-main` + `head` en success para el head de la PR; main build #6 SUCCESS
cubriendo deploy con la imagen `5a2a35b` y `/health` ok; el escaneo
posterior del multibranch deja solo `main`.

**Notas:**
- En el camino, crear ramas via API con `old_ref_name` apuntando a
  estados previos dejo remanentes `ztest/fm` y `ztest/fm2` que el API
  reporta como existentes pero no lista (solo en el caché de Gitea; el
  `git_branch` de Postgres no existe en esta version). DELETE devuelve
  500. No afectan al pipeline.
- Leccion: evitar ramas temporales con el prefijo que ya fallo; si un job
  de rama no aparece tras un push limpio, probar renombrar antes de tocar
  la configuracion del pipeline.
