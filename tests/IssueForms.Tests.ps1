Describe 'Organisation-wide dynamic environments onboarding issue form' {
    $acknowledgementCases = @(
        @{
            Name = 'ordinary GitOps and Docker prerequisites'
            Because = 'requesters must explicitly accept the existing ordinary GitOps and Docker prerequisites'
            Patterns = @('(?i)(ordinary|standard).*GitOps.*onboard', '(?i)standard Docker workflow')
        }
        @{
            Name = 'same-repository pull request branches'
            Because = 'requesters must explicitly accept the same-repository pull request branch restriction'
            Patterns = @('(?i)(same|this).*repository', '(?i)(PR|pull request).*branch|branch.*(PR|pull request)')
        }
        @{
            Name = 'Crossplane ownership and rejected direct deployment routes'
            Because = 'requesters must explicitly accept Crossplane ownership and the rejection of every direct deployment route'
            Patterns = @(
                '(?i)Crossplane.*(own|manag)',
                '(?i)(no|not|without|instead of|rather than|reject)',
                '(?i)Bicep',
                '(?i)Terraform',
                '(?i)Azure CLI',
                '(?i)provider[- ]resource'
            )
        }
    )

    $securityWordingCases = @(
        @{
            Name = 'the automation label requests validation without authorising deployment'
            Source = 'markdown'
            Because = 'applying the label must request validation only and must not be represented as deployment authorisation'
            Patterns = @(
                '(?is)\blabel\b.*\b(only|solely)\b.*\b(request|trigger).*\bvalidation\b',
                '(?is)\blabel\b.*\b(does not|doesn''t|never|cannot)\b.*\bauthori[sz]e\b.*\bdeploy'
            )
        }
        @{
            Name = 'the bot independently checks every prerequisite before opening pull requests'
            Source = 'markdown'
            Because = 'automation must independently verify authority and repository safety before it opens a pull request'
            Patterns = @(
                '(?is)\b(bot|automation)\b.*\bindependent(ly)?\b.*\b(check|verify|validat)',
                '(?i)\brequester\b.*\bpermission',
                '(?i)\btenant\b.*\bownership\b',
                '(?i)\brepository\b.*\bstate\b',
                '(?i)\ball\b.*\binputs?\b',
                '(?is)\bbefore\b.*\b(open|creat)(s|es|ing)?\b.*\b(PR|pull request)'
            )
        }
        @{
            Name = 'the application name is described as untrusted input'
            Source = 'application-name-description'
            Because = 'requesters must understand that the submitted application name is not trusted by automation'
            Patterns = @('(?i)\b(submitted|provided|this)\b.*\b(value|application name|input)\b.*\b(untrusted|not trusted)\b')
        }
        @{
            Name = 'the development overlay path is described as untrusted input'
            Source = 'development-overlay-description'
            Because = 'requesters must understand that the submitted development overlay path is not trusted by automation'
            Patterns = @('(?i)\b(submitted|provided|this)\b.*\b(value|path|input)\b.*\b(untrusted|not trusted)\b')
        }
        @{
            Name = 'the bot requires a DNS-label application name'
            Source = 'application-name-description'
            Because = 'the form must state that automation validates the application name as a DNS label rather than implying client-side enforcement'
            Patterns = @('(?is)\b(bot|automation)\b.*\b(require|check|validat)(s|es)?\b.*\bDNS[- ]label\b')
        }
        @{
            Name = 'the bot requires a canonical repository-relative development overlay path'
            Source = 'development-overlay-description'
            Because = 'the form must state the canonical repository-relative path contract that automation validates'
            Patterns = @('(?is)\b(bot|automation)\b.*\b(require|check|validat)(s|es)?\b.*\bcanonical\b.*\brepository[- ]relative\b')
        }
        @{
            Name = 'unsafe paths interpolation and rendered resources are rejected'
            Source = 'development-overlay-description'
            Because = 'requesters must be warned about every class of input or rendered output that automation rejects'
            Patterns = @(
                '(?i)\breject(s|ed|ing)?\b.*\babsolute paths?\b',
                '(?i)\.\..*\b(traversal|path)\b|\b(traversal|path)\b.*\.\.',
                '(?i)\bsymlinks?\b.*\b(escape|outside)\b.*\brepositor',
                '(?i)\bunsafe\b.*\binterpolation\b',
                '(?i)\bunsupported\b.*\brendered\b.*\bresources?\b'
            )
        }
    )

    BeforeAll {
        $templatePath = Join-Path $PSScriptRoot '..\.github\ISSUE_TEMPLATE\07-onboard_dynamic_environments.yaml'
        $templateExists = Test-Path -LiteralPath $templatePath -PathType Leaf

        if ($templateExists) {
            Import-Module powershell-yaml -ErrorAction Stop
            $form = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Yaml

            $markdown = @($form.body |
                    Where-Object type -EQ 'markdown' |
                    ForEach-Object { $_.attributes.value }) -join "`n"

            $checkboxItems = @($form.body |
                    Where-Object type -EQ 'checkboxes')

            $checkboxOptions = @($checkboxItems |
                    ForEach-Object { $_.attributes.options })

            $applicationName = @($form.body |
                    Where-Object {
                        $_.type -eq 'input' -and
                        (($_.attributes.label, $_.attributes.description) -join ' ') -match '(?i)XKubernetesApp.*application name|application name.*XKubernetesApp'
                    })

            $developmentOverlay = @($form.body |
                    Where-Object {
                        $_.type -eq 'input' -and
                        (($_.attributes.label, $_.attributes.description) -join ' ') -match '(?i)development.*overlay.*path|dev.*overlay.*path'
                    })

            $applicationNameDescription = @($applicationName |
                    ForEach-Object { $_.attributes.description }) -join "`n"

            $developmentOverlayDescription = @($developmentOverlay |
                    ForEach-Object { $_.attributes.description }) -join "`n"

            $requestedFieldText = @($form.body |
                    Where-Object type -In @('input', 'textarea', 'dropdown') |
                    ForEach-Object {
                        $_.attributes.label
                        $_.attributes.description
                        $_.attributes.placeholder
                    }) -join "`n"
        }
    }

    It 'exists as a standalone organisation-wide form' {
        $templateExists |
            Should -BeTrue -Because 'the standalone organisation-wide dynamic environments issue form must exist'
    }

    It 'sets the automation title and label' {
        $form.title.TrimEnd() |
            Should -BeExactly '[Dynamic environments]' -Because 'new issues must use the exact requested title prefix'
        @($form.labels) |
            Should -Contain 'dynamic-environments-onboard' -Because 'automation must be able to select onboarding requests by label'
    }

    It 'does not define an empty assignees list' {
        ($null -eq $form.assignees -or @($form.assignees).Count -gt 0) |
            Should -BeTrue -Because 'GitHub issue-form metadata permits assignees to be absent or non-empty, but not an empty array'
    }

    It 'explains the distinct dev-green-only onboarding workflow' {
        $markdown |
            Should -Match '(?is)(separate|distinct).*(ordinary|standard).*(GitOps).*(onboard)' -Because 'requesters must be told this is separate from ordinary GitOps onboarding'
        $markdown |
            Should -Match '(?i)(only|supports only).*(dev-green)|dev-green.*(only|sole)' -Because 'the standalone form supports only dev-green'
    }

    It 'states <Name>' -ForEach $securityWordingCases {
        $observedText = switch ($Source) {
            'markdown' { $markdown }
            'application-name-description' { $applicationNameDescription }
            'development-overlay-description' { $developmentOverlayDescription }
        }

        foreach ($pattern in $Patterns) {
            $observedText |
                Should -Match $pattern -Because $Because
        }
    }

    It 'requires acknowledgement of existing standard onboarding' {
        @($checkboxOptions |
                Where-Object { $_.label -match '(?i)(ordinary|standard).*GitOps.*onboard' -and $_.label -match '(?i)standard Docker workflow' }).Count |
            Should -BeGreaterThan 0 -Because 'requesters must acknowledge that ordinary GitOps onboarding and the standard Docker workflow already exist'
    }

    It 'marks the <Name> acknowledgement option as required' -ForEach $acknowledgementCases {
        $matchingOption = @($checkboxOptions |
                Where-Object {
                    $candidate = $_
                    @($Patterns | Where-Object { $candidate.label -notmatch $_ }).Count -eq 0
                })[0]

        $matchingOption.required |
            Should -BeTrue -Because $Because
    }

    It 'does not declare unsupported group-level validations on checkbox items' {
        @($checkboxItems |
                Where-Object { $null -ne $_.validations }).Count |
            Should -Be 0 -Because 'GitHub issue-form checkbox acknowledgements are enforced by required options rather than group-level validations'
    }

    It 'requires one DNS-label-compatible XKubernetesApp application name' {
        $applicationName.Count |
            Should -Be 1 -Because 'the contract needs one XKubernetesApp application name input'
        (($applicationName[0].attributes.label, $applicationName[0].attributes.description, $applicationName[0].attributes.placeholder) -join ' ') |
            Should -Match '(?i)DNS[- ]label' -Because 'the application name must explain the Kubernetes DNS-label constraint'
        $applicationName[0].validations.required |
            Should -BeTrue -Because 'an XKubernetesApp application name is necessary to onboard the workload'
    }

    It 'states the 63-character maximum for the XKubernetesApp application name' {
        $applicationNameDescription |
            Should -Match '(?i)\b(maximum|max)\b.{0,30}\b63\b.{0,20}\bcharacters?\b|\b63\b.{0,20}\bcharacters?\b.{0,30}\b(maximum|max)\b' -Because 'requesters must know that a Kubernetes DNS label cannot exceed 63 characters'
    }

    It 'provides the expected development overlay default' {
        $developmentOverlay.Count |
            Should -Be 1 -Because 'the form must expose one development overlay path field'
        $developmentOverlay[0].attributes.value |
            Should -BeExactly 'deploy/dev' -Because 'the development overlay path must default to deploy/dev'
    }

    It 'requires acknowledgement that the pull request branch is in the same repository' {
        @($checkboxOptions |
                Where-Object { $_.label -match '(?i)(same|this).*repository' -and $_.label -match '(?i)(PR|pull request).*branch|branch.*(PR|pull request)' }).Count |
            Should -BeGreaterThan 0 -Because 'requesters must acknowledge that the PR branch is in the same repository'
    }

    It 'requires Crossplane ownership and rejects direct deployment routes' {
        @($checkboxOptions |
                Where-Object {
                    $_.label -match '(?i)Crossplane.*(own|manag)' -and
                    $_.label -match '(?i)(no|not|without|instead of|rather than|reject)' -and
                    $_.label -match '(?i)Bicep' -and
                    $_.label -match '(?i)Terraform' -and
                    $_.label -match '(?i)Azure CLI' -and
                    $_.label -match '(?i)provider[- ]resource'
                }).Count |
            Should -BeGreaterThan 0 -Because 'requesters must accept Crossplane ownership and reject every prohibited direct deployment route'
    }

    It 'does not request sensitive identifiers or secrets' {
        $requestedFieldText |
            Should -Not -Match '(?i)\b(credentials?|tenant IDs?|subscriptions?|client IDs?|resource IDs?|secrets?)\b' -Because 'the public issue form must not request sensitive identifiers or secrets'
    }
}

Describe 'Organisation-wide Deployment Guide onboarding issue form' {
    BeforeAll {
        $templatePath = Join-Path $PSScriptRoot '..\.github\ISSUE_TEMPLATE\08-onboard_deployment_guide.yaml'
        $templateExists = Test-Path -LiteralPath $templatePath -PathType Leaf

        if ($templateExists) {
            Import-Module powershell-yaml -ErrorAction Stop
            $form = Get-Content -LiteralPath $templatePath -Raw | ConvertFrom-Yaml

            $markdown = @($form.body |
                    Where-Object type -EQ 'markdown' |
                    ForEach-Object { $_.attributes.value }) -join "`n"

            $fields = @($form.body | Where-Object type -NE 'markdown')
            $environments = @($fields | Where-Object id -EQ 'environments')
            $syncRoot = @($fields | Where-Object id -EQ 'gitops-sync-root')
        }
    }

    It 'exists as a standalone organisation-wide form' {
        $templateExists |
            Should -BeTrue -Because 'the organisation-wide Deployment Guide onboarding issue form must exist'
    }

    It 'sets the form name, title prefix and automation label' {
        $form.name |
            Should -BeExactly 'Onboard to the Deployment Guide' -Because 'the bot documentation names the form exactly'
        $form.title.TrimEnd() |
            Should -BeExactly '[Deployment Guide]' -Because 'new issues must use the Deployment Guide title prefix'
        @($form.labels) |
            Should -BeExactly @('deployment-guide-onboard') -Because 'the Platform Operator bot acts only on issues carrying this label'
    }

    It 'contains only the environments and GitOps sync root fields' {
        @($fields | ForEach-Object { $_.id }) |
            Should -BeExactly @('environments', 'gitops-sync-root') -Because 'the bot parses exactly these two form sections'
    }

    It 'offers a Deployment Guide environments checkbox group with optional dev, pre and prd options' {
        $environments.Count | Should -Be 1
        $environments[0].type | Should -BeExactly 'checkboxes'
        $environments[0].attributes.label |
            Should -BeExactly 'Deployment Guide environments' -Because 'the bot locates the environments section by this exact heading'
        @($environments[0].attributes.options | ForEach-Object { $_.label }) |
            Should -BeExactly @('dev', 'pre', 'prd') -Because 'the bot accepts only these environment names'
        @($environments[0].attributes.options | Where-Object { $_.required }).Count |
            Should -Be 0 -Because 'requesters choose a subset of environments rather than all of them'
        $environments[0].validations |
            Should -BeNullOrEmpty -Because 'GitHub issue forms do not support group-level validations on checkboxes; the bot enforces at least one selection'
    }

    It 'offers an optional GitOps sync root input defaulting to deploy' {
        $syncRoot.Count | Should -Be 1
        $syncRoot[0].type | Should -BeExactly 'input'
        $syncRoot[0].attributes.label |
            Should -BeExactly 'GitOps sync root' -Because 'the bot locates the sync root section by this exact heading'
        $syncRoot[0].attributes.description |
            Should -BeExactly 'Repository-relative directory that holds the per-environment overlays. Leave blank for `deploy`.'
        $syncRoot[0].validations.required |
            Should -BeFalse -Because 'a blank sync root falls back to deploy'
    }

    It 'explains what the bot does and warns against secrets' {
        $markdown | Should -Match '(?i)platform\.kubernetes\.gitops'
        $markdown | Should -Match '\.github/workflows/deployment-guide-trigger\.yaml'
        $markdown | Should -Match '(?i)auto-?merge'
        $markdown | Should -Match '(?i)already onboarded'
        $markdown | Should -Match '(?i)at least one.*environment' -Because 'the form cannot enforce a selection, so requesters must be told the bot rejects an empty one'
        $markdown | Should -Match '(?i)\bsecrets?\b'
    }
}
