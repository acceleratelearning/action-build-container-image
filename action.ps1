#!/bin/env pwsh
[CmdletBinding()]
param (
    [String]$ImageName,
    [String]$DockerContext,
    [String]$Title,
    [String]$Description,
    [String]$Authors,
    [String]$DocumentationUrl,
    [String]$TestTarget
)

$image_name_parse = ([regex]"(?<registry>[^/]+)/(?<repository>[^:]+):(?<tag>.+)").Match($ImageName)
if (-Not $image_name_parse.Success) {
    throw "Could not parse image name - $ImageName"
}

$repository = $image_name_parse.Groups['repository'].Value
$tag = $image_name_parse.Groups['tag'].Value

$build_date = [Xml.XmlConvert]::ToString([DateTime]::UtcNow, [Xml.XmlDateTimeSerializationMode]::Utc)
$build_args = @(
    "build",
    "--pull",
    "--tag", $ImageName,
    "--label", "`"name=$repository`"",
    "--label", "`"version=$tag`"",
    "--label", "`"org.opencontainers.image.version=$tag`"",
    "--label", "`"org.opencontainers.image.vendor=Accelerate Learning, Inc.`"",
    "--label", "`"org.opencontainers.image.created=$build_date`""
)
if ($env:GITHUB_REPOSITORY) {
    $build_args += "--label", "`"org.opencontainers.image.source=$($env:GITHUB_SERVER_URL)/$($env:GITHUB_REPOSITORY)`""
}
if ($env:GITHUB_SHA) {
    $build_args += "--label", "`"org.opencontainers.image.revision=$($env:GITHUB_SHA)`""
}
if ($Title) {
    $build_args += "--label", "`"org.opencontainers.image.title=$Title`""
}
if ($Description) {
    $build_args += "--label", "`"org.opencontainers.image.description=$Description`""
}
if ($Authors) {
    $build_args += "--label", "`"org.opencontainers.image.authors=$Authors`""
}
if ($DocumentationUrl) {
    $build_args += "--label", "`"org.opencontainers.image.documentation=$DocumentationUrl`""
}
$build_args += $DockerContext

Write-Host '::group::Docker Build Args'
$build_args | Write-Host
Write-Host '::endgroup::'
Write-Host ''

Write-Host '::group::Docker Build'
$env:DOCKER_BUILDKIT = '1'
docker $build_args
Write-Host '::endgroup::'
Write-Host ''

exit $LASTEXITCODE
