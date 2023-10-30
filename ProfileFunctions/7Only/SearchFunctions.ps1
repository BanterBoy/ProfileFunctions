function Get-Google {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Query,
		[Parameter(Mandatory = $false)]
		[switch] $Shopping,
		[Parameter(Mandatory = $false)]
		[switch] $Maps
	)

	Process {
		$([WebSearchUrlBuilder]::new("Google", $Query, $Shopping, $Maps)).Launch()
	}
}

function Get-DuckDuckGo {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Query,
		[Parameter(Mandatory = $false)]
		[switch] $Shopping
	)

	Process {
		$([WebSearchUrlBuilder]::new("DuckDuckGo", $Query, $Shopping)).Launch()
	}
}

function Get-StartPage {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $Query,
		[Parameter(Mandatory = $false)]
		[switch] $Shopping
	)

	Process {
		$([WebSearchUrlBuilder]::new("StartPage", $Query, $Shopping)).Launch()
	}
}

function Get-Navigate {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory = $true, Position = 0)]
		[string] $From, 
		[Parameter(Mandatory = $true, Position = 1)]
		[String] $To
	)

	Process {
		$([WebSearchUrlBuilder]::new($From, $To)).Launch()
	}
}

# function Example-CustomSearch {
# 	[CmdletBinding()]
#     Param(
# 		[Parameter(Mandatory = $true, Position = 0)]
# 		[string] $Query
# 	)

# 	Process {
# 		$([WebSearchUrlBuilder]::new("Custom", $Query, $false)).Launch()
# 	}
# }

class WebSearchUrlBuilder {
	hidden [string]$BaseUrl
	hidden [string]$Query
	hidden [string]$Shopping
	hidden [string[]]$CustomSearches
    
	[string] Url() {
		$url = $this.BaseUrl + $this.Query + $this.Shopping
		Write-Verbose "generated url: $url"
		return $url
	}

	[void] Launch() {	
		# Firefox doesn't support Start-Process "https://www.some-url.com" when it's already running, so open a new window instead to bypass any errors.
		# In this case we're opening a private window, because why the fuck not.
		#
		# Edge/Chrome/etc may well support the easier Start-Process "https://www.some-url.com" syntax when set as the default system browser.
		if ($null -eq $this.CustomSearches -or $this.CustomSearches.Length -eq 0) {
			Write-Verbose "opening: $($this.Url())"
			Start-Process $this.Url()

			#Start-Process -FilePath "firefox.exe" -ArgumentList "-private-window $($this.Url())"
			return
		}

		$this.CustomSearches | ForEach-Object {
			Write-Verbose "opening: $_"
			Start-Process $this.Url()

			#Start-Process -FilePath "firefox.exe" -ArgumentList "-private-window $_"
			[System.Threading.Thread]::Sleep(750)
		}
	}

	hidden [void] BuildSearch([string]$engine, [string]$query, [bool]$shopping, [bool]$maps) {
		switch ($engine) {
			"Google" { 
				if ($maps) {
					$this.BaseUrl = "https://www.google.co.uk/maps/search/"
					$this.Query = $query
					return
				}

				$this.BaseUrl = "https://www.google.co.uk/search"
				$this.Query = "?q=$query"
				$this.Shopping = $shopping ? "&tbm=shop" : ""
			}

			"DuckDuckGo" { 
				$this.BaseUrl = "https://duckduckgo.com"
				$this.Query = "?q=$query"
				$this.Shopping = $shopping ? "&iax=shopping&ia=shopping" : ""
			}

			"StartPage" { 
				$this.BaseUrl = "https://www.startpage.com"
				$this.Query = "/sp/search?query=$query"
				$this.Shopping = $shopping ? "&iax=shopping&ia=shopping" : ""
			}

			"Custom" { 
				$this.CustomSearches = @(
					"https://www.startpage.com/sp/search?query=$query",
					"https://duckduckgo.com?q=$query",
					"https://www.bing.com/search?q=$query",
					"https://www.askjeeves.net/results.html?q=$query"					
				)
			}

			Default {
				throw "Unknown engine: $engine"
			}
		}
	}

	# search constructors
	WebSearchUrlBuilder([string]$engine, [string]$query, [bool]$shopping) {
		$this.BuildSearch($engine, $query, $shopping, $false)
	}

	WebSearchUrlBuilder([string]$engine, [string]$query, [bool]$shopping, [bool]$maps) {
		$this.BuildSearch($engine, $query, $shopping, $maps)
	}

	# navigation constructor
	WebSearchUrlBuilder([string]$from, [string]$to) {
		$this.BaseUrl = "https://www.google.com/maps/dir/"
		$this.Query = "$From/$To/"
	}
}
