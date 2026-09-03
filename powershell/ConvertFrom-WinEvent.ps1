# 平生三郎 - https://github.com/heizeisaburou
#
# https://github.com/heizeisaburou/code-widgets/blob/main/powershell/ConvertFrom-WinEvent.ps1

# Convierte un registro de Get-WinEvent en un [pscustomobject] con todos sus
# campos accesibles por nombre, sin tener que indexar .Properties[n] ni parsear
# el texto de .Message.
#
# Cubre las tres formas en que un proveedor escribe sus datos:
#   <EventData><Data Name="X">v</Data>  -> lo normal (Sysmon, Security, ...)
#   <EventData><Data>v</Data>           -> proveedores clasicos, sin nombre
#   <UserData><LoQueSea><Campo>v</Campo>-> DNS, AppLocker, TerminalServices...
#
# Los nodos <Binary> de los proveedores clasicos se descartan a proposito: son
# un volcado hexadecimal sin valor de lectura.
#
# Por defecto solo salen cuatro cabeceras. Con -System se anade el resto de la
# mitad <System> del evento, y con -Message el texto renderizado.
function ConvertFrom-WinEvent
{
  [CmdletBinding()]
  param(
    [Parameter(Mandatory, ValueFromPipeline)]
    [System.Diagnostics.Eventing.Reader.EventRecord] $Event,
    [switch] $System,
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

    if ($x.Event.EventData) {
      $i = 0
      foreach ($node in $x.Event.EventData.ChildNodes) {
        if ($node.LocalName -ne 'Data') { continue }
        # GetAttribute en vez de $node.Name: la propiedad .Name del XmlElement
        # devuelve 'Data' cuando no hay atributo, y colapsaria todos los campos
        # de un proveedor clasico en una sola clave.
        $name = $node.GetAttribute('Name')
        if ([string]::IsNullOrEmpty($name)) { $name = "Data$i" }
        $d[$name] = $node.InnerText
        $i++
      }
    }

    if ($x.Event.UserData) {
      foreach ($container in $x.Event.UserData.ChildNodes) {
        foreach ($node in $container.ChildNodes) {
          $d[$node.LocalName] = $node.InnerText
        }
      }
    }

    # La otra mitad del evento, la de <System>. Va despues de los datos para no
    # empujar hacia abajo lo que se suele mirar.
    #
    # Todo prefijado con Sys porque cualquiera de estos nombres puede existir
    # tambien en EventData. El caso claro es ProcessId: el de <Execution> es el
    # del proceso que ESCRIBIO el evento -el servicio de Sysmon, p.ej.-, no el
    # del evento, y sin prefijo pisaria al ProcessId real.
    #
    # Se leen del EventRecord y no del XML: son los mismos campos, pero con su
    # tipo de verdad en vez de cadenas.
    if ($System) {
      $d['SysProviderId']        = $Event.ProviderId
      $d['SysVersion']           = $Event.Version
      $d['SysLevel']             = $Event.Level
      $d['SysTask']              = $Event.Task
      $d['SysOpcode']            = $Event.Opcode
      $d['SysKeywords']          = $Event.Keywords
      $d['SysRecordId']          = $Event.RecordId
      $d['SysChannel']           = $Event.LogName
      $d['SysComputer']          = $Event.MachineName
      $d['SysUserId']            = $Event.UserId
      $d['SysProcessId']         = $Event.ProcessId
      $d['SysThreadId']          = $Event.ThreadId
      $d['SysActivityId']        = $Event.ActivityId
      $d['SysRelatedActivityId'] = $Event.RelatedActivityId
    }

    # .Message se renderiza contra el manifiesto del proveedor y es caro: solo
    # bajo demanda, y al final para que no rompa un Format-Table.
    if ($Message) { $d['Message'] = $Event.Message }

    [pscustomobject]$d
  }
}

# Comprueba que ConvertFrom-WinEvent no pierde ningun campo del evento.
#
# Compara nombres, no recuentos, asi que da igual que cabeceras lleve el objeto.
#   Faltan      -> campos del XML que no llegaron al objeto
#   Repetidos   -> dos <Data> con el mismo Name; el segundo pisa al primero
#   Descartados -> nodos ignorados a proposito (<Binary>), informativo
function Test-WinEventCoverage
{
  [CmdletBinding()]
  param([Parameter(Mandatory, ValueFromPipeline)] $Event)
  process
  {
    $x = [xml]$Event.ToXml()

    $esperados   = New-Object System.Collections.Generic.List[string]
    $descartados = New-Object System.Collections.Generic.List[string]

    if ($x.Event.EventData) {
      $i = 0
      foreach ($n in $x.Event.EventData.ChildNodes) {
        if ($n.LocalName -ne 'Data') { $descartados.Add($n.LocalName); continue }
        $name = $n.GetAttribute('Name')
        if ([string]::IsNullOrEmpty($name)) { $name = "Data$i" }
        $esperados.Add($name)
        $i++
      }
    }

    if ($x.Event.UserData) {
      foreach ($c in $x.Event.UserData.ChildNodes) {
        foreach ($n in $c.ChildNodes) { $esperados.Add($n.LocalName) }
      }
    }

    # Sin -System ni -Message: solo interesan los campos del evento.
    $presentes = ($Event | ConvertFrom-WinEvent).PSObject.Properties.Name

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
