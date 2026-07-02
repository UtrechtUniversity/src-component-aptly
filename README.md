# Playbook aptly

A Ansible playbook component for SURF ResearchCloud.

See https://github.com/UtrechtUniversity/researchcloud-items for UU's main repo of SRC components.

## Summary

Installs [Aptly](https://www.aptly.info/), the "Swiss army knife for Debian repository management", and uses it to serve apt repositories on the workspace, as defined by the user.

## Requires

* OS: Ubuntu `jammy` or higher.
* OS: Debian `bookworm` or higher.
* Component: `nginx` must be installed and running on the workspace when this component is executed.

## Description

This component:

1. installs Aptly.
1. uses Aptly to create apt repositories, as defined by the user (see [Variables](#Variables)).
1. uses Aptly to add packages to the created repositories, as defined by the user (see [Variables](#Variables)).
1. uses `nginx` to serve the apt repositories from the workspace.
  * repositories are served under the `/apt/` location (e.g. `https://<workspace_fqdn>/apt/dists/...`)

To publish repositories, Aptly must have access to a valid GPG Keypair. This component:

* uses a keypair provided by the user in the component parameters (see [Variables](#Variables)).
* creates a new keypair when none is provided by the user.
  * the new public key is served by `nginx` alongside the apt repositories (URL: `<workspace_fqdn>/apt/aptly_pubkey.asc`), so that it can easily be downloaded.

To add packages to repositories, the component creates the script `/usr/local/bin/aptly_add_packages.sh`. The script is run once when this component is executed, but you can also use it at any later time to add more packages to the repositories defined by this component. See the [aptly_add role](../roles/aptly_add.md) for documentation.

## Variables

### Aptly repositories

`aptly_repositories`: String of YAML dict objects (one on every newline) defining repositories to be created. Example:

```yaml
{name: jammy, distribution: jammy, label: test, state: present, components: [main, experimental], architectures: [amd64, arm64]}
{name: focal, distribution: focal, label: test, state: present, components: [main, experimental], architectures: [amd64]}
```

This creates repositories for two distributions (`jammy` and `focal`), each with two 'components' (channels, in this case `main` and `experimental`). The `focal` repo will contain only `amd64` packages, while the `jammy` repo also supports `arm64`. The `name` and `label` attributes are descriptive. For more info, compare the [format of an apt repo](https://wiki.debian.org/DebianRepository/Format).

### Aptly packages

`aptly_packages`: String of YAML dict objects (one on every newline) defining directories from which predefined repositories (see `aptly_repositories`) will be provisioned. Put your `.deb` packages in these directories to automatically add them to the repositories you have defined. Example:

```yaml
{name: jammy, component: main, packages: /pkgs/jammy, architectures: [amd64, arm64]}
{name: focal, component: main, packages: /pkgs/focal, architectures: [amd64]}
```

This adds all `.deb` files `/pkgs/jammy` to the `jammy-main` channel, and all `.deb` files in `/pkgs/focal` to the `focal-main` channel.

### Aptly general

- `aptly_gpg_private_key`: String GPG private key. ResearchCloud will turn newlines into `\n` characters, so these are replaced by true newlines in the playbook. **Note**: a key without a passphrase is expected.
- `aptly_gpg_public_key`: String GPG public key. ResearchCloud will turn newlines into `\n` characters, so these are replaced by true newlines in the playbook.
- `aptly_user`: String name for the aptly user (default: `aptly`).
- `aptly_home`: String homedirectory for the aptly user (default: `/srv/aptly`).
- `aptly_api_enable`: Boolean whether to enable the Aptly API (served on port `9091`).

### GPG

When not setting the GPG keys as parameters (see above), these variables can be used to configure key generation on the workspace:

- `aptly_gpg_realname`: String name of the user to which the key belongs (default: 'Aptly on Research Cloud').
- `aptly_gpg_useremail`: String email of the user to which the key belongs (default: `aptly@localhost`).
- `aptly_gpg_algo`: String algorithm to use for key generation, e.g. `rsa4096` (default: `future-default`, which utilizes the algorithm that is planned to be used in future GPG releases).
- `aptly_gpg_expire`: Integer days after which the key expires (default: 360).
- `aptly_gpg_passphrase`: String passphrase with which to protect the private key (default: `None`). **Note: creating a passphrase-protected key is possible, but not yet supported, as the aptly role currently does not allow importing a key with a passphrase.**


## Dependencies

Two external roles are used and imported to this repository as git subtrees. See roles/ext/ for more info and licensing. We import them into this repo because we cannot install arbitrary external roles on SURF ResearchCloud.

## Molecule

[Molecule](https://github.com/ansible/molecule) is a test framework for Ansible. In contrast to the [method above](#manually-running-the-component-on-a-container), Molecule tests allow you to automate performing an entire test cycle, including:

* Creating a test container
* Running certain preparations
* Executing the playbook
* Checking for [idempotence](https://docs.ansible.com/ansible/latest/playbook_guide/playbooks_intro.html#desired-state-and-idempotency)
* Verifying certain assertions
* Destroying the test container

Additionally, you can create multiple test *scenarios*, in order to test the execution of your playbook in different circumstances. While `run_component.sh` can be used for basic development, Molecule is thus more suited for actual integration tests, including in [CI](#ci).

This repository contains some Molecule configuration files in `molecule/ext/molecule-src`. This setup is geared towards testing ResearchCloud components. It configures default container images, and [mimics certain other features of ResearchCloud workspaces](https://github.com/UtrechtUniversity/SRC-molecule#scenarios).

**Note: for `molecule` to run correctly, the path to the component playbook should be correctly set in `molecule/default/molecule.yml! It defaults to the default `playbook.yml`, but if you rename this file, be sure to change in the `molecule.yml`, too.**

To run `molecule`:

1. Install the Python dependencies:
    * `pip install -r molecule/ext/molecule-src/requirements.txt`
1. Install the Ansible dependencies:
    * `ansible-galaxy install -r requirements.yml`
1. Run: `molecule -c molecule/ext/molecule-src/molecule.yml test`

This will run the scenario in the `molecule/default` directory.

To add and run a new scenario, simply:

1. Copy `molecule/default` into `molecule/<yourscenarioname>`.
1. Make your desired changes.
1. Run: `molecule -c molecule/ext/molecule-src/molecule.yml test -s <yourscenarioname>`

## CI

GitHub Actions workflows are added for:

 * Running `molecule` tests
 * Running `ansible-lint`

A configuration file for `ansible-lint` is also provided in `.ansible-lint`.
