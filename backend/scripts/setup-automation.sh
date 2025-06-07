#!/bin/bash

# Tim Balance Update Automation Setup
# This script helps you set up automated daily balance updates

echo "🚀 Tim Balance Update Automation Setup"
echo "======================================"
echo ""

# Get the current directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

echo "📁 Project directory: $PROJECT_DIR"
echo ""

# Check if Node.js is available
if ! command -v node &> /dev/null; then
    echo "❌ Node.js not found. Please install Node.js first."
    exit 1
fi

echo "✅ Node.js found: $(node --version)"
echo ""

echo "⚙️  Automation Options:"
echo ""
echo "1. 📅 Daily Cron Job (recommended)"
echo "   Runs once per day at 9 AM"
echo ""
echo "2. ⏰ Continuous Mode"
echo "   Runs every hour while your computer is on"
echo ""
echo "3. 🖱️  Manual Only"
echo "   Run the script manually when needed"
echo ""

read -p "Choose option (1, 2, or 3): " choice

case $choice in
    1)
        echo ""
        echo "📅 Setting up daily cron job..."
        
        # Create cron job entry
        CRON_COMMAND="0 9 * * * cd $PROJECT_DIR && node scripts/daily-balance-update.js >> logs/balance-updates.log 2>&1"
        
        # Create logs directory
        mkdir -p "$PROJECT_DIR/logs"
        
        # Add to crontab
        (crontab -l 2>/dev/null; echo "$CRON_COMMAND") | crontab -
        
        echo "✅ Daily cron job added!"
        echo "📊 Updates will run every day at 9:00 AM"
        echo "📝 Logs will be saved to: $PROJECT_DIR/logs/balance-updates.log"
        ;;
        
    2)
        echo ""
        echo "⏰ Starting continuous mode..."
        echo "💡 This will run in the background. Press Ctrl+C to stop."
        echo ""
        
        # Create logs directory
        mkdir -p "$PROJECT_DIR/logs"
        
        # Run in continuous mode
        cd "$PROJECT_DIR"
        node scripts/daily-balance-update.js --watch | tee logs/balance-updates.log
        ;;
        
    3)
        echo ""
        echo "🖱️  Manual mode selected."
        echo ""
        echo "💡 To run balance updates manually:"
        echo "   cd $PROJECT_DIR"
        echo "   node scripts/daily-balance-update.js"
        ;;
        
    *)
        echo ""
        echo "❌ Invalid choice. Please run the script again."
        exit 1
        ;;
esac

echo ""
echo "🎯 Next Steps:"
echo "1. Connect sandbox accounts in your iOS app"
echo "2. Configure account categories (inflow/outflow)"
echo "3. Watch your widget show real progression over time!"
echo ""
echo "✅ Setup complete!" 