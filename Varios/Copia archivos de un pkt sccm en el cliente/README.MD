# Guía para Copiar Archivos a través de SCCM

Este proceso permite copiar los archivos de la carpeta "Files2Copy" a una ruta indicada como parámetro en el script.

## Pasos

### 1. Crear Carpeta en Sources de SCCM
- En la ruta de **Sources** de **SCCM**, crea una carpeta para el paquete.
- Dentro de esa carpeta, copia el archivo `FilesCopy.bat`.
- Crea una subcarpeta llamada **Files2Copy**.

### 2. Copiar Archivos
- Copia los archivos que deseas transferir a los clientes dentro de la carpeta **Files2Copy**.

### 3. Crear un Paquete en SCCM
- En **SCCM**, crea un paquete como **programa estándar**.
- Usa `FilesCopy.bat` como el ejecutable.
- Agrega la ruta de destino como parámetro del bat. Ejemplo:
  
  ```bash
  FilesCopy.bat "C:\Users\Public\Desktop"
