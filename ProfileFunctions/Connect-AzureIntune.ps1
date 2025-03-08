function Connect-AzureIntune {
	$intunecred = Get-Secret -Name IntuneAutomationSecret -AsPlainText
	Connect-MSIntuneGraph -ClientID "503f5e11-3d5f-4a1c-9991-563cf1d2157b" -TenantID "3ab8c573-cfde-4a33-b33a-6bd96f601c18" -ClientSecret $intunecred.ClientSecret
}