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
