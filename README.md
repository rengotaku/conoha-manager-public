# conoha-manager-public
Own network infrastructure as code

※ This is not working, just show you code.

# Preparing
## terraform
`$ brew install terraform`
## ansible
`$ brew install ansible`
`$ terraform init`

# インスタンスを立ち上げる
## confirm
`$ terraform plan`
```
~
Plan: 8 to add, 0 to change, 0 to destroy.
~
```
## apply
`$ terraform apply`

## pre
`$ ansible-galaxy install geerlingguy.docker`

# ベース適用
`$ ansible-playbook -i hosts jumper1.yml`
`$ ansible-playbook -i hosts jumper2.yml`

## skip for retry
`$ ansible-playbook -i hosts jumper.yml --skip-tags "skip_for_retry"`
