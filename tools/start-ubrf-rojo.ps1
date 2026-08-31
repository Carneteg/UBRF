<#
    Startar Rojo för UBRF — och bara för UBRF.

    Rojo-pluginen i Studio kommer ihåg vad den var kopplad till sist. Klickar
    man Connect utan att tänka efter kan den koppla upp sig mot ett HELT ANNAT
    projekts server, som ligger kvar på standardporten. Då synkas fel spel in i
    placen, och felsökningen börjar i UBRF-koden fast felet är en uppkoppling.

    Det har redan hänt en gång: en Studio-körning av UBRF drog in Nightfall
    Hollow-skript och ett gammalt UBRF-bygge samtidigt.

    Tre saker gör den här startaren svår att missbruka:

      · den pekar ut projektfilen EXPLICIT, aldrig via katalogsökning,
      · den kör på en egen port som ingen annan råkar använda,
      · den vägrar starta om projektfilen inte är UBRF:s.

    Kör från valfri katalog:  .\tools\start-ubrf-rojo.ps1
#>

[CmdletBinding()]
param(
    # Egen port med flit. Rojos vanliga 34872 är precis den som ett annat
    # projekt kan ligga kvar på, och som pluginen föreslår av gammal vana.
    [int] $Port = 34873
)

$ErrorActionPreference = 'Stop'

# Repo-roten härleds ur skriptets egen plats, inte ur var man råkar stå.
$rot = Split-Path -Parent (Split-Path -Parent $PSCommandPath)
$projekt = Join-Path $rot 'roblox/default.project.json'

if (-not (Test-Path -LiteralPath $projekt)) {
    Write-Error "Hittar inte projektfilen: $projekt"
    exit 1
}

# Namnkontroll, inte bara filkontroll. En felaktig men existerande fil skulle
# annars serveras glatt, och Studio hade visat fel träd utan att någon förstod
# varför.
try {
    $data = Get-Content -LiteralPath $projekt -Raw -Encoding UTF8 | ConvertFrom-Json
} catch {
    Write-Error "Projektfilen gar inte att lasa som JSON: $projekt"
    exit 1
}

if ($data.name -ne 'UBRF-Horse') {
    Write-Error ("Projektfilen heter '{0}', inte 'UBRF-Horse'. Startar inte — det har ar inte UBRF:s projekt." -f $data.name)
    exit 1
}

# Är porten upptagen är det nästan alltid en gammal Rojo som ligger kvar. Vi
# RAPPORTERAR den och slutar. Att döda processer åt någon annan är precis den
# sortens hjälpsamhet som tar fel process en dag när det är bråttom.
$upptagen = $null
if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
    $upptagen = Get-NetTCPConnection -LocalPort $Port -State Listen -ErrorAction SilentlyContinue |
        Select-Object -First 1
}

if ($upptagen) {
    $pid_ = $upptagen.OwningProcess
    $namn = (Get-Process -Id $pid_ -ErrorAction SilentlyContinue).ProcessName
    if (-not $namn) { $namn = 'okand process' }
    Write-Error ("Porten {0} ar redan upptagen av PID {1} ({2}). Stang den processen sjalv och kor om — jag dodar den inte at dig." -f $Port, $pid_, $namn)
    exit 1
}

if (-not (Get-Command rojo -ErrorAction SilentlyContinue)) {
    Write-Error "Hittar inte 'rojo' i PATH. Installera Rojo och forsok igen."
    exit 1
}

Write-Host ''
Write-Host '════════════════════════════════════════════════'
Write-Host ("  UBRF-Horse Rojo -> localhost:{0}" -f $Port)
Write-Host '════════════════════════════════════════════════'
Write-Host ("  projekt : {0}" -f $projekt)
Write-Host ''
Write-Host '  I Studio: Rojo-pluginen -> Connect, och kontrollera'
Write-Host ("  att den sager UBRF-Horse och porten {0}." -f $Port)
Write-Host '  Star det nagot annat projektnamn: AVBRYT.'
Write-Host ''

rojo serve $projekt --port $Port
exit $LASTEXITCODE
