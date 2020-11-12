#!/bin/bash

# Setup the environment variables -
# make sure to set ConnectionStrings__PaymentConnection  and VAULT_ADDRvariable with appropriate value.

# Install vault
brew install vault

export VAULT_ADDR=http://vault.example.com
# Initiate vault to have 1 unseal key (usually it should more than 3)
data=$(vault operator init -key-threshold=1 -key-shares=1)

unsealkey="$(echo "$data" | grep "Unseal Key 1: " | cut -c15-)"
roottoken="$(echo "$data" | grep "Root Token: " | cut -c21-)"

echo "Unseal Key : $unsealkey"
echo "Root Token : $roottoken"
# Unseal the Vault using Unseal Key
vault operator unseal $unsealkey

# Login to the Vault using Root Token
vault login $roottoken

# Enable Key Vault engine with paymentservice as path.
vault secrets enable -version=2 -path=secret/paymentservice kv

# Create ConnectionStrings:PaymentConnection secret under paymentservice/settings path.
#vault kv put secret/paymentservice/dev
vault kv put secret/paymentservice/dev db.username=paymentuser db.password=password

# Get the paths under paymentservice kv engine.
vault kv list secret/paymentservice/

# Get the secrets under paymentservice/settings/.
vault kv get secret/paymentservice/dev

# Enable AppRole auth.
vault auth enable approle

# Format the policy located at policies.hcl under vault/policies folder.
#vault policy fmt policies/policies.hcl

# Create the policy.
vault policy write paymentservice - <<EOF
path "secret/" {
  capabilities = ["read", "list"]
}

path "secret/*" {
  capabilities = ["read", "list"]
}
EOF

# Read the policy which just got created.
vault policy read paymentservice

# Create a role and associate it with the policy created.
vault write auth/approle/role/paymentservice secret_id_ttl=525600m secret_id_num_uses=0 policies=default,paymentservice

# Read the Role id.
vault read auth/approle/role/paymentservice/role-id

# Read the Secret Id associated with the role.
vault write -f auth/approle/role/paymentservice/secret-id