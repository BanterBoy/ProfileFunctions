function New-ObjectToHashTable {
	param([
		Parameter(Mandatory , ValueFromPipeline)]
		$object)
	process	{
		$object |
		Get-Member -MemberType *Property |
		Select-Object -ExpandProperty Name |
		Sort-Object |
		ForEach-Object { [PSCustomObject ]@{
				Item  = $_
				Value = $object. $_
			}
		}
	}
}