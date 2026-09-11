# 平生三郎 - https://github.com/heizeisaburou
#
# GitHub (public): https://github.com/heizeisaburou/code-widgets/blob/main/powershell/ConvertFrom-SysmonEvent.ps1

# Version minima de ConvertFrom-WinEvent, pensada para teclear de memoria en una
# maquina donde no se puede pegar nada.
#
# Solo cubre <EventData> con atributo Name, que es lo que escribe Sysmon y la
# mayoria de proveedores modernos. Para el caso general
# (proveedores clasicos sin Name, y <UserData>) esta ConvertFrom-WinEvent.ps1,
# del que esta funcion es un subconjunto estricto.
function ConvertFrom-SysmonEvent
{
  [CmdletBinding()]
  param(
    [Parameter(ValueFromPipeline)] $Event,
    [switch] $Message
  )
  process
  {
    $x = [xml]$Event.ToXml()

    $d = [ordered]@{
      Id               = $Event.Id
      TimeCreated      = $Event.TimeCreated
      ProviderName     = $Event.ProviderName
      LevelDisplayName = $Event.LevelDisplayName
    }

    foreach ($node in $x.Event.EventData.Data) {
      $d[$node.Name] = $node.'#text'
    }

    if ($Message) { $d['Message'] = $Event.Message }

    [pscustomobject]$d
  }
}

# Comprueba que ConvertFrom-SysmonEvent no pierde ningun campo del evento.
#
# Mismo diseno que Test-WinEventCoverage, pero midiendo contra la version
# reducida. Por eso aqui los campos de <UserData> aparecen en Faltan: la version
# Sysmon no los mira. Y varios <Data> sin atributo Name caen todos en la clave
# 'Data', que sale en Repetidos.
function Test-SysmonEventCoverage
{
  [CmdletBinding()]
  param([Parameter(Mandatory, ValueFromPipeline)] $Event)
  process
  {
    $x = [xml]$Event.ToXml()

    $esperados   = New-Object System.Collections.Generic.List[string]
    $descartados = New-Object System.Collections.Generic.List[string]

    if ($x.Event.EventData) {
      foreach ($n in $x.Event.EventData.ChildNodes) {
        if ($n.LocalName -ne 'Data') { $descartados.Add($n.LocalName); continue }
        $name = $n.GetAttribute('Name')
        # sin atributo Name, $node.Name cae a la propiedad del elemento: 'Data'
        if ([string]::IsNullOrEmpty($name)) { $name = 'Data' }
        $esperados.Add($name)
      }
    }

    if ($x.Event.UserData) {
      foreach ($c in $x.Event.UserData.ChildNodes) {
        foreach ($n in $c.ChildNodes) { $esperados.Add($n.LocalName) }
      }
    }

    $presentes = ($Event | ConvertFrom-SysmonEvent).PSObject.Properties.Name

    $faltan = @($esperados |
        Select-Object -Unique |
        Where-Object { $_ -notin $presentes })

    $repetidos = @($esperados |
        Group-Object |
        Where-Object Count -gt 1 |
        ForEach-Object Name)

    $ok = ($faltan.Count -eq 0) -and ($repetidos.Count -eq 0)

    [pscustomobject]@{
      Id          = $Event.Id
      Provider    = $Event.ProviderName
      EnXml       = $esperados.Count
      Faltan      = ($faltan -join ', ')
      Repetidos   = ($repetidos -join ', ')
      Descartados = ($descartados -join ', ')
      OK          = $ok
    }
  }
}
