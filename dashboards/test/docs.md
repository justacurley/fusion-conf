## **✅ SUCCESSFUL METHOD: How to Connect the Dots in PowerShell Universal ChartJS**

### **Key Success Factors:**

1. **Use `New-UDChartJSDataset` with `-AdditionalOptions`**
2. **Critical property: `showLine = $true`** - This is the magic setting that connects the dots!
3. **Supporting properties for smooth lines:**
   - `fill = $false` - Don't fill area under lines
   - `tension = 0.1` - Slight curve smoothing
   - `pointRadius = 4` - Visible data points
   - `borderWidth = 2` - Clear line thickness

### **Working Code Pattern:**
```powershell
$dataset = New-UDChartJSDataset -DataProperty "DataColumn" -Label "Series Name" -BackgroundColor "#color" -BorderColor "#color" -AdditionalOptions @{
    fill = $false
    tension = 0.1
    pointRadius = 4
    borderWidth = 2
    showLine = $true  # ← THIS IS THE KEY!
}
```

### **Additional Chart Options for Polish:**
```powershell
elements = @{
    line = @{
        tension = 0.1
    }
    point = @{
        radius = 4
    }
}
```

**The secret sauce was `showLine = $true` in the `AdditionalOptions` hashtable!** Without this, ChartJS treats line charts as scatter plots with disconnected points. With it, you get proper connected line series.

This approach works perfectly with PowerShell Universal's `New-UDChartJSDataset` pattern while giving us the connected lines we needed for the dual-series pain tracking chart! 📈