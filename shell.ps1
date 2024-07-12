# PowerShell script for Azure Function

# Import required modules
Import-Module Az.KeyVault

# Define the main function
function Run-CertbotAndImportToKeyVault {
    # Ensure certbot is installed
    if (-Not (Get-Command 'certbot' -ErrorAction SilentlyContinue)) {
        throw "certbot is not installed. Please install certbot."
    }

    # Ensure openssl is installed
    if (-Not (Get-Command 'openssl' -ErrorAction SilentlyContinue)) {
        throw "openssl is not installed. Please install openssl."
    }

    # Generate certificates using certbot
    $command = 'certbot certonly --manual --key-type rsa'
    $input = "fl-api.northeurope.cloudapp.azure.com`n2`n"
    $process = Start-Process -FilePath 'certbot' -ArgumentList $command -NoNewWindow -PassThru
    $process.StandardInput.Write($input)
    $process.StandardInput.Close()
    $process.WaitForExit()

    # Define the certificate directory
    $certDir = "C:\etc\letsencrypt\live\fl-api.northeurope.cloudapp.azure.com"
    if (-Not (Test-Path -Path $certDir)) {
        throw "Certificate directory $certDir does not exist."
    }

    # Change to the certificate directory
    Set-Location -Path $certDir

    # Define the certificate files
    $fullchain = "fullchain.pem"
    $privkey = "privkey.pem"

    # Generate a password for the PFX file
    $passkey = [guid]::NewGuid().ToString()

    # Create the PFX file
    $certFile = "certificate.pfx"
    $opensslCommand = "openssl pkcs12 -export -inkey $privkey -in $fullchain -out $certFile -passout pass:$passkey"
    Invoke-Expression $opensslCommand

    # Import the PFX file into Azure Key Vault
    $vaultName = "findlifeKeyVault"
    $certName = "fl-gw-cert"
    az keyvault certificate import --vault-name $vaultName --file $certFile --name $certName --password $passkey
}

# Main script entry point
Run-CertbotAndImportToKeyVault
