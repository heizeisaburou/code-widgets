#!/usr/bin/env bash

# 平生三郎 - https://github.com/heizeisaburou
#
# GitHub (public): https://github.com/heizeisaburou/code-widgets/blob/main/bash/get_script_dir.sh

# Devuelve el directorio real donde se encuentra este archivo, resolviendo
# enlaces simbólicos de forma recursiva.
get_real_script_dir() {
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

# Devuelve el directorio donde está este archivo según la ruta usada para invocarlo.
# No resuelve enlaces simbólicos: si el script se ejecuta mediante un symlink,
# devuelve el directorio del symlink, no el del archivo real.
get_script_dir() {
  (
    cd -P "$(dirname "${BASH_SOURCE[0]}")" && pwd
  )
}
