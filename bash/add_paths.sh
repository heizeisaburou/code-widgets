#!/usr/bin/env bash

# 平生三郎 - https://github.com/heizeisaburou
#
# GitHub (public): https://github.com/heizeisaburou/code-widgets/blob/main/bash/add_paths.sh

# Apenda directorios al PATH de la sesion actual de bash. Solo agrega los que
# existen y nunca crea entradas duplicadas. No toca ningun fichero de
# configuracion: para que dure, hay que llamarla desde ~/.bashrc.
#
#   add_paths ~/bin ~/scripts
add_paths() {
  local d
  for d in "$@"; do
    [[ -d "$d" ]] || continue
    # case en vez de =~ : un directorio con +, ( o ) rompe la expresion regular
    # y el directorio acabaria agregandose una vez por llamada.
    case ":$PATH:" in
      *":$d:"*) ;;
      *) PATH="$PATH:$d" ;;
    esac
  done
}
