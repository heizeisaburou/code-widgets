#!/usr/bin/env bash

# 平生三郎 ― https://github.com/heizeisaburou/coding-widgets/bash/get_script_dir.sh

# Devuelve el directorio real donde se encuentra este archivo, resolviendo
# enlaces simbólicos de forma recursiva. Esto permite obtener una ruta absoluta
# y estable independientemente de desde dónde se ejecute el script o de si fue
# invocado a través de un symlink.
get_script_dir() {
  local SOURCE_PATH="${BASH_SOURCE[0]}"
  local symlinkDir
  local scriptDir

  # Resuelve recursivamente los enlaces simbólicos
  while [ -L "$SOURCE_PATH" ]; do
    # Obtiene el directorio donde se encuentra el enlace simbólico
    symlinkDir="$(cd -P "$(dirname "$SOURCE_PATH")" >/dev/null 2>&1 && pwd)"
    # Resuelve el destino del enlace, ya sea relativo o absoluto
    SOURCE_PATH="$(readlink "$SOURCE_PATH")"
    # Si la ruta era relativa la convierte a una ruta absoluta
    [ "${SOURCE_PATH#/}" = "$SOURCE_PATH" ] && SOURCE_PATH="$symlinkDir/$SOURCE_PATH"
  done

  # Obtiene el scriptDir a traves de un path completamente resuelto
  scriptDir="$(cd -P "$(dirname "$SOURCE_PATH")" >/dev/null 2>&1 && pwd)"
  echo "$scriptDir"
}
