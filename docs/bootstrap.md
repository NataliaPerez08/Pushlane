# Bootstrap

> Opera todo desde un nodo de control con acceso al Proxmox y a las VMs (en
> este lab, un ECS en la misma Tailnet que llega por `ProxyJump` via el host
> PVE). Ese nodo concentra el venv de Ansible, el `.env` con credenciales,
> los vaults y el `terraform.tfstate`/`terraform.tfvars` reales (gitignored).

## 1. Proxmox

1. Crea una plantilla Debian/Ubuntu con cloud-init y QEMU Guest Agent.
2. Crea un usuario y token exclusivos para OpenTofu.
3. Copia `tofu/terraform.tfvars.example` y reemplaza los valores del lab.
4. Evita guardar el token real en el archivo: usa una variable de entorno o un
   gestor de secretos local.

## 2. OpenTofu

```bash
make tofu-init
make tofu-plan
make tofu-apply
```

Verifica que las VMs respondan por SSH antes de continuar.

## 3. Ansible

```bash
ansible-galaxy collection install -r ansible/requirements.yml
cp ansible/inventory/hosts.yml.example ansible/inventory/hosts.yml
make ansible-check
make ansible-apply
```

Antes de exponer Gitea, define la contrasena de base de datos. El compose
exige la variable `GITEA_DB_PASSWORD` y el rol `gitea` falla si Ansible no
la provee. Dos formas:

1. **Simple:** agrega `gitea_db_password: <tu-contrasena>` al inventario real
   `ansible/inventory/hosts.yml` (gitignored, nunca se versiona).
2. **Con Ansible Vault (recomendada, leccion de la Fase 8):**

   ```bash
   cd ansible
   ansible-vault create inventory/group_vars/gitea/vault.yml
   # contenido: gitea_db_password: <tu-contrasena>
   ```

   Los vaults viven junto al inventario (`inventory/group_vars/<grupo>/`)
   porque Ansible solo carga group_vars del directorio del inventario o del
   playbook; ponerlos en `ansible/group_vars/` no funciona.

   Y aplica el playbook con el password del vault:

   ```bash
   make ansible-apply ANSIBLE_EXTRA_ARGS="--ask-vault-pass"
   ```

El rol escribe `/opt/pushlane/gitea/.env` (modo `0600`) y este no se versiona.

## 4. DNS interno (Technitium)

El rol `dns` despliega Technitium DNS Server en `pushlane-git` (grupo `dns`
del inventario) y crea la zona `lab.local` con un registro A por host del
inventario, via la API HTTP del servidor.

1. Define la contrasena de la consola:

   ```bash
   cd ansible
   ansible-vault create inventory/group_vars/dns/vault.yml
   # contenido: dns_admin_password: <tu-contrasena>
   ```

2. Aplica el playbook (con tu vault) y abre `http://<ip-de-pushlane-git>:5380`
   como usuario `admin`.

Notas:

- Technitium solo lee las variables `DNS_SERVER_*` del `.env` en el primer
  arranque (volumen `dns_config` vacio); cambiarlas despues no tiene efecto.
  Para reinicializar la configuracion hay que borrar ese volumen.
- Los hosts enrutan solo `lab.local` a Technitium (split DNS via
  systemd-resolved); la resolucion externa sigue por el DNS de cloud-init.
- El daemon de Docker tambien usa Technitium para que los contenedores
  resuelvan `*.lab.local`; los contenedores creados antes del cambio
  necesitan recrearse para heredarlo.

## 5. Gitea

1. No hay asistente web: el rol `gitea` fija `INSTALL_LOCK=true`, los
   dominios (`gitea.lab.local`, SSH en `2222`) y deshabilita el registro
   publico antes del primer arranque.
2. Ejecuta `make ansible-apply`: el rol crea el admin `gitea-admin` por
   CLI, la organizacion `homelab`, los repos privados `demo-api` e
   `infrastructure`, los usuarios `devops` y `developer` (equipo
   `developers`, escritura via `units_map`), registra la llave publica
   del nodo de control como llave del admin, empuja el contenido inicial
   por SSH (`:2222`) y protege `main` (push directo bloqueado, cambios
   solo por PR). El push del repo `infrastructure` envia la historia
   completa desde el nodo de control.
3. El webhook de Jenkins y su secreto compartido se configuran en la
   Fase 5.
4. Respaldos: `make gitea-backup` y `docs/runbooks/gitea-backup.md`.

## 6. Jenkins

1. Abre `http://pushlane-ci.lab.local:8080`.
2. Recupera la clave inicial desde el contenedor.
3. Instala solo los plugins necesarios para Git, Pipeline, Gitea y SSH Agent.
4. Crea credenciales con los IDs documentados por el `Jenkinsfile`.
5. Crea el nodo agente en Jenkins (tipo *inbound*), nombre `pushlane-agent` y
   etiqueta `docker`. Al guardarlo, Jenkins muestra un secret: definelo como
   `jenkins_agent_secret` en el inventario real o en un vault
   (`ansible-vault create inventory/group_vars/jenkins/vault.yml`) y vuelve a ejecutar
   `make ansible-apply ANSIBLE_EXTRA_ARGS="--ask-vault-pass"`. Ansible provee
   en `pushlane-ci` el contenedor del agente con Docker CLI y Python (bloqueada
   por el socket del host); el secret activa la conexion JNLP. No ejecutes
   builds de aplicaciones en el controller.
6. Crea un Multibranch Pipeline apuntando al repositorio de Gitea.

> El registry del laboratorio usa HTTP. El rol `docker` escribe
> `/etc/docker/daemon.json` con `insecure-registries` en `pushlane-ci` (push
> del agente) y `pushlane-app` (pull del despliegue), segun la variable
> `docker_insecure_registries` del inventario. Sin ese ajuste el push falla
> con `http: server gave HTTP response to HTTPS client`. Si registras el
> agente en otra maquina, aplica alli la misma configuracion. La Fase 8
> reemplaza esta excepcion con TLS.

## 7. Primer pipeline

Publica el contenido del repositorio y coloca `pipelines/Jenkinsfile` como
`Jenkinsfile` en la raiz del repo de aplicacion, o configura esa ruta en
Jenkins. Primero valida Lint/Test; habilita Publish/Deploy cuando el registry,
DNS y las credenciales funcionen.
