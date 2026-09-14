# 平生三郎 - https://github.com/heizeisaburou
#
# GitHub (public): https://github.com/heizeisaburou/code-widgets/blob/main/powershell/Add-Path.ps1

# Apenda directorios al PATH de la sesion actual de PowerShell. Solo agrega los
# que existen y nunca crea entradas duplicadas. No toca el PATH del usuario ni
# el del sistema.
#
#   Add-Path $HOME\bin $HOME\scripts
#
# Resolve-Path normaliza antes de comparar -resuelve una ruta relativa y
# expande un ..- y el TrimEnd a los dos lados evita que C:\bin y C:\bin\
# cuenten como carpetas distintas. [IO.Path]::PathSeparator devuelve ; en
# Windows y : en Unix, asi que la funcion sirve tambien en pwsh sobre Linux.
#
# Ojo: esto es el PATH de la sesion. Colocarlo en $PROFILE no equivale a un
# .bashrc: solo lo ven las consolas de PowerShell, no cmd ni el menu Inicio.
function Add-Path
{
  param([Parameter(ValueFromRemainingArguments)] [string[]] $Path)

  $sep = [IO.Path]::PathSeparator
  foreach ($p in $Path)
  {
    if (-not (Test-Path -LiteralPath $p -PathType Container)) { continue }
    $full    = (Resolve-Path -LiteralPath $p).Path.TrimEnd('\', '/')
    $current = @($env:PATH -split $sep | ForEach-Object { $_.TrimEnd('\', '/') })
    if ($current -notcontains $full) { $env:PATH += "$sep$full" }
  }
}
