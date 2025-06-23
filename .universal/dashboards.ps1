New-PSUApp -Name "entries" -FilePath "dashboards/Entries/Entries.ps1" -BaseUrl "/entries" -Environment "PowerShell 7" -AutoDeploy -Description "Add or update entries" 
New-PSUApp -Name "gallery" -FilePath "dashboards/gallery/gallery.ps1" -BaseUrl "/gallery" -AutoDeploy -Description "Gallery of incision healing" 
New-PSUApp -Name "testapp" -FilePath "dashboards/test/test.ps1" -BaseUrl "/testapp" -Environment "PowerShell 7" -AutoDeploy -Description "test stuff" 
New-PSUApp -Name "testb" -FilePath "dashboards/testb/testb.ps1" -BaseUrl "/testb" -Environment "PowerShell 7" -AutoDeploy