# Bootstrap

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
   ansible-vault create group_vars/gitea/vault.yml
   # contenido: gitea_db_password: <tu-contrasena>
   ```

   Y aplica el playbook con el password del vault:

   ```bash
   make ansible-apply ANSIBLE_EXTRA_ARGS="--ask-vault-pass"
   ```

El rol escribe `/opt/pushlane/gitea/.env` (modo `0600`) y este no se versiona.

## 4. Gitea

1. Abre `http://pushlane-git.lab.local:3000`.
2. Completa el instalador y crea la organizacion `homelab`.
3. Crea el repositorio `demo-api` y protege `main`.
4. Agrega el webhook de Jenkins y un secreto compartido.

## 5. Jenkins

1. Abre `http://pushlane-ci.lab.local:8080`.
2. Recupera la clave inicial desde el contenedor.
3. Instala solo los plugins necesarios para Git, Pipeline, Gitea y SSH Agent.
4. Crea credenciales con los IDs documentados por el `Jenkinsfile`.
5. Crea el nodo agente en Jenkins (tipo *inbound*), nombre `pushlane-agent` y
   etiqueta `docker`. Al guardarlo, Jenkins muestra un secret: definelo como
   `jenkins_agent_secret` en el inventario real o en un vault
   (`ansible-vault create group_vars/jenkins/vault.yml`) y vuelve a ejecutar
   `make ansible-apply ANSIBLE_EXTRA_ARGS="--ask-vault-pass"`. Ansible provee
   en `pushlane-ci` el contenedor del agente con Docker CLI y Python (bloqueda
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

## 6. Primer pipeline

Publica el contenido del repositorio y coloca `pipelines/Jenkinsfile` como
`Jenkinsfile` en la raiz del repo de aplicacion, o configura esa ruta en
Jenkins. Primero valida Lint/Test; habilita Publish/Deploy cuando el registry,
DNS y las credenciales funcionen.
