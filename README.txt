

This git repo has 2 powershell scripts that help maintain the performance of the virtual machine instances that are used for high-performance computing. 
These scripts can be run from the powershell command line manually, or set up in Task Scheduler to run automatically. Both create logs in the working 
directory. 

CleanDirectory.ps1 <path> <age> <size threshold> <action(s)> <email message (optional)> 
Description: Checks the size of a folder and takes actions accordingly:
Arguments:
  <path>: Directory to act on. If the path starts with "userprofile" it will iterate over overy subfolder in C:\users
  <age>: Integer for days old to filter on, or "Any" 
  <size>: total size in GB to trigger action
  <action>: comma-separated (no spaces) combination of "Delete" and/or "Notify"
  <message>: If notify is one of the actions, this will be the text in the body of the email sent to the user.

CleanProcess.ps1 <name> <user state> <action(s)> <email message (optional)> 
Description: Checks to see who is using a specific program and takes actions accordingly:
Arguments:
  <name>: Program name to act on, as it shows up in the process column of the details tab in the task manager
  <age>: comma-separated (no spaces) combination of "Disc" and/or "Active". Disc (disconnected) users are people who close the RDP applicaiton but leave their session running 
  <action>: comma-separated (no spaces) combination of "Delete" and/or "Notify"
  <message>: If notify is one of the actions, this will be the text in the body of the email sent to the user
  
Automating cleanup tasks:
Running the python script VM_governance_GenerateTasks.py will create .xml files to import into Task Scheduler. The python script uses a json file called 
"VM_governance.json", and creates an .xml file based on a template (ApplicationTask.xml) for each CleanDirectory and CleanProcess run. The .xml files can
be imported into Task Scheduler, to run these in the future on an automated schedule (before or after reboot, etc).