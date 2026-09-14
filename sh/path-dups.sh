#!/bin/sh

# 平生三郎 - https://github.com/heizeisaburou
#
# GitHub (public): https://github.com/heizeisaburou/code-widgets/blob/main/sh/path-dups.sh

# path-dups ― imprime, una por línea, las entradas repetidas de un PATH.
# uso: path-dups             mira el $PATH de esta shell
#      path-dups "$CADENA"   mira la cadena que le pases
# Sale con 0 si no hay duplicados y con 1 si los hay.

printf '%s\n' "${1-$PATH}" | tr ':' '\n' | awk '
    {
        if (!($0 in n)) order[++k] = $0
        n[$0]++
        pos[$0] = pos[$0] (n[$0] > 1 ? "," : "") NR
    }
    END {
        for (i = 1; i <= k; i++) {
            d = order[i]
            if (n[d] > 1) {
                printf "%s  (%d veces, posiciones %s)\n", (d == "" ? "<vacía: directorio actual>" : d), n[d], pos[d]
                found = 1
            }
        }
        exit found
    }'
