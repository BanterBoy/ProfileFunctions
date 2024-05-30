function Set-ConsoleConfig {
    param (
        [int]$WindowHeight,
        [int]$WindowWidth,
        [int]$BufferHeight=9001
    )
    [System.Console]::SetWindowSize($WindowWidth, $WindowHeight)
    [System.Console]::SetBufferSize($WindowWidth, $BufferHeight)
}
