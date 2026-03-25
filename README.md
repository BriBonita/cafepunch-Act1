# Proyecto Café & Canela (Actividad 1)

## Objetivo
Repositorio de ejemplo para la actividad "Despliegue de sitio estático en AWS S3".

## Archivos incluidos
- `index.html`: contenido principal
- `styles.css`: estilos visuales
- `app.js`: comportamiento interactivo (carrito, menú móvil, newsletter)
- `deploy.sh`: script de despliegue automático a S3
- `README.md`: instrucciones de uso

## Pasos recomendados (mínimos para la actividad)

1. Configurar Git:
   - `git config --global user.name "TU NOMBRE"`
   - `git config --global user.email "TU EMAIL"`

2. Autenticación GitHub:
   - Crear PAT con permisos `repo`.
   - Configurar `git remote add origin ...`
   - `git push -u origin main`

3. Configurar AWS CLI:
   - `aws configure`
   - Clave, Secreta, Región, JSON

4. Probar AWS CLI:
   - `aws sts get-caller-identity`

5. Despliegue inicial a S3 (desde este directorio):
   - `./deploy.sh <bucket-name> <region>`
   - Ejemplo: `./deploy.sh cafecanela-actividad1-usw2 us-west-2`

6. Revisar URL pública:
   - `http://<bucket-name>.s3-website-<region>.amazonaws.com`

7. Versionamiento con ramas:
   - `git checkout -b feature/cambio1`
   - Editar `index.html` (texto o imagen visible)
   - `git add . && git commit -m "Mensaje"`
   - `git push origin feature/cambio1`
   - Abrir PR en GitHub -> merge
   - `git checkout main && git pull`
   - Ejecutar `./deploy.sh ...` de nuevo.

8. Repetir paso 7 al menos otra vez (requisito de la actividad).

## Notas del informe de la actividad

- Documentar en Word (o PDF) la ejecución real: comandos, pantallazos, ramas, PRs, merges.
- Incluir URL de repositorio, URL de S3 CLI y URL de S3 Console.
- Incluir reflexión comparativa (parte D).
