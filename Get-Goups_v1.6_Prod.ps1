Add-Type -AssemblyName PresentationFramework
Import-Module ActiveDirectory

# ==========================================================
# HARD-CODE DEFAULT VALUES (EDIT THESE!)
# ==========================================================
$DefaultDC = "DC.mydomain.com"
$DefaultUserUPN = "mydomain.com\user86"

# ==========================================================
# XAML UI
# ==========================================================

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        Title="AD Group Membership Lookup"
        WindowStartupLocation="CenterScreen"
        Width="650" Height="820"
        Background="#1e1e1e"
        ResizeMode="CanResize">

<Window.Resources>

    <!-- TEXT -->
    <Style TargetType="TextBlock">
        <Setter Property="Foreground" Value="#ffffff"/>
    </Style>

    <!-- INPUT FIELDS -->
    <Style TargetType="TextBox">
        <Setter Property="Background" Value="#2d2d2d"/>
        <Setter Property="Foreground" Value="#ffffff"/>
        <Setter Property="BorderBrush" Value="#555555"/>
    </Style>

    <Style TargetType="PasswordBox">
        <Setter Property="Background" Value="#2d2d2d"/>
        <Setter Property="Foreground" Value="#ffffff"/>
        <Setter Property="BorderBrush" Value="#555555"/>
    </Style>

    <!-- LIST -->
    <Style TargetType="ListBox">
        <Setter Property="Background" Value="#252526"/>
        <Setter Property="Foreground" Value="#ffffff"/>
        <Setter Property="BorderBrush" Value="#555555"/>
    </Style>

    <!-- GROUP BOX -->
    <Style TargetType="GroupBox">
        <Setter Property="Foreground" Value="#ffffff"/>
        <Setter Property="BorderBrush" Value="#555555"/>
    </Style>

    <!-- BUTTON -->
    <Style TargetType="Button">
        <Setter Property="Foreground" Value="#ffffff"/>
        <Setter Property="Background" Value="#0e639c"/>
    </Style>

</Window.Resources>

    <Grid Margin="20">

        <!-- 2 COLUMN GRID -->
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="160"/>
            <ColumnDefinition Width="*"/>
        </Grid.ColumnDefinitions>

        <!-- ROWS -->
        <Grid.RowDefinitions>
            <RowDefinition Height="40"/>     
            <RowDefinition Height="40"/>     
            <RowDefinition Height="40"/>     
            <RowDefinition Height="200"/>    
            <RowDefinition Height="360"/>    
            <RowDefinition Height="70"/>     
        </Grid.RowDefinitions>

        <!-- DOMAIN CONTROLLER -->
        <TextBlock Text="Domain Controller:"
                   FontSize="13"
                   VerticalAlignment="Center"/>

        <StackPanel Grid.Column="1"
                    Orientation="Horizontal"
                    VerticalAlignment="Center">

            <!-- Network Server Icon -->
            <TextBlock Text="&#xE168;"
                       FontFamily="Segoe MDL2 Assets"
                       FontSize="18"
                       Margin="0,0,8,0"/>

            <TextBox Name="DCName"
                     FontSize="13"
                     Padding="3"
                     Width="240"
                     Height="22"/>
        </StackPanel>

        <!-- CREDENTIALS -->
        <TextBlock Text="Credentials:"
                   Grid.Row="1"
                   FontSize="13"
                   VerticalAlignment="Center"/>

        <StackPanel Grid.Row="1" Grid.Column="1"
                    Orientation="Horizontal"
                    VerticalAlignment="Center">

            <!-- Username -->
            <StackPanel Orientation="Horizontal">
                <TextBlock Text="&#xE13D;"
                           FontFamily="Segoe MDL2 Assets"
                           FontSize="18"
                           Margin="0,0,6,0"/>
                <TextBox Name="UserNameInput"
                         Width="150"
                         Height="22"
                         Padding="3"
                         FontSize="13"/>
            </StackPanel>

            <!-- Password -->
            <StackPanel Orientation="Horizontal" Margin="12,0,0,0">
                <TextBlock Text="&#xE785;"
                           FontFamily="Segoe MDL2 Assets"
                           FontSize="18"
                           Margin="0,0,6,0"/>
                <PasswordBox Name="PasswordInput"
                             Width="150"
                             Height="22"
                             Padding="3"
                             FontSize="13"/>
            </StackPanel>

        </StackPanel>

        <!-- SAMACCOUNTNAME -->
        <TextBlock Text="sAMAccountName:"
                   Grid.Row="2"
                   FontSize="13"
                   VerticalAlignment="Center"/>

        <StackPanel Grid.Row="2" Grid.Column="1"
                    Orientation="Horizontal"
                    VerticalAlignment="Center">

            <TextBox Name="UserInput"
                     Width="160"
                     Height="22"
                     Padding="3"
                     FontSize="13"/>

            <Button Name="LookupButton"
                    Content="Lookup"
                    Width="75"
                    Height="24"
                    Background="#0e639c"
                    Foreground="White"
                    Margin="10,0,0,0"/>
         </StackPanel>

        <!-- USER DETAILS -->
        <GroupBox Header="User Details"
                  Grid.Row="3"
                  Grid.ColumnSpan="2"
                  FontSize="13"
                  Margin="0,8,0,10">

            <ScrollViewer VerticalScrollBarVisibility="Auto">
                <StackPanel Name="DetailsPanel" Margin="10"/>
            </ScrollViewer>

        </GroupBox>

        <!-- GROUP LIST (BIG AREA) -->
<ListBox Name="GroupList"
         Grid.Row="4"
         Grid.ColumnSpan="2"
         FontSize="12"
         BorderBrush="#555555"
         BorderThickness="1"
         Background="#252526"
         Foreground="#ffffff">

    <ListBox.ItemContainerStyle>
        <Style TargetType="ListBoxItem">
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="Background" Value="Transparent"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#3a3a3a"/>
                </Trigger>
                <Trigger Property="IsSelected" Value="True">
                    <Setter Property="Background" Value="#094771"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </ListBox.ItemContainerStyle>

</ListBox>

        <!-- EXPORT BUTTON -->
        <Button Name="ExportCSV"
                Grid.Row="5"
                Grid.ColumnSpan="2"
                Width="300"
                Height="42"
                HorizontalAlignment="Center"
                Content="Export Groups to CSV"
                Background="#107c10"
                Foreground="White"
                Margin="0,10,0,0"/>
    </Grid>
</Window>
"@



# ==========================================================
# LOAD UI
# ==========================================================
$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$Window = [Windows.Markup.XamlReader]::Load($reader)

# Map controls
$DCName = $Window.FindName("DCName")
$UserNameInput = $Window.FindName("UserNameInput")
$PasswordInput = $Window.FindName("PasswordInput")
$UserInput = $Window.FindName("UserInput")
$LookupButton = $Window.FindName("LookupButton")
$GroupList = $Window.FindName("GroupList")
$DetailsPanel = $Window.FindName("DetailsPanel")
$ExportCSV = $Window.FindName("ExportCSV")

# ==========================================================
# PREFILL + LOCK FIELDS (DOUBLE CLICK TO UNLOCK)
# ==========================================================
$DCName.Text = $DefaultDC
$DCName.IsReadOnly = $false
$DCName.IsEnabled = $true

$UserNameInput.Text = $DefaultUserUPN
$UserNameInput.IsReadOnly = $false
$UserNameInput.IsEnabled = $true

# ----- Double Click Unlock -----
$DCName.Add_MouseDoubleClick({
    $DCName.IsEnabled = $true
    $DCName.IsReadOnly = $false
})

$UserNameInput.Add_MouseDoubleClick({
    $UserNameInput.IsEnabled = $true
    $UserNameInput.IsReadOnly = $false
})

# ==========================================================
# FUNCTIONS
# ==========================================================

# Display user details
function Show-UserDetails {
    param($user)

    $DetailsPanel.Children.Clear()

    $props = @{
        "Display Name" = $user.Name
        "Email"        = $user.EmailAddress
        "Enabled"      = $user.Enabled
        "User DN"      = $user.DistinguishedName
        "GUID"         = $user.ObjectGUID
        "OU"           = ($user.DistinguishedName -replace '^CN=.*?,','')
    }

    foreach ($p in $props.GetEnumerator()) {
        $tb = New-Object System.Windows.Controls.TextBlock
        $tb.Text = "$($p.Key): $($p.Value)"
        $tb.FontSize = 14
        $tb.Margin = "0,3,0,3"
        $DetailsPanel.Children.Add($tb)
    }
}

# Load group list from MemberOf
function Load-Groups {
    param($User, $server, $cred)

    $GroupList.Items.Clear()
    $script:GroupData = @()

    foreach ($dn in $User.MemberOf) {

        $group = Get-ADGroup -Identity $dn -Server $server -Credential $cred `
                 -Properties GroupCategory, GroupScope -ErrorAction SilentlyContinue

        if ($null -eq $group) { continue }

        $item = New-Object System.Windows.Controls.ListBoxItem
        $item.Content = $group.Name

        if ($group.GroupCategory -eq "Security") { $item.Foreground = "Blue" }
        elseif ($group.GroupCategory -eq "Distribution") { $item.Foreground = "Green" }

        $GroupList.Items.Add($item)

        $script:GroupData += [PSCustomObject]@{
            GroupName = $group.Name
            Category  = $group.GroupCategory
            Scope     = $group.GroupScope
        }
    }
}

# ==========================================================
# LOOKUP BUTTON CLICK
# ==========================================================
$LookupButton.Add_Click({

    $server = $DefaultDC             # Always use hardcoded DC
    $userName = $DefaultUserUPN      # Always use hardcoded Username
    $password = $PasswordInput.Password
    $sam = $UserInput.Text.Trim()

    if ([string]::IsNullOrWhiteSpace($password) -or [string]::IsNullOrWhiteSpace($sam)) {
        [System.Windows.MessageBox]::Show("Password and sAMAccountName required.","Missing Info")
        return
    }

    # Build Credential
    $SecurePassword = ConvertTo-SecureString $password -AsPlainText -Force
    $Cred = New-Object System.Management.Automation.PSCredential ($userName, $SecurePassword)

    try {
        $User = Get-ADUser $sam -Properties MemberOf,EmailAddress,Enabled,DistinguishedName,ObjectGUID `
                             -Server $server -Credential $Cred -ErrorAction Stop
    }
    catch {
        [System.Windows.MessageBox]::Show("Invalid credentials OR user not found.","Error")
        return
    }

    Show-UserDetails -user $User
    Load-Groups -User $User -server $server -cred $Cred
})

# ==========================================================
# EXPORT CSV
# ==========================================================
$ExportCSV.Add_Click({
    if ($script:GroupData.Count -eq 0) {
        [System.Windows.MessageBox]::Show("No groups to export.","Warning")
        return
    }

    $sam = $UserInput.Text.Trim()

    # Export to C:\Temp with filename SAM_groupExport.csv
    $path = Join-Path "$($env:SystemDrive)\Temp" "$($sam)_GroupExport.csv"

    # Ensure C:\Temp exists
    if (-not (Test-Path "$($env:SystemDrive)\Temp")) {
        New-Item -ItemType Directory -Path "$($env:SystemDrive)\Temp" | Out-Null
    }

    $script:GroupData | Export-Csv -Path $path -NoTypeInformation -Encoding UTF8

    [System.Windows.MessageBox]::Show("CSV exported to: `n$path","Success")
})

# ==========================================================
# RUN WINDOW
# ==========================================================

$Window.Topmost = $true
$Window.Add_ContentRendered({
    $Window.Topmost = $false
})
$Window.ShowDialog() | Out-Null