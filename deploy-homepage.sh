#!/bin/bash

echo "🚀 Deploying Health Dashboard Homepage..."

# Step 1: Add all changes to git
echo "📝 Adding changes to git..."
git add .

# Step 2: Commit the changes
echo "� Committing homepage changes..."
git commit -m "Add comprehensive health dashboard homepage with navigation

- Created homepage app with statistics overview
- Added quick action buttons for common tasks
- Added dashboard overview cards for all features
- Updated portal pages configuration
- Fixed dashboard URLs and navigation links"

# Step 3: Push to repository
echo "🔄 Pushing changes to repository..."
git push

if [ $? -eq 0 ]; then
    echo "✅ Changes pushed successfully!"
    echo "🤖 PowerShell Universal will automatically deploy the new homepage"
    echo ""
    echo "🌐 Your homepage will be available at: https://fusion.acurley.dev/"
    echo ""
    echo "📋 Available dashboards:"
    echo "  🏠 Homepage: https://fusion.acurley.dev/"
    echo "  📝 Entries: https://fusion.acurley.dev/entries"
    echo "  📊 Charts: https://fusion.acurley.dev/charts"
    echo "  🏃 Activity Timeline: https://fusion.acurley.dev/activitytimeline"
    echo "  📅 Health Timeline: https://fusion.acurley.dev/timeline"
    echo "  🖼️ Gallery: https://fusion.acurley.dev/gallery"
    echo "  🧪 Pain Analysis: https://fusion.acurley.dev/testme"
    echo ""
    echo "⏱️  PowerShell Universal typically takes 1-2 minutes to deploy changes"
    echo "🎉 Deployment initiated! Check your homepage shortly!"
else
    echo "❌ Error: Failed to push changes to repository"
    exit 1
fi
