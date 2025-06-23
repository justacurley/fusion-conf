New-UDApp -Content { 
    
    New-UDButton -Text "Add Controls" -OnClick {

        New-udform -Id 'dynamic-form' -Content {
            # Initial controls
            New-UDRow -Id "ControlContainer" -Content {
                New-UDColumn -Content {
                    New-UDSelect -Id "Dropdown1" -Option { 
                        @(
                            New-UDSelectOption -Name "Option 1" -Value "Option1", 
                            New-UDSelectOption -Name "Option 2" -Value "Option2", 
                            New-UDSelectOption -Name "Option 3" -Value "Option3" 
                        )
                    }
                    New-UDTextbox -Id "Textbox1"
                }
            }
        } -Endpoint {
            $count = (Get-UDElement -Id "ControlContainer").Content.Count

            # Adding new controls
            New-UDRow -Content {
                New-UDColumn -Content {
                    New-UDSelect -Id "Dropdown$count" -Option { 
                        @( 
                            New-UDSelectOption -Name "Option 1" -Value "Option1", 
                            New-UDSelectOption -Name "Option 2" -Value "Option2", 
                            New-UDSelectOption -Name "Option 3" -Value "Option3" 
                        )
                    }
                    New-UDTextbox -Id "Textbox$count"
                }
            } | Add-UDElement -Id "ControlContainer"
        }
    } 
}


