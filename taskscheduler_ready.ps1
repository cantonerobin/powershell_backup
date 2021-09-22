########################################################################
# Autor:     Cantone Robin
# Version:   1.0
# Date:      20.09.2021
# Function:  Create one time Backups or Backup Routines with Taskscheduler
########################################################################


function backup_client {
#Import the Assemblies Libraries
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null

### Generated all the Form Objects
#The whole window
$frm_whole_form = New-Object System.Windows.Forms.Form
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState

#Welcome Elements
$Lbl_welcome = New-Object System.Windows.Forms.Label            #Welcome text 
$Lbl_options = New-Object System.Windows.Forms.Label            #Function explanation


#Path Elements
$Lbl_original_path = New-Object System.Windows.Forms.Label                   #Choose original Path
$Btn_original_path = New-Object System.Windows.Forms.Button                  #Select original Path
$Dialog_original_path = New-Object System.Windows.Forms.FolderBrowserDialog  #Open File Explorer and select Folder
$Tbx_original_path = New-Object System.Windows.Forms.TextBox                 #Show original Path 

$Lbl_backup_path = New-Object System.Windows.Forms.Label                     #Choose backup Path
$Btn_backup_path = New-Object System.Windows.Forms.Button                    #Select backup Path
$Dialog_backup_path = New-Object System.Windows.Forms.FolderBrowserDialog    #Open File Explorer and select Folder
$Tbx_backup_path = New-Object System.Windows.Forms.TextBox                   #Show Backup Path


#Compression Element
$Lbl_compress_backup = New-Object System.Windows.Forms.Label    #ask for Compression
$Check_zip = New-Object System.Windows.Forms.CheckBox           #Yes/No


#Backup Routine Elements
$Lbl_DD_periode = New-Object System.Windows.Forms.Label         #Explanation for Routine
$DD_periode = New-Object System.Windows.Forms.ComboBox          #Dropdown for Routine (Daily/weekly/Monthly)

$Lbl_dayofweek = New-Object System.Windows.Forms.Label          #Explanation for Day of Week
$DD_dayofweek = New-Object System.Windows.Forms.ComboBox        #Dropdown for Day of Week

$Lbl_DD_time = New-Object System.Windows.Forms.Label            #Explanation for Time
$DD_time = New-Object System.Windows.Forms.ComboBox             #Dropdown for Time


#Start Backup or Cancel Buttons
$Btn_cancel = New-Object System.Windows.Forms.Button            #Close Form
$Btn_add_routine = New-Object System.Windows.Forms.Button       #Add backup routine
$Btn_start_backup = New-Object System.Windows.Forms.Button      #Start Backup


$splitter1 = New-Object System.Windows.Forms.Splitter

### Add Functionalitys to the Form Objects

#read actual date and format it
        $date = get-date -Format  "dd.MM.yyyy HH:mm:ss"
        $date = $date -replace ":",""
        $date = $date  -replace "\.",""
        $date = $date  -replace " ",""


$Btn_original_path_OnClick=
{
        #set standard Path for File Dialog
        $Dialog_original_path.SelectedPath = "$env:userprofile\Documents"
        
        #Open Forms with before set default path
        $ok = $Dialog_original_path.ShowDialog()
        if ($ok -eq "OK")
        {
            #Show selected Path in Textbox
            $Tbx_original_path.Text = $Dialog_original_path.SelectedPath #Gibt selektierten Ordner zurück
        }
        
        else
        {
            #When no Direcotry is selected
            $Tbx_original_path.Text = "No Directory was selected.."
        }
}

$Btn_backup_path_OnClick= 
{
        
        #set standard Path for File Dialog
        $Dialog_backup_path.SelectedPath = "$env:userprofile\Documents"
        
        #Open Forms with before set default path
        $ok = $Dialog_backup_path.ShowDialog()
        if ($ok -eq "OK") 
        {
            #Show selected Path in Textbox
            $Tbx_backup_path.Text = $Dialog_backup_path.SelectedPath
            $Tbx_backup_path.Text = $Tbx_backup_path.Text + "\Backup" + $date
        }
        
        else
        {
            #When no Direcotry is selected
            $Tbx_backup_path.Text = "No Directory was selected.."
        }
}


$handler_Btn_start_backup_Click= 
{

    #When the Zip Checkbox is ticked
    if ($Check_zip.Checked)
    {
        #Create or add to an existing Archive
        Compress-Archive -Path $Tbx_original_path.Text -Update -DestinationPath $Tbx_backup_path.Text
    }

    else 
    {  
        #Copy the Directory
        copy-item -recurse $Tbx_original_path.Text $Tbx_backup_path.Text
    }     
}

$Btn_add_routine_OnClick= 
    {

        #read periode from Dropdown
        $periode = $DD_periode.SelectedItem.ToString()
    
        if ($periode -ne "Daily")
        {
            #read DayOfWeek from Dropdown
            $dayofweek = $DD_dayofweek.SelectedItem.ToString()
        }

        #read Time from Dropdown
        $time = $DD_time.SelectedItem.ToString()
    
        
        #generate save path for the Script
        $script_path =  "'$env:USERPROFILE'\Documents\tasksch" + $date + ".ps1"

        #remove unwanted characters (whitespaces and ')
        $script_path = $script_path -replace "\s","" 
        $script_path = $script_path -replace "'",""


     ################################# Generate Task in Task Scheduler ******************************************     
        #define Task name
        $task_name = "AutomatedBackup" + $date
        
        #Generate new Action
        $Action = New-ScheduledTaskAction -Execute "Powershell.exe" -Argument "$script_path -NonInteractive -NoLogo -NoProfile "
 
        #execute when Daily is selected
        if ($periode -eq "Daily")
        {
            #Define Trigger
            $Trigger = New-ScheduledTaskTrigger -Daily -At $time
        }

        elseif ($periode -eq "Weekly")
        {   
            #Define Trigger
            $Trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek $dayofweek -At $time
        }

        elseif ($periode -eq "Monthly")
        {
            #Define Trigger
            $Trigger = New-ScheduledTaskTrigger -Weekly -WeeksInterval 4 -DaysOfWeek $dayofweek -At $time
        }

        #Give additional Settings (requiered)
        $Settings = New-ScheduledTaskSettingsSet

        #Put it all together
        $Task = New-ScheduledTask -Action $Action -Trigger $Trigger -Settings $Settings

        #Add it to the Scheduler
        Register-ScheduledTask -TaskName $task_name -InputObject $Task

        #Create a File with the following Content
        #When the Zip Checkbox is ticked
        if ($Check_zip.Checked)
        {
            #Create or add to an existing Archive
            New-Item $script_path -Value "Compress-Archive -Path $($Tbx_original_path.Text) -Update -DestinationPath $($Tbx_backup_path.Text)"
        }

        else 
        {  
            #Copy the Directory
            New-Item $script_path -Value "copy-item -recurse $($Tbx_original_path.Text) $($Tbx_backup_path.Text)"
        }

        #Report status
        task_added

    }

$handler_Btn_cancel_Click= 
{

    #close Form
    $frm_whole_form.Close()

}

$Btn_start_backup_OnClick= 
{
      
      
}

$handler_checkBox1_CheckedChanged=
{
#TODO: Place custom script here

}



$handler_frm_default_Load= 
{
#TODO: Place custom script here

}



$Check_zip_action= 
{
#TODO: Place custom script here

}

$handler_label5_Click= 
{
#TODO: Place custom script here

}



$handler_label4_Click= 
{
#TODO: Place custom script here

}

$handler_Lbl_DD_time_Click= 
{
#TODO: Place custom script here

}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$frm_whole_form.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 533
$System_Drawing_Size.Width = 428
$frm_whole_form.ClientSize = $System_Drawing_Size
$frm_whole_form.DataBindings.DefaultDataSourceUpdateMode = 0
$frm_whole_form.Name = "frm_whole_form"
$frm_whole_form.Text = "Backup Client"
$frm_whole_form.add_Load($handler_frm_default_Load)

$DD_dayofweek.DataBindings.DefaultDataSourceUpdateMode = 0
$DD_dayofweek.FormattingEnabled = $True
$DD_dayofweek.Items.Add("Monday")|Out-Null
$DD_dayofweek.Items.Add("Tuesday")|Out-Null
$DD_dayofweek.Items.Add("Wednesday")|Out-Null
$DD_dayofweek.Items.Add("Thursday")|Out-Null
$DD_dayofweek.Items.Add("Friday")|Out-Null
$DD_dayofweek.Items.Add("Saturday")|Out-Null
$DD_dayofweek.Items.Add("Sunday")|Out-Null
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 201
$System_Drawing_Point.Y = 360
$DD_dayofweek.Location = $System_Drawing_Point
$DD_dayofweek.Name = "DD_dayofweek"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 21
$System_Drawing_Size.Width = 121
$DD_dayofweek.Size = $System_Drawing_Size
$DD_dayofweek.TabIndex = 25
#make the Textbox not editable
$DD_dayofweek.DropDownStyle = 2



$frm_whole_form.Controls.Add($DD_dayofweek)

$Lbl_dayofweek.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 201
$System_Drawing_Point.Y = 334
$Lbl_dayofweek.Location = $System_Drawing_Point
$Lbl_dayofweek.Name = "Lbl_dayofweek"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 178
$Lbl_dayofweek.Size = $System_Drawing_Size
$Lbl_dayofweek.TabIndex = 24
$Lbl_dayofweek.Text = "Choose the Day of the Week"

$frm_whole_form.Controls.Add($Lbl_dayofweek)

$DD_time.DataBindings.DefaultDataSourceUpdateMode = 0
$DD_time.FormattingEnabled = $True
$DD_time.Items.Add("1am")|Out-Null
$DD_time.Items.Add("2am")|Out-Null
$DD_time.Items.Add("3am")|Out-Null
$DD_time.Items.Add("4am")|Out-Null
$DD_time.Items.Add("5am")|Out-Null
$DD_time.Items.Add("6am")|Out-Null
$DD_time.Items.Add("7am")|Out-Null
$DD_time.Items.Add("8am")|Out-Null
$DD_time.Items.Add("9am")|Out-Null
$DD_time.Items.Add("10am")|Out-Null
$DD_time.Items.Add("11am")|Out-Null
$DD_time.Items.Add("12am")|Out-Null
$DD_time.Items.Add("1pm")|Out-Null
$DD_time.Items.Add("2pm")|Out-Null
$DD_time.Items.Add("3pm")|Out-Null
$DD_time.Items.Add("4pm")|Out-Null
$DD_time.Items.Add("5pm")|Out-Null
$DD_time.Items.Add("6pm")|Out-Null
$DD_time.Items.Add("7pm")|Out-Null
$DD_time.Items.Add("8pm")|Out-Null
$DD_time.Items.Add("9pm")|Out-Null
$DD_time.Items.Add("10pm")|Out-Null
$DD_time.Items.Add("11pm")|Out-Null
$DD_time.Items.Add("12pm")|Out-Null
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 415
$DD_time.Location = $System_Drawing_Point
$DD_time.Name = "DD_time"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 21
$System_Drawing_Size.Width = 121
$DD_time.Size = $System_Drawing_Size
$DD_time.TabIndex = 23
#make the Textbox not editable
$DD_time.DropDownStyle = 2

$frm_whole_form.Controls.Add($DD_time)

$Lbl_DD_time.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 16
$System_Drawing_Point.Y = 397
$Lbl_DD_time.Location = $System_Drawing_Point
$Lbl_DD_time.Name = "Lbl_DD_time"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 100
$Lbl_DD_time.Size = $System_Drawing_Size
$Lbl_DD_time.TabIndex = 22
$Lbl_DD_time.Text = "Choose Start Time"
$Lbl_DD_time.add_Click($handler_Lbl_DD_time_Click)

$frm_whole_form.Controls.Add($Lbl_DD_time)

$Lbl_DD_periode.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 334
$Lbl_DD_periode.Location = $System_Drawing_Point
$Lbl_DD_periode.Name = "Lbl_DD_periode"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 206
$Lbl_DD_periode.Size = $System_Drawing_Size
$Lbl_DD_periode.TabIndex = 21
$Lbl_DD_periode.Text = "How often do you want Backups?"

$frm_whole_form.Controls.Add($Lbl_DD_periode)

$DD_periode.DataBindings.DefaultDataSourceUpdateMode = 0
$DD_periode.FormattingEnabled = $True
$DD_periode.Items.Add("Daily")|Out-Null
$DD_periode.Items.Add("Weekly")|Out-Null
$DD_periode.Items.Add("Monthly")|Out-Null
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 360
$DD_periode.Location = $System_Drawing_Point
$DD_periode.Name = "DD_periode"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 21
$System_Drawing_Size.Width = 121
$DD_periode.Size = $System_Drawing_Size
$DD_periode.TabIndex = 20
#make the Textbox not editable
$DD_periode.DropDownStyle = 2


$frm_whole_form.Controls.Add($DD_periode)


$splitter1.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 0
$System_Drawing_Point.Y = 0
$splitter1.Location = $System_Drawing_Point
$splitter1.Name = "splitter1"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 533
$System_Drawing_Size.Width = 3
$splitter1.Size = $System_Drawing_Size
$splitter1.TabIndex = 18
$splitter1.TabStop = $False

$frm_whole_form.Controls.Add($splitter1)

$Lbl_options.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 33
$Lbl_options.Location = $System_Drawing_Point
$Lbl_options.Name = "Lbl_options"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 39
$System_Drawing_Size.Width = 394
$Lbl_options.Size = $System_Drawing_Size
$Lbl_options.TabIndex = 16
$Lbl_options.Text = "You have the Option between a one Time Backup or automated Backups."

$frm_whole_form.Controls.Add($Lbl_options)


$Btn_add_routine.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 87
$System_Drawing_Point.Y = 471
$Btn_add_routine.Location = $System_Drawing_Point
$Btn_add_routine.Name = "Btn_add_routine"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 150
$Btn_add_routine.Size = $System_Drawing_Size
$Btn_add_routine.TabIndex = 14
$Btn_add_routine.Text = "add Backup routine"
$Btn_add_routine.UseVisualStyleBackColor = $True
$Btn_add_routine.add_Click($Btn_add_routine_OnClick)

$frm_whole_form.Controls.Add($Btn_add_routine)

$Tbx_backup_path.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 181
$Tbx_backup_path.Location = $System_Drawing_Point
$Tbx_backup_path.Name = "Tbx_backup_path"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 175
$Tbx_backup_path.Size = $System_Drawing_Size
$Tbx_backup_path.TabIndex = 13
$Tbx_backup_path.Text = "select path ..."
#read only for textbox
$Tbx_backup_path.ReadOnly = 'true'

$frm_whole_form.Controls.Add($Tbx_backup_path)

$Tbx_original_path.DataBindings.DefaultDataSourceUpdateMode = 0
$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 107
$Tbx_original_path.Location = $System_Drawing_Point
$Tbx_original_path.Name = "Tbx_original_path"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 20
$System_Drawing_Size.Width = 180
$Tbx_original_path.Size = $System_Drawing_Size
$Tbx_original_path.TabIndex = 12
$Tbx_original_path.Text = "select path ..."
#read only for textbox
$Tbx_original_path.ReadOnly = 'true'

$frm_whole_form.Controls.Add($Tbx_original_path)

$Lbl_compress_backup.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 230
$Lbl_compress_backup.Location = $System_Drawing_Point
$Lbl_compress_backup.Name = "Lbl_compress_backup"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 305
$Lbl_compress_backup.Size = $System_Drawing_Size
$Lbl_compress_backup.TabIndex = 11
$Lbl_compress_backup.Text = "Do you want compression?"
$Lbl_compress_backup.add_Click($handler_label4_Click)

$frm_whole_form.Controls.Add($Lbl_compress_backup)


$Check_zip.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 256
$Check_zip.Location = $System_Drawing_Point
$Check_zip.Name = "Check_zip"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 24
$System_Drawing_Size.Width = 55
$Check_zip.Size = $System_Drawing_Size
$Check_zip.TabIndex = 9
$Check_zip.Text = "ZIP"
$Check_zip.UseVisualStyleBackColor = $True
$Check_zip.add_Click($Check_zip_action)
$Check_zip.add_CheckedChanged($handler_checkBox1_CheckedChanged)

$frm_whole_form.Controls.Add($Check_zip)


$Btn_cancel.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 6
$System_Drawing_Point.Y = 471
$Btn_cancel.Location = $System_Drawing_Point
$Btn_cancel.Name = "Btn_cancel"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$Btn_cancel.Size = $System_Drawing_Size
$Btn_cancel.TabIndex = 8
$Btn_cancel.Text = "cancel"
$Btn_cancel.UseVisualStyleBackColor = $True
$Btn_cancel.add_Click($handler_Btn_cancel_Click)

$frm_whole_form.Controls.Add($Btn_cancel)


$Btn_original_path.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 237
$System_Drawing_Point.Y = 104
$Btn_original_path.Location = $System_Drawing_Point
$Btn_original_path.Name = "Btn_original_path"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$Btn_original_path.Size = $System_Drawing_Size
$Btn_original_path.TabIndex = 7
$Btn_original_path.Text = "..."
$Btn_original_path.UseVisualStyleBackColor = $True
$Btn_original_path.add_Click($Btn_original_path_OnClick)

$frm_whole_form.Controls.Add($Btn_original_path)


$Btn_backup_path.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 237
$System_Drawing_Point.Y = 181
$Btn_backup_path.Location = $System_Drawing_Point
$Btn_backup_path.Name = "Btn_backup_path"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$Btn_backup_path.Size = $System_Drawing_Size
$Btn_backup_path.TabIndex = 6
$Btn_backup_path.Text = "..."
$Btn_backup_path.UseVisualStyleBackColor = $True
$Btn_backup_path.add_Click($Btn_backup_path_OnClick)

$frm_whole_form.Controls.Add($Btn_backup_path)

$Lbl_welcome.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 16
$System_Drawing_Point.Y = 9
$Lbl_welcome.Location = $System_Drawing_Point
$Lbl_welcome.Name = "Lbl_welcome"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 284
$Lbl_welcome.Size = $System_Drawing_Size
$Lbl_welcome.TabIndex = 5
$Lbl_welcome.Text = "Welcome in the Backup Client"

$frm_whole_form.Controls.Add($Lbl_welcome)

$Lbl_backup_path.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 16
$System_Drawing_Point.Y = 155
$Lbl_backup_path.Location = $System_Drawing_Point
$Lbl_backup_path.Name = "Lbl_backup_path"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 295
$Lbl_backup_path.Size = $System_Drawing_Size
$Lbl_backup_path.TabIndex = 4
$Lbl_backup_path.Text = "Choose Backup location"

$frm_whole_form.Controls.Add($Lbl_backup_path)

$Lbl_original_path.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 17
$System_Drawing_Point.Y = 79
$Lbl_original_path.Location = $System_Drawing_Point
$Lbl_original_path.Name = "Lbl_original_path"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 26
$System_Drawing_Size.Width = 305
$Lbl_original_path.Size = $System_Drawing_Size
$Lbl_original_path.TabIndex = 3
$Lbl_original_path.Text = "Which Drive or Folder do you want to Backup?"

$frm_whole_form.Controls.Add($Lbl_original_path)


$Btn_start_backup.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 243
$System_Drawing_Point.Y = 471
$Btn_start_backup.Location = $System_Drawing_Point
$Btn_start_backup.Name = "Btn_start_backup"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 168
$Btn_start_backup.Size = $System_Drawing_Size
$Btn_start_backup.TabIndex = 0
$Btn_start_backup.Text = "start one Time backup"
$Btn_start_backup.UseVisualStyleBackColor = $True
$Btn_start_backup.add_Click($handler_Btn_start_backup_Click)

$frm_whole_form.Controls.Add($Btn_start_backup)

#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $frm_whole_form.WindowState
#Init the OnLoad event to correct the initial state of the form
$frm_whole_form.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$frm_whole_form.ShowDialog()| Out-Null

} #End Function

#Call the Function
backup_client



#Generated Form Function
function task_added {

#region Generated Form Objects
$Frm_task_added = New-Object System.Windows.Forms.Form
$Btn_added_successfully = New-Object System.Windows.Forms.Button
$Lbl_task_successful = New-Object System.Windows.Forms.Label
$InitialFormWindowState = New-Object System.Windows.Forms.FormWindowState
#endregion Generated Form Objects

#----------------------------------------------
#Generated Event Script Blocks
#----------------------------------------------
#Provide Custom Code for events specified in PrimalForms.
$Btn_added_successfully_OnClick= 
{
  $frm_task_added.Close()

}

$OnLoadForm_StateCorrection=
{#Correct the initial state of the form to prevent the .Net maximized form issue
	$Frm_task_added.WindowState = $InitialFormWindowState
}

#----------------------------------------------
#region Generated Form Code
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 128
$System_Drawing_Size.Width = 327
$Frm_task_added.ClientSize = $System_Drawing_Size
$Frm_task_added.DataBindings.DefaultDataSourceUpdateMode = 0
$Frm_task_added.Name = "Frm_task_added"
$Frm_task_added.Text = "Backup routine added successfully"


$Btn_added_successfully.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 240
$System_Drawing_Point.Y = 93
$Btn_added_successfully.Location = $System_Drawing_Point
$Btn_added_successfully.Name = "Btn_added_successfully"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 75
$Btn_added_successfully.Size = $System_Drawing_Size
$Btn_added_successfully.TabIndex = 1
$Btn_added_successfully.Text = "OK"
$Btn_added_successfully.UseVisualStyleBackColor = $True
$Btn_added_successfully.add_Click($Btn_added_successfully_OnClick)

$Frm_task_added.Controls.Add($Btn_added_successfully)

$Lbl_task_successful.DataBindings.DefaultDataSourceUpdateMode = 0

$System_Drawing_Point = New-Object System.Drawing.Point
$System_Drawing_Point.X = 22
$System_Drawing_Point.Y = 29
$Lbl_task_successful.Location = $System_Drawing_Point
$Lbl_task_successful.Name = "Lbl_task_successful"
$System_Drawing_Size = New-Object System.Drawing.Size
$System_Drawing_Size.Height = 23
$System_Drawing_Size.Width = 225
$Lbl_task_successful.Size = $System_Drawing_Size
$Lbl_task_successful.TabIndex = 0
$Lbl_task_successful.Text = "Backup routine added successfully!"

$Frm_task_added.Controls.Add($Lbl_task_successful)

#endregion Generated Form Code

#Save the initial state of the form
$InitialFormWindowState = $Frm_task_added.WindowState
#Init the OnLoad event to correct the initial state of the form
$Frm_task_added.add_Load($OnLoadForm_StateCorrection)
#Show the Form
$Frm_task_added.ShowDialog()| Out-Null

}