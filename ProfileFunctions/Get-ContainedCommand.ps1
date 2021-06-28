function Get-ContainedCommand {
    param
    (
        [Parameter(Mandatory)][string]
        $Path,

        [string][ValidateSet('FunctionDefinition', 'Command' )]
        $ItemType
    )

    $Token = $Err = $null
    $ast = [Management.Automation.Language.Parser]::ParseFile( $Path, [ref] $Token, [ref] $Err)

    $ast.FindAll( { $args[0].GetType(). Name -eq "${ItemType}Ast" }, $true )

}