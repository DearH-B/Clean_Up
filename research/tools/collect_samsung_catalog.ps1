param(
    [string]$OutputPath = (Join-Path $PSScriptRoot "..\catalog_batches\samsung_expansion_30.json")
)

$ErrorActionPreference = "Stop"
$checkedAt = "2026-06-14"
$baseUrl = "https://www.samsung.com"

$candidates = @(
    @{ category = "refrigerator"; model = "RM70F64Q1XJ"; path = "/sec/refrigerators/french-door-rm70f64q1xj-d2c/RM70F64Q1XJ/" },
    @{ category = "refrigerator"; model = "RM90F91D1W"; path = "/sec/refrigerators/french-door-rm90f91d1w-d2c/RM90F91D1W/" },
    @{ category = "refrigerator"; model = "RM90H64P2W"; path = "/sec/refrigerators/french-door-rm90h64p2w-d2c/RM90H64P2W/" },
    @{ category = "kimchi_refrigerator"; model = "RK70F49D1A"; path = "/sec/kimchi-refrigerators/kimchi-stand-rk70f49d1a-d2c/RK70F49D1A/" },
    @{ category = "kimchi_refrigerator"; model = "RK80F42C2A"; path = "/sec/kimchi-refrigerators/kimchi-stand-rk80f42c2a-d2c/RK80F42C2A/" },
    @{ category = "kimchi_refrigerator"; model = "RK80F58B1A"; path = "/sec/kimchi-refrigerators/kimchi-stand-rk80f58b1a-d2c/RK80F58B1A/" },
    @{ category = "kimchi_refrigerator"; model = "RQ33DB74E1AP"; path = "/sec/kimchi-refrigerators/kimchi-stand-rq33db74e1ap-d2c/RQ33DB74E1AP/" },
    @{ category = "kimchi_refrigerator"; model = "RQ42DB99T2APG"; path = "/sec/kimchi-refrigerators/kimchi-stand-rq42db99t2apg-d2c/RQ42DB99T2APG/" },
    @{ category = "kimchi_refrigerator"; model = "RQ34C7915AP"; path = "/sec/kimchi-refrigerators/kimchi-stand-rq34c7815ap-d2c/RQ34C7915AP/" },
    @{ category = "kimchi_refrigerator"; model = "RP20C3111EG"; path = "/sec/kimchi-refrigerators/kimchi-top-loadingrp20c3111eg-d2c/RP20C3111EG/" },
    @{ category = "refrigerator"; model = "RR40C7895AP"; path = "/sec/refrigerators/one-door-rr40c7895ap-d2c/RR40C7895AP/" },
    @{ category = "refrigerator"; model = "RW24C5820AP"; path = "/sec/refrigerators/one-door-rw24c5820ap-d2c/RW24C5820AP/" },
    @{ category = "washer"; model = "WA30DG2120EE"; path = "/sec/washing-machines/wa30dg2120ee-d2c/WA30DG2120EE/" },
    @{ category = "washer"; model = "WA80F19SKB"; path = "/sec/washing-machines/top-loader-wa80f19skb-d2c/WA80F19SKB/" },
    @{ category = "washer"; model = "WD90H25AHS"; path = "/sec/laundry-combo/combo-wd90h25ahs-d2c/WD90H25AHS/" },
    @{ category = "washer"; model = "WD99F25AHR"; path = "/sec/laundry-combo/combo-wd99f25ahr-d2c/WD99F25AHR/" },
    @{ category = "washer"; model = "WF90F25ADT"; path = "/sec/washing-machines/wf90f25adt-d2c/WF90F25ADT/" },
    @{ category = "washer"; model = "WH90F2120GBHW"; path = "/sec/washing-machines/onebody-wh90f2120gbhw-d2c/WH90F2120GBHW/" },
    @{ category = "air_conditioner"; model = "AF60F19D12WRT"; path = "/sec/air-conditioners/package-af60f19d12wrt-d2c/AF60F19D12WRT/" },
    @{ category = "air_conditioner"; model = "AF70F17D24WRT"; path = "/sec/air-conditioners/package-af70f17d24wrt-d2c/AF70F17D24WRT/" },
    @{ category = "air_conditioner"; model = "AF80F18D25WRT"; path = "/sec/air-conditioners/package-af80f18d25wrt-d2c/AF80F18D25WRT/" },
    @{ category = "air_conditioner"; model = "AF90H25D36WRT"; path = "/sec/air-conditioners/package-af90h25d36wrt-d2c/AF90H25D36WRT/" },
    @{ category = "air_conditioner"; model = "AR60F11D11WT"; path = "/sec/air-conditioners/package-ar60f11d11wt-d2c/AR60F11D11WT/" },
    @{ category = "dishwasher"; model = "DW90F79F1USBS"; path = "/sec/dishwashers/built-in-dw90f79f1usbs-d2c/DW90F79F1USBS/" },
    @{ category = "dishwasher"; model = "DW99F79E1B00S"; path = "/sec/dishwashers/true-built-in-dw99f79e1b00s-d2c/DW99F79E1B00S/" },
    @{ category = "dishwasher"; model = "DW99F79E1UHCS"; path = "/sec/dishwashers/built-in-dw99f79e1uhcs-d2c/DW99F79E1UHCS/" },
    @{ category = "induction"; model = "CC80H63G1HS"; path = "/sec/electric-range/cooktop-cc80h63g1hs-d2c/CC80H63G1HS/" },
    @{ category = "induction"; model = "CC99H84JAD"; path = "/sec/electric-range/cooktop-cc99h84jad-d2c/CC99H84JAD/" },
    @{ category = "induction"; model = "NZ62DG300CFW"; path = "/sec/electric-range/cooktop-nz62dg300cf-d2c/NZ62DG300CFW/" },
    @{ category = "air_purifier"; model = "AX053B810HND"; path = "/sec/air-cleaner/air-purifier-ax053b810hnd-d2c/AX053B810HND/" },
    @{ category = "vacuum"; model = "VR90F01SAG"; path = "/sec/vacuum-cleaners/jetbot-vr90f01sag-d2c/VR90F01SAG/" },
    @{ category = "vacuum"; model = "VS15A680AEW"; path = "/sec/vacuum-cleaners/vs15a680aew-d2c/VS15A680AEW/" },
    @{ category = "vacuum"; model = "VS90F40CSG"; path = "/sec/vacuum-cleaners/bespoke-jet-vs90f40cs-d2c/VS90F40CSG/" },
    @{ category = "dryer"; model = "DV90F22CDT"; path = "/sec/dryers/dryer-dv90f22cdt-d2c/DV90F22CDT/" }
)

function Get-ProductJson {
    param([string]$Html, [string]$Model)

    $matches = [regex]::Matches(
        $Html,
        '<script[^>]+type="application/ld\+json"[^>]*>(.*?)</script>',
        [System.Text.RegularExpressions.RegexOptions]::Singleline
    )
    foreach ($match in $matches) {
        try {
            $value = $match.Groups[1].Value | ConvertFrom-Json
            if ($value.'@type' -eq "Product" -and $value.sku -eq $Model) {
                return $value
            }
        }
        catch {
            continue
        }
    }
    throw "$Model product structured data not found."
}

function Get-ManualUrl {
    param([string]$Model, [string]$GoodsId)

    $body = @{
        mdlCode = $Model
        goodsId = $GoodsId
        manualLang = "KO"
        mdlNm = ""
        supportYn = "Y"
    }
    $manualHtml = Invoke-RestMethod `
        -Uri "$baseUrl/sec/xhr/goods/goodsManual" `
        -Method Post `
        -Body $body `
        -TimeoutSec 60

    $userManual = [regex]::Match(
        $manualHtml,
        'https://downloadcenter\.samsung\.com/content/UM/[^"]+\.pdf'
    )
    if ($userManual.Success) {
        return $userManual.Value
    }
    $fallback = [regex]::Match(
        $manualHtml,
        'https://downloadcenter\.samsung\.com/content/[^"]+\.pdf'
    )
    if ($fallback.Success) {
        return $fallback.Value
    }
    throw "$Model official PDF manual not found."
}

function Get-ModelYear {
    param([string]$Model, [Nullable[int]]$FallbackYear)

    $match = [regex]::Match($Model, '^[A-Z]{2}[0-9]{2,3}([A-Z])')
    if ($match.Success) {
        $years = @{
            A = 2021
            B = 2022
            C = 2023
            D = 2024
            F = 2025
            H = 2026
        }
        $code = $match.Groups[1].Value
        if ($years.ContainsKey($code)) {
            return $years[$code]
        }
    }
    return $FallbackYear
}

$failures = @()
$results = foreach ($candidate in $candidates) {
    try {
        $url = "$baseUrl$($candidate.path)"
        Write-Host "Collecting $($candidate.model)..."
        $html = (Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 60).Content
        $product = Get-ProductJson -Html $html -Model $candidate.model
        $goodsIdMatch = [regex]::Match($html, 'G[0-9]{9}')
        if (-not $goodsIdMatch.Success) {
            throw "$($candidate.model) goods ID not found."
        }
        $image = [string]$product.image
        if ($image.StartsWith("//")) {
            $image = "https:$image"
        }
        $imageYearMatch = [regex]::Match($image, '/(20[0-9]{2})/')
        $releaseYear = if ($imageYearMatch.Success) {
            [int]$imageYearMatch.Groups[1].Value
        }
        else {
            $null
        }

        [ordered]@{
            category = $candidate.category
            model = $candidate.model
            name = [string]$product.name
            description = [string]$product.description
            productUrl = $url
            imageUrl = $image
            goodsId = $goodsIdMatch.Value
            manualUrl = Get-ManualUrl -Model $candidate.model -GoodsId $goodsIdMatch.Value
            supportUrl = "$baseUrl/sec/support/model/$($candidate.model)/"
            releaseYear = Get-ModelYear -Model $candidate.model -FallbackYear $releaseYear
            pageAssetYear = $releaseYear
            checkedAt = $checkedAt
        }
    }
    catch {
        Write-Warning "$($candidate.model): $($_.Exception.Message)"
        $failures += [ordered]@{
            category = $candidate.category
            model = $candidate.model
            productUrl = "$baseUrl$($candidate.path)"
            error = $_.Exception.Message
        }
    }
}

$directory = Split-Path -Parent $OutputPath
New-Item -ItemType Directory -Path $directory -Force | Out-Null
[ordered]@{
    checkedAt = $checkedAt
    products = @($results)
    failures = @($failures)
} | ConvertTo-Json -Depth 6 | Set-Content -Encoding utf8 $OutputPath
Write-Host "Saved $($results.Count) products and $($failures.Count) failures to $OutputPath"
