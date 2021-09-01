function Set-ConsoleConfig {
    param (
        [int]$WindowHeight,
        [int]$WindowWidth,
        [int]$BufferHeight=9001,
        [int]$BufferWidth=$WindowWidth
    )
    [System.Console]::SetWindowSize($WindowWidth, $WindowHeight)
    [System.Console]::SetBufferSize($BufferWidth, $BufferHeight)
}
