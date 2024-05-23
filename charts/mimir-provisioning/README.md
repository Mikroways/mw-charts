# Chart de aprovisionamiento de mimir

Este chart se utilizara para tareas de aprovisionamiento de mimir (como por
ejemplo la carga de rules).

En lineas generales funciona de la siguiente manera:

- Genera un conjunto de configmaps que se configuran mediante la clave
  `provision`.

- Una vez que se instala el chart se crea un job con dos contenedores:

  - Estos configmaps luego son levantados por un contenedor de
    [k8s-sidecar-container](https://github.com/kiwigrid/k8s-sidecar) quien los
    persiste en un volumen local en forma de archivos con path
    `/tmp/<tenant>/<archivo>`

  - Finalmente este volumen es utilizado por un contenedor de `mimirtool` quien
    itera sobre las carpetas y archivos aprovisionamdo mimir en base al tenant y
    el archivo.

## Values

| nombre | tipo | default | descripcion |
| --- | --- | --- | --- |
| `mode` | `String` | `"job"` | Modo de depligue del aprovisionador. Posibles valores `job` y `cronjob` |
| `cronjob.schedule` | `String` | `"*/5 * * * *"` | Expresión para el cronjob |
| `global.provisioner.mimirtoolCommand` | `String` | `rules sync` | Subcomando que se le envia a mimirtool. Por defecto realizara un sync de las rules |
| `global.provisioner.mimirtoolArgs` | `String` | `/tmp/$tenant/$file` | Argumentos que se le pasan al comando de mimirtool |
| `imagePullSecrets` | `Array<image-pullsecrets>` | `[]` | Nombre de secreto con credenciales para bajar las imagenes si se utilizacen repositorios privados. |
| `nameOverride` | `String`  | `""`  |   |
| `fullnameOverride` | `String`  | `""`  |   |
| `serviceAccount.create` | `Bool` | `true` | Especifica si se debe crear una sa |
| `serviceAccount.annotations` | `Object` | `{}` | Anotaciones para la sa |
| `serviceAccoint.name` | `String` | `""` | Nombre de la sa que se utiliza con el despliegue. Si es vacio se utiliza el nombre del release |
| `podAnnotations` | `Object` | `{}` | Anotaciones para el pod que se despliega |
| `podSecurityContext` | `Object` | `{}` | Security context a nivel pod |
| `nodeSelector` | `Object` | `{}` | Nodeselector para schedulear el pod |
| `tolerations` | `Array<toleration>` | `[]` | Tolerations para el pod |
| `affinity` | `Object` | `{}` | Affinity para schedulear el pod |
| `backoffLimit` | `Int` | `3` | Cantidad de veces que se ejecuta el pod en caso de fallos |
| `provisioner.image.repository` | `String` | `grafana/mimirtool` | Repositorio donde se obtiene la imagen de mimirtool |
| `provisioner.image.tag` | `String` | `2.10.5` | Tag de la imagen de mimirtool |
| `provisioner.image.pullPolicy` | `String` | `IfNotPresent` | Polituca para bajar la imagen del provisioner |
| `provisioner.securityContext` | `Object` | `{}` | Security context para el contenedor de mimirtool |
| `provisioner.resources` | `Object` | `{}` | Requests y Limits para el contenedor de mimirtool |
| `provisioner.mimirAddress` | `String` | `http://mimir-nginx.mimir.svc` | Url de la api de mimir. Por defecto se configura para utilizar un mimir instalado en el mismo namespace que este chart. |
| `provisioner.script` | `String` | `Ver values.yaml` | Script que se invoca en el contenedor de mimirtool. Por defecto itera en una estructura de archivos  `/tmp/<tenant>/<file>` aplicando el `mimirtoolCommand` con el archivo y el tenant infiriendolos del path. |
| `sidecar.image.repository` | `String` | `ghcr.io/kiwigrid/k8s-sidecar` | Repositorio donde se obtiene la imagen de mimirtool |
| `sidecar.image.tag` | `String` | `1.25.3` | Tag de la imagen de mimirtool |
| `sidecar.image.pullPolicy` | `String` | `IfNotPresent` | Polituca para bajar la imagen del sidecar |
| `sidecar.securityContext` | `Object` | `{}` | Security context para el contenedor de sidecar |
| `sidecar.resources` | `Object` | `{}` | Requests y Limits para el contenedor de sidecar |
| `sidecar.extraEnvs` | `Array<env>` | `[]` | Objeto de variables extra para pasar al contenedor del sidecar. Respetan el formato de variables de ambiente de k8s (name,value) |
| `sidecar.resourceLabel` | `String` | `provisioning` | Label que se aplica a los configmaps y a traves del cual el sidecar los identifica para montar como archivos. |
| `sidecar.resourceType` | `String<both,configmap,secret>` | `both` | Que tipo de recursos mira el sidecar. Por defecto seran configmaps y secrets |
| `sidecar.behaviour` | `String<LIST,WATCH>` | `LIST` | Indica en que modo se ejecuta el sidecar. `LIST` chequea los recursos y termina, `WATCH` queda en loop esperando cambios. |
| `provision` | `Object<tenant>` | `{}` | Objeto que define tenant y archivos para `aprovisiona`r mimir |
| `provision.tenant` | `Array<file>` | `""` | Define los archivos que se utilizan para aprovisionar un tenant en mimir |
| `provision.tenant.file` | `Object<name,content>` | `""` | Define un archivo para aprovisionar un tenant. El mismo cuenta con `name` (nombre con que se montara el archivo en el pod de aprovisionamiento) y `content` (contenido de dicho archivo) |

## Acerca de provision

Dado que mimir es multitenant, es importante que el objeto provision tenga como
claves nombres de tenants validos ya que a partir de estos es que se terminan
montando los archivos e infiriendo contra que tenant aplicar el
aprovisionamiento.

