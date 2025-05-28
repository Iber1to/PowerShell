# Metodo para detecta si estamos en la fase de Autopilot. Devuelve False si estas en Autopilot y True si no lo estas.
# Este Script lo usaremos como Requirement rule.
$ProcessActive = Get-Process "WWAHost" -ErrorAction silentlycontinue
$CheckNull =   $null -eq $ProcessActive
$CheckNull