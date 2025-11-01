# Railway Database Deployment Script
# This script helps you connect to Railway PostgreSQL and deploy the database schema

Write-Host "🚀 Railway Database Deployment Helper" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green
Write-Host ""

# Check if the database recreation script exists
$scriptPath = "complete-database-recreation.sql"
if (-not (Test-Path $scriptPath)) {
    Write-Host "❌ Database recreation script not found!" -ForegroundColor Red
    Write-Host "Please make sure complete-database-recreation.sql exists in the current directory." -ForegroundColor Red
    exit 1
}

Write-Host "✅ Database recreation script found" -ForegroundColor Green
Write-Host "📄 Script: $scriptPath" -ForegroundColor Cyan
$fileSize = (Get-Item $scriptPath).Length / 1KB
Write-Host "📊 Size: $([math]::Round($fileSize, 2)) KB" -ForegroundColor Cyan
Write-Host ""

Write-Host "📋 Railway Database Connection Instructions" -ForegroundColor Yellow
Write-Host "==========================================" -ForegroundColor Yellow
Write-Host ""

Write-Host "1. Get your Railway DATABASE_URL:" -ForegroundColor White
Write-Host "   - Go to https://railway.app" -ForegroundColor Gray
Write-Host "   - Select your project" -ForegroundColor Gray
Write-Host "   - Click on your PostgreSQL database service" -ForegroundColor Gray
Write-Host "   - Go to 'Variables' tab" -ForegroundColor Gray
Write-Host "   - Copy the DATABASE_URL" -ForegroundColor Gray
Write-Host ""

Write-Host "2. Run the database recreation script:" -ForegroundColor White
Write-Host "   psql `"YOUR_DATABASE_URL`" -f complete-database-recreation.sql" -ForegroundColor Cyan
Write-Host ""

Write-Host "3. Alternative - Interactive connection:" -ForegroundColor White
Write-Host "   psql `"YOUR_DATABASE_URL`"" -ForegroundColor Cyan
Write-Host "   Then run: \i complete-database-recreation.sql" -ForegroundColor Cyan
Write-Host ""

Write-Host "4. Test the connection:" -ForegroundColor White
Write-Host "   psql `"YOUR_DATABASE_URL`" -c `"SELECT version();`"" -ForegroundColor Cyan
Write-Host ""

Write-Host "⚠️  Important Notes:" -ForegroundColor Yellow
Write-Host "   - Replace YOUR_DATABASE_URL with your actual Railway database URL" -ForegroundColor Gray
Write-Host "   - The script will completely recreate your database" -ForegroundColor Gray
Write-Host "   - Make sure you have a backup if needed" -ForegroundColor Gray
Write-Host "   - The script includes both DAK and FHIR R4 compliance" -ForegroundColor Gray
Write-Host ""

Write-Host "🎯 What the script will create:" -ForegroundColor Yellow
Write-Host "   ✅ Complete DAK compliance (all 14 decision points, 5 scheduling guidelines, 10 indicators)" -ForegroundColor Green
Write-Host "   ✅ Full FHIR R4 compliance (all resource types and operations)" -ForegroundColor Green
Write-Host "   ✅ Production-ready schema with proper indexing" -ForegroundColor Green
Write-Host "   ✅ Sample data for testing" -ForegroundColor Green
Write-Host "   ✅ Functions for compliance calculations" -ForegroundColor Green
Write-Host "   ✅ Triggers for automatic updates" -ForegroundColor Green
Write-Host "   ✅ Views for easy querying" -ForegroundColor Green
Write-Host ""

Write-Host "🚀 Ready to deploy your database!" -ForegroundColor Green
Write-Host "Copy your DATABASE_URL from Railway and run the psql command above." -ForegroundColor White
Write-Host ""

# Ask if user wants to proceed
$response = Read-Host "Do you want to proceed with the database deployment? (y/n)"
if ($response -eq "y" -or $response -eq "Y") {
    Write-Host ""
    Write-Host "Please enter your Railway DATABASE_URL:" -ForegroundColor Yellow
    $databaseUrl = Read-Host "DATABASE_URL"
    
    if ($databaseUrl) {
        Write-Host ""
        Write-Host "🚀 Deploying database schema..." -ForegroundColor Green
        Write-Host "This may take a few minutes..." -ForegroundColor Yellow
        
        try {
            # Run the psql command
            $command = "psql `"$databaseUrl`" -f complete-database-recreation.sql"
            Write-Host "Running: $command" -ForegroundColor Cyan
            Invoke-Expression $command
            
            Write-Host ""
            Write-Host "✅ Database deployment completed!" -ForegroundColor Green
            Write-Host "🎉 Your database now has complete DAK and FHIR R4 compliance!" -ForegroundColor Green
        }
        catch {
            Write-Host ""
            Write-Host "❌ Database deployment failed!" -ForegroundColor Red
            Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host ""
            Write-Host "Please check your DATABASE_URL and try again." -ForegroundColor Yellow
        }
    } else {
        Write-Host "❌ No DATABASE_URL provided. Exiting." -ForegroundColor Red
    }
} else {
    Write-Host "Database deployment cancelled." -ForegroundColor Yellow
}
