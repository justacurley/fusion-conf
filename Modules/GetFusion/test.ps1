ipmo /home/alex/src/fusion-conf/Modules/GetFusion -Force
$MedData = Get-EntriesData /home/alex/src/fusion-conf/fusion-data/entries_updated.json
Get-DateActivityData "0626" $MedData."0626"