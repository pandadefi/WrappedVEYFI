from brownie import (
    project,
    WrappedVEYFIImpl,
    config
)
from brownie import accounts
import click
from pathlib import Path


Proxy = project.load(
    Path.home() / ".brownie" / "packages" / config["dependencies"][0]
).ERC1967Proxy

def main():
    deployer = accounts.load(
        click.prompt("Account", type=click.Choice(accounts.load()))
    )
    impl = deployer.deploy(WrappedVEYFIImpl)
    proxy = deployer.deploy(Proxy, impl, b"")
    click.echo(f"---------------------------------------------------------------")
    click.echo(f"Implementation: '{impl}',")
    click.echo(f"Proxy: '{proxy}',")
    click.echo(f"---------------------------------------------------------------")