# 平生三郎 - https://github.com/heizeisaburou
#
# GitHub (public): https://github.com/heizeisaburou/code-widgets/blob/main/zsh/add_paths.zsh

# Apenda directorios al PATH. Solo agrega los que existen y nunca crea
# entradas duplicadas.
#
#   add_paths ~/bin ~/scripts
#
# No hace falta tocar PATH como cadena: zsh mantiene el array $path
# sincronizado con $PATH. El subindice (Ie) busca el elemento exacto dentro del
# array -I devuelve su posicion, e desactiva el emparejamiento por patron- y
# devuelve 0 cuando no esta.
add_paths() {
  local d
  for d in "$@"; do
    [[ -d $d ]] || continue
    (( ${path[(Ie)$d]} )) || path+=("$d")
  done
}
