function Format-Console {
    param (
        [int]$WindowHeight,
        [int]$WindowWidth,
        [int]$BufferHeight,
        [int]$BufferWidth
    )
    [System.Console]::SetWindowSize($WindowWidth, $WindowHeight)
    [System.Console]::SetBufferSize($BufferWidth, $BufferHeight)
}