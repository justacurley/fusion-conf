New-PSUApp -Name "ActivityTimeline" -FilePath "dashboards/ActivityTimeline/ActivityTimeline.ps1" -BaseUrl "/activitytimeline" -Authenticated -Role @('User') -AutoDeploy 
New-PSUApp -Name "charts" -FilePath "dashboards/charts/charts.ps1" -BaseUrl "/charts" -Environment "PowerShell 7" -AutoDeploy -Description "charts" 
New-PSUApp -Name "entries" -FilePath "dashboards/Entries/Entries.ps1" -BaseUrl "/entries" -Environment "PowerShell 7" -Authenticated -AutoDeploy -Description "Add or update entries" 
New-PSUApp -Name "gallery" -FilePath "dashboards/gallery/gallery.ps1" -BaseUrl "/gallery" -AutoDeploy -Description "Gallery of incision healing" 
New-PSUApp -Name "HealthTimeline" -FilePath "dashboards/timeline/timeline.ps1" -BaseUrl "/healthtimeline" -Environment "PowerShell 7" -Authenticated -Role @('User') -AutoDeploy 
New-PSUApp -Name "HomePage" -FilePath "dashboards/home/home-app.ps1" -BaseUrl "/home" -Environment "PowerShell 7" -Authenticated -Role @('User') -AutoDeploy -Description "Health Dashboard Homepage with Navigation" 
New-PSUApp -Name "Registration" -FilePath "dashboards/Registration/Registration.ps1" -BaseUrl "/register" -Environment "Integrated" -AutoDeploy -Description "multi-user registration page" 
New-PSUApp -Name "test" -FilePath "dashboards/test/test.ps1" -BaseUrl "/testme" -Environment "PowerShell 7" -Authenticated -AutoDeploy 
New-PSUApp -Name "Test Viewer" -FilePath "dashboards/Test Viewer/Test Viewer.ps1" -BaseUrl "/test-viewer" -Authenticated -AutoDeploy -Description "A Pester test result viewer for PowerShell Universal." -Module "PowerShellUniversal.Apps.Pester" -Command "New-UDPesterApp" 
New-PSUApp -Name "test_calendars" -FilePath "dashboards/test_calendars/test_calendars.ps1" -BaseUrl "/testcalendar" -Environment "PowerShell 7" -Authenticated -AutoDeploy 
New-PSUApp -Name "UpdateEntries" -FilePath "dashboards/UpdateEntries/UpdateEntries.ps1" -BaseUrl "/updateentry" -Authenticated -AutoDeploy