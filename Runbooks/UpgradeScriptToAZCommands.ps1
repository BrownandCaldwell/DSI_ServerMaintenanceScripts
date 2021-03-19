Import-Module Az.Tools.Migration
# Generate an upgrade plan for all the scripts and module files in the specified folder and save it to a variable.

#Change DirectoryPath to location of Script
$DirectoryPath = 'C:\Users\bmauri\OneDrive - Brown and Caldwell\Not Shared\Projects\Azure\Update Management\Scripts\New'
New-AzUpgradeModulePlan -FromAzureRmVersion 6.13.1 -ToAzVersion 4.6.1 -DirectoryPath $DirectoryPath -OutVariable Plan

# Filter plan results to only warnings and errors
$Plan | Where-Object PlanResult -ne ReadyToUpgrade | Format-List


# Execute the automatic upgrade plan and save the results to a variable.
Invoke-AzUpgradeModulePlan -Plan $Plan -FileEditMode SaveChangesToNewFiles -OutVariable Results

# Filter results to show only errors
$Results | Where-Object UpgradeResult -ne UpgradeCompleted | Format-List