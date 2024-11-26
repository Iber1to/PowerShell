# https://learn.microsoft.com/es-es/mem/intune/protect/windows-10-expedite-updates

$Session = New-Object -ComObject Microsoft.Update.Session
$Searcher = $Session.CreateUpdateSearcher()
$historyCount = $Searcher.GetTotalHistoryCount()
$list = $Searcher.QueryHistory(0, $historyCount) | Select-Object -Property "Title"
foreach ($update in $list)
{
   if ($update.Title.Contains("4023057"))
   {
      return 1
      exit 0
   }
}
return 0
exit 1