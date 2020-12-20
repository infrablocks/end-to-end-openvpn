# End to End Example - OpenVPN

This is an end-to-end deployment of a single infrastructure component, in this
case it's an OpenVPN server. We combine several tools to make this work:

* Rake - for task management
* Terraform - for infrastructure provisioning, heavily leaning on InfraBlocks
* Confidante - for configuration management

## Concepts

InfraBlocks modules, and our configuration, contain some terms which need
explanation:

### Component

A collection of infrastructure, which together provides value. For example, a
typical micro-service to serve customer information, with a database and an ECS
Service, would all come under the component `customer-service`. For this 
codebase, we've just used `openvpn-example`, but this could easily be 
`vpn-server`.

### Role

The individual bits that make up a component. Examples of roles include the 
`database`, `log-group`, and the `service`. You can see how we layer together
roles in the `config/roles` directory.

### Deployment Identifier

A label so you can differentiate between multiple deployments of the same 
component. This could be tied to an environment, e.g. `development` or 
`production`, or something more clever. We've used a mixture of environment and
build flavours, so we could run A/B tests of services, e.g. `production-blue`
and `production-green`.

## Deployment

This code requires terraform 0.12 or greater.

### Set up your machine (optional)

We use the `go` script to automate pre-install steps like installing Gems. To 
get `go` onto the PATH, we use direnv. If you want to skip this step, use `rake` 
instead of `go` in all the commands below.

```bash
$ brew install direnv
$ direnv allow
```

### Unlock the secrets

It's not recommended, but for this example we keep secrets in the repository.

We keep them locked up using `git-crypt` and we've provided example keys for 
you to unlock them.

```bash
$ brew install git-crypt
```

To securely manage the VPN, we are using two different secrets access roles, 
an "operator" and a "user":

- Operators are responsible for managing the public key infrastructure (PKI), 
  and provisioning certificates for VPN clients and servers.
- Users are the clients of the VPN and are able to access their encrypted VPN
  profiles.   

To unlock the secrets for a user:

```bash
$ git-crypt unlock ./git-crypt-user-key
```

To unlock the secrets for an operator:

```bash
$ git-crypt unlock ./git-crypt-operator-key
```

**If you want to deploy this for real:**

- Roll all the secrets!
- Use GPG keys to manage access for each of the roles.

### Choose a deployment identifier

Because S3 buckets are global, if you deployed this all as-is you'd likely bump
into others (including us!) for things like S3 buckets. So you need to change
the deployment identifier.

It can be anything you want. :-)

``` bash
$ export DEPLOYMENT_IDENTIFIER=example
```

### Provision the state bucket

We need to store remote terraform state, so the first thing we do is build an S3
bucket to keep it all in.

```bash
$ go "bucket:provision[$DEPLOYMENT_IDENTIFIER]"
```

The state for this bucket is stored in the `state` folder in this repository.

If you want to use this repository as part of a team environment, you need to go
into the `.gitignore` file and delete the following:

```
# State bucket state - remove this
state/*
```

### Provision the DNS zone

In this example, we stand up a public and private zone so we can refer to our
CI by name rather than by IP address.

```bash
$ go "domain:provision[$DEPLOYMENT_IDENTIFIER,example.com]"
```

### Provision the network

We need to build a network to put our services into. At the moment it just takes
up `10.0.0.0/16`.

```bash
$ go "network:provision[$DEPLOYMENT_IDENTIFIER]"
```

### Provision the Cluster

We need to provision some machines to run our ECS cluster on. In this example
we spin up a single `t2.medium` box per availability zone. In this case, it's
three.

```
$ go "cluster:provision[$DEPLOYMENT_IDENTIFIER]"
```

### Provision the Services

Once we have everything we need, now we just need to tell ECS to deploy the
services. This will give us some ECS services, as well as a load balancer.

Note: In this example, we've opened up the CI to `0.0.0.0/0`.

```
$ go "services:provision[$DEPLOYMENT_IDENTIFIER]"
```

## Operation

OpenVPN requires a PKI to manage VPN clients and servers. We use a set of Rake
tasks to administer the PKI, stored in `config/secrets/pki`, securely. These 
Rake tasks should be run by an operator as they update the encrypted PKI.

### Generate PKI

To generate a new PKI, including the root certificate authority (CA) 
certificate, Diffie-Hellman (DH) parameters and a certificate revocation list 
(CRL):

```
$ go "pki:generate"
```

### Manage server keys and certificates

To generate a key and certificate for a VPN server:

```
$ go "server:generate[<dns-address-of-server>]"
```

To revoke a VPN server certificate:

```
$ go "server:revoke[<dns-address-of-server>]"
```

### Manage client profiles

We generate full `.ovpn` profiles for clients of the VPN and store them 
encrypted with the user's GPG key in the `config/secrets/openvpn` directory.
The Rake tasks assume the user's public GPG key is available at 
`config/gpg/<user-email-address>.gpgkey` so make sure it's available before 
running these commands.

To add a new client to the VPN:

```
$ go "client:add[<user-email-address>,<vpn-dns-address>]"
``` 

To remove a client from the VPN:

```
$ go "client:remove[<user-email-address>]"
```

### Pushing additional routes

In some instances, we'll want all traffic for a given third party to go through
the VPN such that it originates from the NAT gateway rather from our 
development machines. This is common in the case where IP whitelisting is
used by those 3rd parties.

OpenVPN supports pushing specific routes to the client on connection. The
3rd party server address can be expressed as a DNS name or as an IP address. In
the case of a DNS name, OpenVPN resolves the DNS name and pushes the resulting
IP address down to the client.

To add additional pushed routes, see `src/openvpn/server.conf.additional`. The
contents of this file are appended to the server configuration on container
start-up so any other OpenVPN configuration can be added here also.

## Usage

To get set up as a user of the VPN:

1. Add your GPG key to the `config/gpg` directory as 
`<your-email-address>.gpgkey`.
2. Ask an operator to create your profile.
3. Decrypt your profile and add to your VPN client:

```
gpg -d config/secrets/openvpn/<your-email-address>.ovpn.gpg > profile.ovpn
open profile.ovpn
```
