param(
    [ValidateSet('red','blue')]
    [string]$StartForm = 'red',
    [ValidateRange(0.5, 2.0)]
    [double]$Scale = 1.0,
    [ValidateRange(60, 3600)]
    [int]$IdleSeconds = 300
)

Add-Type -AssemblyName PresentationCore, PresentationFramework, WindowsBase, System.Xaml, System.Windows.Forms

$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$assets = Join-Path $root 'assets'
$atlasPaths = @{
    red  = Join-Path $assets 'spritesheet-red.png'
    blue = Join-Path $assets 'spritesheet-blue.png'
}
foreach ($path in $atlasPaths.Values) {
    if (-not (Test-Path -LiteralPath $path)) {
        [System.Windows.MessageBox]::Show("缺少宠物图集：$path", '光之守护者') | Out-Null
        exit 1
    }
}

function Load-Atlas([string]$path) {
    $bitmap = [System.Windows.Media.Imaging.BitmapImage]::new()
    $bitmap.BeginInit()
    $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
    $bitmap.UriSource = [Uri]::new($path)
    $bitmap.EndInit()
    $bitmap.Freeze()
    return $bitmap
}

$atlases = @{ red = Load-Atlas $atlasPaths.red; blue = Load-Atlas $atlasPaths.blue }
$frameWidth = 192
$frameHeight = 208
$rows = @{
    idle = @{ row = 0; frames = 6 }
    right = @{ row = 1; frames = 8 }
    left = @{ row = 2; frames = 8 }
    wave = @{ row = 3; frames = 4 }
    jump = @{ row = 4; frames = 5 }
}

$window = [System.Windows.Window]::new()
$window.Title = '光之守护者'
$window.WindowStyle = [System.Windows.WindowStyle]::None
$window.AllowsTransparency = $true
$window.Background = [System.Windows.Media.Brushes]::Transparent
$window.Topmost = $true
$window.ShowInTaskbar = $false
$window.ResizeMode = [System.Windows.ResizeMode]::NoResize
$window.Width = $frameWidth * $Scale
$window.Height = $frameHeight * $Scale

$grid = [System.Windows.Controls.Grid]::new()
$sprite = [System.Windows.Controls.Image]::new()
$sprite.Stretch = [System.Windows.Media.Stretch]::Fill
[System.Windows.Media.RenderOptions]::SetBitmapScalingMode($sprite, [System.Windows.Media.BitmapScalingMode]::NearestNeighbor)
$grid.Children.Add($sprite) | Out-Null
$window.Content = $grid

$state = [ordered]@{
    form = $StartForm
    animation = 'idle'
    frame = 0
    scale = $Scale
    lastInteraction = [DateTime]::UtcNow
    flying = $false
    direction = 1
    transientUntil = [DateTime]::MinValue
}

function Set-Frame {
    $meta = $rows[$state.animation]
    $index = $state.frame % $meta.frames
    $rect = [System.Windows.Int32Rect]::new($index * $frameWidth, $meta.row * $frameHeight, $frameWidth, $frameHeight)
    $crop = [System.Windows.Media.Imaging.CroppedBitmap]::new($atlases[$state.form], $rect)
    $sprite.Source = $crop
}

function Set-PetScale([double]$value) {
    $state.scale = $value
    $window.Width = $frameWidth * $value
    $window.Height = $frameHeight * $value
    $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $window.Left = [Math]::Min([Math]::Max($window.Left, $area.Left), $area.Right - $window.Width)
    $window.Top = [Math]::Min([Math]::Max($window.Top, $area.Top), $area.Bottom - $window.Height)
}

function Show-LightMessage {
    $tip = [System.Windows.Window]::new()
    $tip.WindowStyle = [System.Windows.WindowStyle]::None
    $tip.AllowsTransparency = $true
    $tip.Background = [System.Windows.Media.Brushes]::Transparent
    $tip.Topmost = $true
    $tip.ShowInTaskbar = $false
    $tip.SizeToContent = [System.Windows.SizeToContent]::WidthAndHeight

    $border = [System.Windows.Controls.Border]::new()
    $border.Background = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromArgb(232, 20, 32, 68))
    $border.BorderBrush = [System.Windows.Media.SolidColorBrush]::new([System.Windows.Media.Color]::FromRgb(95, 225, 255))
    $border.BorderThickness = [System.Windows.Thickness]::new(2)
    $border.CornerRadius = [System.Windows.CornerRadius]::new(12)
    $border.Padding = [System.Windows.Thickness]::new(14, 8, 14, 8)
    $text = [System.Windows.Controls.TextBlock]::new()
    $text.Text = '给你光的力量'
    $text.Foreground = [System.Windows.Media.Brushes]::White
    $text.FontSize = 18
    $text.FontWeight = [System.Windows.FontWeights]::Bold
    $border.Child = $text
    $tip.Content = $border
    $tip.Show()
    $tip.Left = $window.Left + ($window.Width - $tip.ActualWidth) / 2
    $tip.Top = [Math]::Max(0, $window.Top - $tip.ActualHeight - 8)

    $closeTimer = [System.Windows.Threading.DispatcherTimer]::new()
    $closeTimer.Interval = [TimeSpan]::FromMilliseconds(1500)
    $closeTimer.Add_Tick({ $closeTimer.Stop(); $tip.Close() })
    $closeTimer.Start()
}

$context = [System.Windows.Controls.ContextMenu]::new()
$sizeMenu = [System.Windows.Controls.MenuItem]::new()
$sizeMenu.Header = '大小'
foreach ($percent in 50, 75, 100, 125, 150, 200) {
    $item = [System.Windows.Controls.MenuItem]::new()
    $item.Header = "$percent%"
    $value = $percent / 100.0
    $item.Add_Click({ Set-PetScale $value }.GetNewClosure())
    $sizeMenu.Items.Add($item) | Out-Null
}
$context.Items.Add($sizeMenu) | Out-Null
$switchItem = [System.Windows.Controls.MenuItem]::new()
$switchItem.Header = '立即切换红/蓝形态'
$switchItem.Add_Click({ $state.form = if ($state.form -eq 'red') { 'blue' } else { 'red' }; Set-Frame })
$context.Items.Add($switchItem) | Out-Null
$resetItem = [System.Windows.Controls.MenuItem]::new()
$resetItem.Header = '回到屏幕右下角'
$resetItem.Add_Click({
    $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $window.Left = $area.Right - $window.Width - 24
    $window.Top = $area.Bottom - $window.Height - 12
})
$context.Items.Add($resetItem) | Out-Null
$exitItem = [System.Windows.Controls.MenuItem]::new()
$exitItem.Header = '退出'
$exitItem.Add_Click({ $window.Close() })
$context.Items.Add($exitItem) | Out-Null
$window.ContextMenu = $context

$window.Add_MouseLeftButtonDown({
    $state.lastInteraction = [DateTime]::UtcNow
    $state.flying = $false
    $state.animation = 'wave'
    $state.frame = 0
    $state.transientUntil = [DateTime]::UtcNow.AddSeconds(1.2)
    Show-LightMessage
    try { $window.DragMove() } catch { }
})

$animationTimer = [System.Windows.Threading.DispatcherTimer]::new()
$animationTimer.Interval = [TimeSpan]::FromMilliseconds(125)
$animationTimer.Add_Tick({
    if ($state.transientUntil -ne [DateTime]::MinValue -and [DateTime]::UtcNow -ge $state.transientUntil) {
        $state.transientUntil = [DateTime]::MinValue
        $state.animation = 'idle'
        $state.frame = 0
    }
    if (-not $state.flying -and ([DateTime]::UtcNow - $state.lastInteraction).TotalSeconds -ge $IdleSeconds) {
        $state.flying = $true
        $state.direction = if ($window.Left -gt ([System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea.Width / 2)) { -1 } else { 1 }
    }
    if ($state.flying) {
        $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
        $state.animation = if ($state.direction -gt 0) { 'right' } else { 'left' }
        $window.Top = $area.Bottom - $window.Height - 10
        $window.Left += 7 * $state.scale * $state.direction
        if ($window.Left -le $area.Left) { $window.Left = $area.Left; $state.direction = 1 }
        if ($window.Left + $window.Width -ge $area.Right) { $window.Left = $area.Right - $window.Width; $state.direction = -1 }
    }
    $state.frame++
    Set-Frame
})

$formTimer = [System.Windows.Threading.DispatcherTimer]::new()
$formTimer.Interval = [TimeSpan]::FromMinutes(3)
$formTimer.Add_Tick({ $state.form = if ($state.form -eq 'red') { 'blue' } else { 'red' }; Set-Frame })

$window.Add_Loaded({
    $area = [System.Windows.Forms.Screen]::PrimaryScreen.WorkingArea
    $window.Left = $area.Right - $window.Width - 24
    $window.Top = $area.Bottom - $window.Height - 12
    Set-Frame
    $animationTimer.Start()
    $formTimer.Start()
})
$window.Add_Closed({ $animationTimer.Stop(); $formTimer.Stop() })

$window.ShowDialog() | Out-Null
