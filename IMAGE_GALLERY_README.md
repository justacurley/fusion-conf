# Fusion Image Gallery

A PowerShell Universal web interface for displaying images stored in the `fusion-data/img` directory.

## Features

- **📸 Gallery View**: Modern, responsive grid layout for image browsing
- **🔍 Image Preview**: Click any image to view full-size in a modal
- **📊 Metadata Display**: Shows file size and last modified date
- **🎨 Modern UI**: Clean, professional design with hover effects
- **📱 Responsive**: Works on desktop, tablet, and mobile devices
- **🔒 Secure**: Path validation prevents directory traversal attacks

## Endpoints

### 1. Gallery Web Interface
**URL:** `/gallery`
**Method:** GET
**Description:** Main image gallery webpage with visual interface

**Features:**
- Grid layout of image thumbnails
- Image metadata (name, size, date)
- Click to view full-size images
- Modal overlay for detailed viewing
- Responsive design

### 2. Individual Image Serving
**URL:** `/api/image/{imageName}`
**Method:** GET
**Description:** Serves individual image files

**Examples:**
- `/api/image/0521.png`
- `/api/image/0604.jpg`
- `/api/image/0619.jpg`

**Supported formats:**
- JPG/JPEG
- PNG
- GIF
- BMP
- WebP

### 3. Images List API
**URL:** `/api/images`
**Method:** GET
**Description:** Returns JSON list of all available images

**Response format:**
```json
{
  "count": 12,
  "images": [
    {
      "name": "0521.png",
      "size": 45230,
      "sizeFormatted": "44.17 KB",
      "lastModified": "2025-06-19T10:30:00Z",
      "extension": ".png",
      "url": "/api/image/0521.png"
    }
  ],
  "path": "fusion-data/img",
  "generated": "2025-06-19T15:45:30Z"
}
```

## Usage

### Viewing the Gallery
1. Start your PowerShell Universal server
2. Navigate to `http://your-server:port/gallery`
3. Browse images in the grid layout
4. Click any image to view full-size

### Programmatic Access
```powershell
# Get list of all images
$images = Invoke-RestMethod -Uri "http://your-server:port/api/images"

# Download a specific image
Invoke-WebRequest -Uri "http://your-server:port/api/image/0521.png" -OutFile "downloaded-image.png"
```

### JavaScript Integration
```javascript
// Fetch image list
fetch('/api/images')
  .then(response => response.json())
  .then(data => {
    console.log(`Found ${data.count} images`);
    data.images.forEach(image => {
      console.log(`${image.name} - ${image.sizeFormatted}`);
    });
  });
```

## Directory Structure

```
fusion-conf/
├── .universal/
│   ├── endpoints/
│   │   └── gallery/
│   │       ├── gallery.ps1    # Main gallery webpage
│   │       ├── image.ps1      # Image serving endpoint
│   │       └── api.ps1        # JSON API endpoint
│   └── endpoints.ps1          # Endpoint configuration
└── fusion-data/
    └── img/                   # Image storage directory
        ├── 0521.png
        ├── 0523.png
        ├── 0604.jpg
        └── ...
```

## Security Features

- **Path Validation**: Prevents access to files outside the img directory
- **File Type Filtering**: Only serves recognized image formats
- **Zone.Identifier Exclusion**: Automatically filters out Windows security zone files
- **Error Handling**: Graceful handling of missing or invalid files

## Customization

### Adding New Image Formats
Edit the `$ImageExtensions` array in the PowerShell scripts:
```powershell
$ImageExtensions = @("*.jpg", "*.jpeg", "*.png", "*.gif", "*.bmp", "*.webp", "*.svg")
```

### Styling Changes
The gallery webpage includes embedded CSS that can be modified to change:
- Grid layout (columns, spacing)
- Color scheme
- Card styling
- Modal appearance

### Adding Upload Functionality
You can extend the system by adding upload endpoints:
```powershell
New-PSUEndpoint -Url "/api/upload" -Method @('POST') -Path "/endpoints/gallery/upload.ps1"
```

## Image Management

### Supported Operations
- **View**: Browse all images in gallery format
- **Serve**: Direct access to individual images
- **List**: Programmatic access to image metadata

### File Organization
Images are automatically:
- Sorted alphabetically by filename
- Filtered to show only valid image files
- Displayed with metadata (size, date)

### Best Practices
1. Use descriptive filenames (e.g., date-based: `0619.jpg`)
2. Keep image sizes reasonable for web viewing
3. Use standard formats (JPG, PNG) for best compatibility
4. Organize by date or category if needed

## Troubleshooting

### Images Not Appearing
1. Check that files are in `fusion-data/img/` directory
2. Verify file extensions are supported
3. Ensure PowerShell Universal has read access to the directory

### Security Errors
1. Verify the image path is correctly calculated
2. Check that no path traversal attempts are being made
3. Ensure Zone.Identifier files are filtered out

### Performance Issues
1. Consider image optimization for large files
2. Implement pagination for large image collections
3. Add caching headers for better performance

## Integration with Health Tracking

This image gallery complements your health tracking system by providing:
- Visual documentation of health-related images
- Date-based organization (matching your health entries)
- API access for programmatic integration with health data
- Web interface for easy review and management

The image filenames (0521.png, 0604.jpg, etc.) appear to follow a date pattern that could correlate with your health tracking entries in DynamoDB.
