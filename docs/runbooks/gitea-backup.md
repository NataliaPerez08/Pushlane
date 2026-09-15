# Runbook: respaldo y restauracion de Gitea

## Respaldo

Ejecutar desde el nodo de control:

```
make gitea-backup
```

Equivale a `ansible-playbook ... --tags backup --limit pushlane-git`.
El rol corre `gitea dump --type zip` dentro del contenedor (usuario
`git`) y copia el resultado con `docker cp` a
`/opt/pushlane/backups/gitea-dump-latest.zip` en `pushlane-git`
(propietario root, modo 0600).

Las tareas de respaldo llevan `tags: [never, backup]`: un apply normal
nunca las ejecuta y no rompe la idempotencia (`changed=0`).

## Contenido del dump

| Entrada | Contenido |
| --- | --- |
| `app.ini` | Configuracion completa de la instancia |
| `gitea-db.sql` | Volcado de la base postgres |
| `repos/` | Repositorios en formato bare (`repos/homelab/<repo>.git`) |
| `data/` | Avatares, adjuntos y LFS |

Notas:

- El archivo destino es siempre `gitea-dump-latest.zip` (snapshot
  unica). Para conservar historia, copiar con fecha:
  `cp gitea-dump-latest.zip gitea-dump-$(date +%F).zip`.
- El dump NO es consistente con transacciones en vuelo; ejecutarlo en
  momentos de reposo del lab.

## Drill de restauracion (verificado 2026-09-15)

Restaurar un repositorio desde el dump en `pushlane-git`:

```
sudo mkdir -p /tmp/restore-drill && cd /tmp/restore-drill
sudo python3 -c "import zipfile; zipfile.ZipFile('/opt/pushlane/backups/gitea-dump-latest.zip').extractall('.')"
git clone repos/homelab/demo-api.git restored-demo-api
git -C restored-demo-api log --oneline
```

`unzip` no esta instalado en las VMs; usar el modulo `zipfile` de
python3. El clon debe mostrar la historia completa hasta el commit que
existia al momento del dump (incluidos merges de PR).

Restauracion completa de la instancia (referencia, no ensayada):

1. Detener el compose de Gitea y vaciar el volumen de datos.
2. Recrear `data/` y `app.ini` desde el dump, importar `gitea-db.sql`
   a una base postgres nueva (misma contrasena del vault).
3. Copiar `repos/` a `/data/git/repositories` con propietario `git`.
4. Levantar el compose y verificar `GET /api/v1/version`.

El ensayo completo de recreacion esta en la Fase 10 del ROADMAP.
