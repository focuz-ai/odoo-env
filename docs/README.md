<h1>Tabla de contenido</h1>

- [Gestión de submódulos (sub-proyecto o sub-repositorio)](#gestión-de-submódulos-sub-proyecto-o-sub-repositorio)
  - [Cómo agregar un nuevo submódulo](#cómo-agregar-un-nuevo-submódulo)
  - [Cómo descargar actualizaciones de superproyectos](#cómo-descargar-actualizaciones-de-superproyectos)
  - [Cómo actualizar los submódulos a la última versión en cada rama](#cómo-actualizar-los-submódulos-a-la-última-versión-en-cada-rama)
    - [Si quieres actualizar un submódulo específico](#si-quieres-actualizar-un-submódulo-específico)
    - [Si también deseas cambiar a la rama principal de cada submódulo](#si-también-deseas-cambiar-a-la-rama-principal-de-cada-submódulo)
  - [Cómo cambiar de rama con submódulos](#cómo-cambiar-de-rama-con-submódulos)
  - [Subir cambios al repositorio del subproyecto](#subir-cambios-al-repositorio-del-subproyecto)
  - [Cómo hacer merge con submódulos](#cómo-hacer-merge-con-submódulos)
    - [1. Cambiar a la rama destino:](#1-cambiar-a-la-rama-destino)
    - [2. Actualiza la rama de destino:](#2-actualiza-la-rama-de-destino)
    - [3. Fusiona la rama de origen:](#3-fusiona-la-rama-de-origen)
    - [4. Actualiza los submódulos:](#4-actualiza-los-submódulos)
    - [5. Confirma los cambios:](#5-confirma-los-cambios)
    - [6. Empuja los cambios:](#6-empuja-los-cambios)
  - [Cómo eliminar submódulo](#cómo-eliminar-submódulo)
    - [1. Desvincular el submódulo](#1-desvincular-el-submódulo)
    - [2. Eliminar las referencias al submódulo](#2-eliminar-las-referencias-al-submódulo)
    - [3. Eliminar los archivos del submódulo](#3-eliminar-los-archivos-del-submódulo)
    - [4. Confirmar los cambios](#4-confirmar-los-cambios)
    - [5. Eliminar la entrada del submódulo en el archivo .gitmodules](#5-eliminar-la-entrada-del-submódulo-en-el-archivo-gitmodules)
    - [6. Confirmar la eliminación del submódulo en el repositorio principal](#6-confirmar-la-eliminación-del-submódulo-en-el-repositorio-principal)
    - [7. (Opcional) Empujar los cambios](#7-opcional-empujar-los-cambios)
  - [Configuraciones útiles para submódulos](#configuraciones-útiles-para-submódulos)
- [Extras de GIT](#extras-de-git)
  - [Múltiples ubicaciones remotas donde el repositorio está almacenado](#múltiples-ubicaciones-remotas-donde-el-repositorio-está-almacenado)
    - [1. Verificar remotos actuales:](#1-verificar-remotos-actuales)
    - [2. Agregar un nuevo remote:](#2-agregar-un-nuevo-remote)
    - [3. Verificar que se agregó correctamente:](#3-verificar-que-se-agregó-correctamente)
    - [4. Realizar operaciones con múltiples remotos:](#4-realizar-operaciones-con-múltiples-remotos)
      - [Push a un remoto específico:](#push-a-un-remoto-específico)
      - [Push de todas las ramas a un remoto específico:](#push-de-todas-las-ramas-a-un-remoto-específico)
      - [Fetch desde un remoto específico:](#fetch-desde-un-remoto-específico)
      - [Pull desde un remoto específico:](#pull-desde-un-remoto-específico)
  - [¿Cómo cambiar de rama predeterminada o rama de seguimiento?](#cómo-cambiar-de-rama-predeterminada-o-rama-de-seguimiento)
- [Cómo usar Fail2ban para prevenir accesos no deseados al servidor](#cómo-usar-fail2ban-para-prevenir-accesos-no-deseados-al-servidor)
  - [Qué es Fail2ban](#qué-es-fail2ban)
  - [Cómo instalar Fail2ban](#cómo-instalar-fail2ban)
  - [Cómo configurar Fail2ban](#cómo-configurar-fail2ban)
  - [Configuraciones personalizadas para cada servicio](#configuraciones-personalizadas-para-cada-servicio)
  - [Cómo comprobar el estado de Fail2ban](#cómo-comprobar-el-estado-de-fail2ban)
- [Fuentes](#fuentes)


# Gestión de submódulos (sub-proyecto o sub-repositorio)

## Cómo agregar un nuevo submódulo

    git submodule add -b <branch> <url> <path>
    git commit -m "feat: Se agrego nuevo submódulo <name>"

## Cómo descargar actualizaciones de superproyectos
De forma predeterminada, el repositorio del submódulo se recupera, pero no se actualiza cuando ejecuta `git pull` en el superproyecto. Se necesita usar `git submodule update`, o agregar `--recurse-submodules` a pull:

    git pull
    git submodule update --init --recursive

o, en un comando (Git >= 2.14)

    git pull --recurse-submodules

`--init` es necesario si el superproyecto agregó nuevos submódulos, y `--recursive` es necesario si algún submódulo tiene submódulos.

Si alguna vez el superproyecto cambia la URL del submódulo, se requiere un comando por separado:

    git submodule sync --recursive
    git submodule update --init --recursive

## Cómo actualizar los submódulos a la última versión en cada rama

Este comando recuperará las últimas versiones de los submódulos según la rama configurada en el archivo `.gitmodules ` y los actualizará en tu repositorio.

    git submodule update --remote

### Si quieres actualizar un submódulo específico

Esto actualizará solo el submódulo con el nombre especificado.

    git submodule update --remote nombre_submodulo

### Si también deseas cambiar a la rama principal de cada submódulo

Estos comandos cambiarán cada submódulo a la rama principal y luego realizarán un pull para actualizarlos.

    git submodule foreach git checkout main
    git submodule foreach git pull origin main

## Cómo cambiar de rama con submódulos
De forma predeterminada, el árbol de trabajo del submódulo no se actualiza para que coincida con el commit registrado en el superproyecto al cambiar de rama. Necesita usar `git submodule update`, o agregar `--recurse-submodules` a checkout:


    git checkout <branch>
    git submodule update --recursive

o, en un comando (Git >= 2.13)

    git checkout --recurse-submodules <branch>

## Subir cambios al repositorio del subproyecto

Mientras está en el directorio del submódulo:

    git push

O mientras está en el directorio principal:

    git push --recurse-submodules=on-demand

## Cómo hacer merge con submódulos
Cuando estás trabajando con submódulos en Git y necesitas realizar un git merge entre ramas que contienen submódulos, hay algunos pasos adicionales que debes seguir para asegurarte de que los submódulos se actualicen correctamente. Aquí hay una guía paso a paso:

Supongamos que tienes dos ramas: rama_origen y rama_destino, y quieres fusionar rama_origen en rama_destino.

### 1. Cambiar a la rama destino:

    git checkout rama_destino

### 2. Actualiza la rama de destino:
Asegúrate de que la rama de destino esté actualizada con los cambios más recientes:

    git pull origin rama_destino

### 3. Fusiona la rama de origen:
Fusiona la rama de origen en la rama de destino:

    git merge rama_origen

### 4. Actualiza los submódulos:
Después de fusionar las ramas, necesitas actualizar los submódulos:

    git submodule update --init --recursive

Este comando asegura que los submódulos estén inicializados y actualizados después de la fusión. Si el submódulo ha sido agregado o actualizado en la rama de origen, este paso asegura que esos cambios se reflejen en la rama de destino.

### 5. Confirma los cambios:
Confirma los cambios en la rama de destino, incluyendo las actualizaciones de los submódulos:

    git commit -m "Merge rama_origen into rama_destino"

### 6. Empuja los cambios:
Empuja los cambios a la rama de destino en el repositorio remoto:

    git push origin rama_destino

Recuerda que, en algunos casos, podría ser necesario realizar pasos adicionales dependiendo de cómo se hayan configurado y gestionado los submódulos en tu proyecto. Por ejemplo, si los submódulos han sido modificados en la rama de origen, esos cambios deben confirmarse y empujarse en esa rama antes de realizar la fusión en la rama de destino.

## Cómo eliminar submódulo

### 1. Desvincular el submódulo

    git submodule deinit -f ruta_del_submodulo

Este comando desvincula el submódulo y lo elimina de la configuración del submódulo. La opción -f fuerza la desvinculación.

### 2. Eliminar las referencias al submódulo

    git rm --cached ruta_del_submodulo

Esto elimina las referencias al submódulo del índice (staging area) pero mantiene los archivos en tu sistema de archivos.

### 3. Eliminar los archivos del submódulo

    rm -rf ruta_del_submodulo
    rm -rf .git/modules/ruta_del_submodulo

Esto elimina los archivos del submódulo de tu sistema de archivos.

### 4. Confirmar los cambios

    git commit -m "Eliminado submódulo: ruta_del_submodulo"

Este comando confirma los cambios en el repositorio principal.

### 5. Eliminar la entrada del submódulo en el archivo .gitmodules
Abre el archivo .gitmodules y elimina la entrada correspondiente al submódulo que acabas de eliminar. Este archivo se encuentra en la raíz de tu repositorio.

### 6. Confirmar la eliminación del submódulo en el repositorio principal

    git add .gitmodules
    git commit -m "Eliminada la configuración del submódulo: ruta_del_submodulo"

### 7. (Opcional) Empujar los cambios
Si deseas aplicar estos cambios al repositorio remoto:

    git push

## Configuraciones útiles para submódulos

Siempre muestre el registro del submódulo cuando vea diferencias:

    git config --global diff.submodule log

Muestre un breve resumen de los cambios del submódulo en su mensaje git status:

    git config --global status.submoduleSummary true

Haga que push sea predeterminado en --recurse-submodules = on-demand:

    git config --global push.recurseSubmodules on-demand

Haga que todos los comandos (excepto clone) estén predeterminados en --recurse-submodules si admiten la bandera (esto funciona para git pull desde Git 2.15):

    git config --global submodule.recurse true
    
# Extras de GIT
## Múltiples ubicaciones remotas donde el repositorio está almacenado

### 1. Verificar remotos actuales:
Puedes verificar los remotos actuales de tu repositorio usando el siguiente comando:

    git remote -v

### 2. Agregar un nuevo remote:
Para agregar un nuevo "origin" (remote), puedes hacerlo con el siguiente comando:

    git remote add <nombre-remoto> <URL-remoto>

Donde <nombre-remoto> es un nombre descriptivo que le das a este remoto (por ejemplo, "origin2") y <URL-remoto> es la URL del repositorio remoto.

Ejemplo:

    git remote add gitlab git@gitlab.com:hchumpitaz92/odoo_enterprise.git

### 3. Verificar que se agregó correctamente:

Vuelve a ejecutar el comando `git remote -v` para asegurarte de que el nuevo remoto se haya agregado correctamente.

### 4. Realizar operaciones con múltiples remotos:

#### Push a un remoto específico:
```
git push <nombre-remoto> <rama-local>
```

Ejemplo:

    git push gitlab 18.0

#### Push de todas las ramas a un remoto específico:
```
git push --set-upstream <nombre-remoto> --all
```
`--set-upstream ` (o simplemente `-u`) establece la rama remota predeterminada para la rama local actual. Esto significa que en futuros comandos `git push` y `git pull`, no necesitarás especificar la rama remota y la rama local, ya que la conexión se establecerá automáticamente.

Ejemplo:

    git push --set-upstream gitlab --all

#### Fetch desde un remoto específico:
```
git fetch <nombre-remoto>
```

Ejemplo:

    git fetch gitlab

#### Pull desde un remoto específico:
```
git pull <nombre-remoto> <rama-remota>
```

Ejemplo:

    git pull gitlab 18.0

Esto te permitirá trabajar con varios repositorios remotos simultáneamente.

Recuerda que "origin" es simplemente un nombre convencional, y puedes darle cualquier nombre a tus remotos. El término "origin" es comúnmente utilizado para referirse al repositorio principal, pero no es obligatorio.

## ¿Cómo cambiar de rama predeterminada o rama de seguimiento?

Si deseas cambiar la rama predeterminada (o la rama de seguimiento) para la rama local actual en Git, puedes utilizar el comando `git branch --set-upstream-to` o su forma abreviada `git branch -u`. Aquí hay un ejemplo de cómo hacerlo:

Supongamos que estás actualmente en la rama local "mi_rama_actual" y quieres establecer la rama remota "origin/nueva_rama_remota" como su rama de seguimiento. Puedes hacerlo de la siguiente manera:

    git branch -u origin/nueva_rama_remota

Recuerda que en Git, la rama predeterminada para el push y pull se basa en la rama de seguimiento, por lo que establecer la rama de seguimiento es útil para simplificar comandos futuros.

# Cómo usar Fail2ban para prevenir accesos no deseados al servidor

## Qué es Fail2ban
Fail2ban es una aplicación de Linux que permite evitar accesos no autorizados a tu servidor. ¿Y cómo funciona? Se encarga de bloquear (o banear) las direcciones IP que realicen varios intentos de acceso incorrectos al servidor. Y se trata de una estrategia ideal de seguridad a tener en cuenta tras contratar un Servidor Cloud.

## Cómo instalar Fail2ban

```bash
sudo apt-get install fail2ban
```

## Cómo configurar Fail2ban
La configuración de Fail2ban se encuentra en la carpeta «/etc/fail2ban/«. Allí encontraremos un archivo llamado «jail.conf» con las configuraciones del sistema. Para encontrar más información, podemos abrir ese archivo con nuestro editor preferido.

```bash
sudo nano jail.conf
```

En la sección «[DEFAULT]» encontramos la configuración global de las opciones. Allí veremos diversas variables que definir como las siguientes:

- **bantime:** es el tiempo que una IP será baneada, expresado en segundos.
- **maxretry:** es el número máximo de reintentos de login que podrán realizarse antes de que la IP sea baneada.
- **ignoreip:** una lista de IPs separadas por espacios que serían ignoradas por fail2ban.

## Configuraciones personalizadas para cada servicio

Cada una de las protecciones se expresa en una «jaula». Podemos tener varias «jaulas» para cada tipo de servicio administrado por Fail2ban. Ahora, si deseamos hacer cambios en la configuración predeterminada, lo recomendable es crear un archivo llamado `jail.local`.

```bash
sudo nano jail.local
```

Podemos crear una configuración SSH entrante de esta manera:
```bash
[sshd]
maxretry = 5
bantime=10800
```
_Nota: «sshd» es el demonio de conexión SSH, que permite que otros usuarios se conecten con nuestro servidor._

Para que estos cambios tengan efecto, tenemos que **reiniciar el servicio**. El comando puede depender de la distribución con la que estemos trabajando, pero en Ubuntu sería algo como esto:

```bash
sudo systemctl restart fail2ban.service
```

## Cómo comprobar el estado de Fail2ban

Podemos comprobar el estado de Fail2ban con el siguiente comando.

```bash
fail2ban-client status
```

Nos arrojará una lista de las jaulas que tenemos configuradas. Luego, podríamos visualizar información detallada de cada jaula con el comando:

```bash
fail2ban-client status sshd
```


# Fuentes
- [Cómo usar Fail2ban para prevenir accesos no deseados al servidor](https://www.arsys.es/blog/instalar-fail2ban)
- [Seguridad en Odoo](https://www.odoo.com/documentation/16.0/administration/on_premise/deploy.html#security)