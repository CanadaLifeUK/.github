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
