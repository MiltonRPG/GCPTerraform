import os
import sys
import json

# Verificar que se haya pasado el nombre del servicio como argumento
if len(sys.argv) != 2:
    print("Usage: generate_version.py <service>")
    sys.exit(1)

service = sys.argv[1]

# Directorio donde se almacenarán las versiones
version_dir = "versions"

# Crear el directorio si no existe
if not os.path.exists(version_dir):
    os.makedirs(version_dir)

# Ruta del archivo donde se almacenará la última versión del servicio
version_file_path = os.path.join(version_dir, f"{service}.txt")

# Leer la última versión del archivo, si existe
if os.path.exists(version_file_path):
    with open(version_file_path, "r") as file:
        last_version = file.read().strip()
else:
    last_version = "0-0-0"

# Incrementar la versión
def increment_version(version):
    major, minor, patch = map(int, version.split("-"))
    patch += 1
    if patch >= 10:
        patch = 0
        minor += 1
        if minor >= 10:
            minor = 0
            major += 1
    return f"{major}-{minor}-{patch}"

new_version = increment_version(last_version)

# Guardar la nueva versión en el archivo
with open(version_file_path, "w") as file:
    file.write(new_version)

# Devolver el nuevo version_id en formato JSON
output = {
    "version": new_version
}

print(json.dumps(output))


