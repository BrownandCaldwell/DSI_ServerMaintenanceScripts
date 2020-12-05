$limit = (Get-Date).AddDays(-7)
$Users = Get-ChildItem "C:\Users" -Exclude azrlcladm,Public,s-mpm
#$Users = Get-ChildItem "C:\Users" -Exclude azrlcladm,Public,s-mpm,!BSkousen,!cgibson,!csomerlot,-afugal,-mposhaughnessy,afugal,bskousen,csomerlot,ctoro,djoachim,DPDavis,Dshapiro,MOHAre,Msafranek,PWhitby,rravisangar,skowalczyk
$Users | ForEach-Object {
    Get-ChildItem -Path "C:\Users\$($_.Name)\AppData\Local\ESRI\Local Caches\" -Recurse | Where-Object { ($_.LastWriteTime -lt $limit) } | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
}
