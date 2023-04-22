locals {
  config = yamldecode(templatefile("${var.config}", {
    param1 = "value1"
  }))

  creds = {
    user : var.owner_keypair_user,
    private_key : base64decode(var.owner_keypair_private_key)
    public_key : base64decode(var.owner_keypair_public_key)
  }
}
